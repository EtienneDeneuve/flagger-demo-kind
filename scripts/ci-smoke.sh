#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
load_versions
require_context

out="$TOOLS_DIR/e2e-logs"
mkdir -p "$out"
pf=''
load=''
pilot=''
metrics=''
cleanup() {
  for p in "$pilot" "$load" "$pf" "$metrics"; do
    if [[ -n "$p" ]]; then kill "$p" 2>/dev/null || true; wait "$p" 2>/dev/null || true; fi
  done
}
on_error() {
  log_fail "E2E failed — diagnostics in $out/"
  kubectl get nodes -o wide >"$out/nodes.txt" 2>&1 || true
  kubectl -n "$LAB_NS" get pods,deploy,canary,gateway,httproute,svc -o wide >"$out/status.txt" 2>&1 || true
  kubectl -n "$LAB_NS" describe canary podinfo >"$out/canary.txt" 2>&1 || true
  kubectl -n "$LAB_NS" get httproute podinfo -o yaml >"$out/httproute.yaml" 2>&1 || true
  kubectl -n flagger-system logs deployment/flagger >"$out/flagger.log" 2>&1 || true
  kubectl -n flagger-system logs deployment/prometheus-lab >"$out/prometheus.log" 2>&1 || true
  kubectl -n envoy-gateway-system logs deployment/envoy-gateway >"$out/envoy-gateway.log" 2>&1 || true
}
trap cleanup EXIT
trap on_error ERR

wait_http() {
  local url="$1" header="$2" attempts=0 code
  while (( attempts < 90 )); do
    code="$(http_code -H "Host: podinfo.local" -H "$header" "$url")"
    if [[ "$code" == 2* ]]; then
      log_ok "HTTP $code  $url"
      return 0
    fi
    if (( attempts % 10 == 0 )); then
      log_wait "gateway $url  last=$code  (canary 5xx possible pendant une analyse)"
    fi
    attempts=$((attempts+1))
    sleep 2
  done
  log_fail "HTTP endpoint unavailable: $url (last=$code)"
  return 1
}
wait_promoted() {
  local text="$1" attempts=0 primary target phase weight
  while (( attempts < 120 )); do
    primary="$(podinfo_ui_message podinfo-primary)"
    target="$(podinfo_ui_message podinfo)"
    phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    weight="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.canaryWeight}' 2>/dev/null || true)"
    if [[ "$primary" == "$text" && "$phase" == "Succeeded" ]]; then
      log_ok "promoted  phase=$phase  weight=${weight:-0}  primary=$primary"
      return 0
    fi
    if [[ "$phase" == "Failed" ]]; then
      log_fail "promotion interrompue (phase=Failed) — métriques 5xx; voir make status"
      return 1
    fi
    if [[ "$phase" == "Initialized" && "$target" == "$text" && (( attempts > 20 )) ]]; then
      log_fail "Flagger Idle alors que target=$target — révision non détectée (pas un problème de métriques)"
      return 1
    fi
    if (( attempts % 5 == 0 )); then
      log_wait "phase=${phase:-?}  w=${weight:-?}  target=${target:-?}  primary=${primary:-?}"
    fi
    sleep 2
    attempts=$((attempts+1))
  done
  log_fail "Timed out waiting for promotion of $text (phase=${phase:-?} target=${target:-?} primary=${primary:-?})"
  return 1
}
wait_phase() {
  local desired="$1" attempts=0 phase weight
  while (( attempts < 240 )); do
    phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    weight="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.canaryWeight}' 2>/dev/null || true)"
    if [[ "$phase" == "$desired" ]]; then
      log_ok "canary phase=$phase  weight=${weight:-0}"
      return 0
    fi
    if (( attempts % 15 == 0 )); then
      log_wait "phase→$desired  now=${phase:-?}  weight=${weight:-?}"
    fi
    sleep 2
    attempts=$((attempts+1))
  done
  log_fail "Canary did not enter $desired"
  return 1
}

log_banner "Flagger lab · E2E smoke"

log_step "1/5  Gateway + baseline"
wait_httproute_accepted "$LAB_NS" podinfo
log_ok "HTTPRoute accepted"
bash "$ROOT_DIR/scripts/port-forward.sh" >"$out/port-forward.log" 2>&1 &
pf="$!"
wait_http http://127.0.0.1:8080/ "x-lab: smoke"
bash "$ROOT_DIR/scripts/traffic.sh" >"$out/load.log" 2>&1 &
load="$!"
log_ok "trafic de fond démarré"
recover_canary_baseline

log_step "2/5  Promotion progressive V2"
bash "$ROOT_DIR/scripts/promotion.sh"
wait_promoted 'FLAGGER LAB | V2 VALIDEE'

log_step "3/5  Rollback sur 5xx canary (V3)"
bash "$ROOT_DIR/scripts/rollback.sh"
wait_phase Failed
stable="$(podinfo_ui_message podinfo-primary)"
if [[ "$stable" != 'FLAGGER LAB | V2 VALIDEE' ]]; then
  log_fail "Stable revision corrupted by rollback: $stable"
  exit 1
fi
log_ok "primary intacte: $stable"
wait_http http://127.0.0.1:8080/ "x-lab: smoke"
# Belt-and-suspenders: let rate({{ interval }}) forget V3 5xx before A/B traffic.
log_wait "cool-down métriques post-rollback (15s)"
sleep 15

log_step "4/5  Routage A/B (header x-canary)"
bash "$ROOT_DIR/scripts/traffic.sh" ab >"$out/pilot.log" 2>&1 &
pilot="$!"
bash "$ROOT_DIR/scripts/ab.sh"
wait_phase Progressing
kubectl -n "$LAB_NS" get httproute podinfo -o yaml >"$out/ab-route.yaml"
grep -q 'x-canary' "$out/ab-route.yaml" || { log_fail "Header routing was not reconciled"; exit 1; }
log_ok "HTTPRoute contient le match x-canary"
log_info "vérif cohorte: beta → V4, public → V2"
matched=0
for i in $(seq 1 90); do
  internal="$(curl --max-time 3 -sS -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/api/info 2>/dev/null || true)"
  public="$(curl --max-time 3 -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/api/info 2>/dev/null || true)"
  if [[ "$internal" == *'V4 BETA'* && "$public" == *'V2 VALIDEE'* ]]; then
    matched=1
    break
  fi
  if (( i % 15 == 1 )); then
    log_wait "A/B split  (essai $i/90)"
  fi
  sleep 2
done
if (( matched == 0 )); then
  log_fail "A/B cohort separation never observed"
  exit 1
fi
log_ok "cohorte séparée (header vs public)"

log_step "5/5  Promotion cohorte V4"
wait_promoted 'FLAGGER LAB | V4 BETA'

printf '\n'
log_ok "PASS  gateway · trafic · promotion · rollback métrique · A/B · kubeconfig privé"
printf '\n'
