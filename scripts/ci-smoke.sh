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
  echo "E2E failed: collecting diagnostic logs." >&2
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
  local url="$1" header="$2" attempts=0
  while (( attempts < 90 )); do
    if curl -fsS --max-time 3 -o /dev/null -H "Host: podinfo.local" -H "$header" "$url"; then
      return 0
    fi
    attempts=$((attempts+1))
    sleep 2
  done
  echo "HTTP endpoint unavailable: $url" >&2
  return 1
}
wait_promoted() {
  local text="$1" attempts=0
  while (( attempts < 240 )); do
    local config phase
    config="$(kubectl -n "$LAB_NS" get deployment podinfo-primary -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}' 2>/dev/null || true)"
    phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    if [[ "$config" == "$text" && "$phase" == "Succeeded" ]]; then return 0; fi
    sleep 2
    attempts=$((attempts+1))
  done
  echo "Timed out waiting for promotion of $text" >&2
  return 1
}
wait_phase() {
  local desired="$1" attempts=0
  while (( attempts < 240 )); do
    local phase
    phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    if [[ "$phase" == "$desired" ]]; then return 0; fi
    sleep 2
    attempts=$((attempts+1))
  done
  echo "Canary did not enter $desired" >&2
  return 1
}

echo "E2E 1/4: bootstrapped workload and Gateway are available"
wait_httproute_accepted "$LAB_NS" podinfo
bash "$ROOT_DIR/scripts/port-forward.sh" >"$out/port-forward.log" 2>&1 &
pf="$!"
wait_http http://127.0.0.1:8080/ "x-lab: smoke"
bash "$ROOT_DIR/scripts/traffic.sh" >"$out/load.log" 2>&1 &
load="$!"

echo "E2E 2/4: measuring real HTTP traffic and promoting a revision"
bash "$ROOT_DIR/scripts/promotion.sh"
wait_promoted 'FLAGGER LAB | V2 VALIDEE'

echo "E2E 3/4: injecting a deterministic HTTP 500 only into canary"
bash "$ROOT_DIR/scripts/rollback.sh"
wait_phase Failed
stable="$(kubectl -n "$LAB_NS" get deployment podinfo-primary -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}')"
[[ "$stable" == 'FLAGGER LAB | V2 VALIDEE' ]] || { echo "Stable revision corrupted by rollback" >&2; exit 1; }
wait_http http://127.0.0.1:8080/ "x-lab: smoke"

echo "E2E 4/4: matching a pilot cohort with Gateway API"
bash "$ROOT_DIR/scripts/traffic.sh" ab >"$out/pilot.log" 2>&1 &
pilot="$!"
bash "$ROOT_DIR/scripts/ab.sh"
wait_phase Progressing
kubectl -n "$LAB_NS" get httproute podinfo -o yaml >"$out/ab-route.yaml"
grep -q 'x-canary' "$out/ab-route.yaml" || { echo "Header routing was not reconciled" >&2; exit 1; }
echo "Verifying that only the beta cohort sees V4 while public traffic stays on V2"
matched=0
for i in $(seq 1 90); do
  internal="$(curl --max-time 3 -fsS -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/api/info || true)"
  public="$(curl --max-time 3 -fsS -H 'Host: podinfo.local' http://127.0.0.1:8080/api/info || true)"
  if [[ "$internal" == *'V4 BETA'* && "$public" == *'V2 VALIDEE'* ]]; then
    matched=1
    break
  fi
  sleep 2
done
if (( matched == 0 )); then
  echo "A/B cohort separation never observed" >&2
  exit 1
fi
wait_promoted 'FLAGGER LAB | V4 BETA'

echo "PASS: gateway, traffic, promotion, metric-driven rollback, A/B, private kubeconfig"
