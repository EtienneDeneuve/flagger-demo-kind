#!/usr/bin/env bash
# TP 2 — patch manifests/tp/02-degraded-v3.patch.yaml + fault injection HTTP.
# Participant : docs/05-tp-participant.md (faire les deux étapes à la main).
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

# Mode poids (au cas où le Canary était encore en A/B).
kubectl apply -f "$ROOT_DIR/manifests/05-canary.yaml" >/dev/null

patch="$(mktemp)"
trap 'rm -f "$patch"' EXIT
sed "s/flagger-lab\\/revision: \"v3-degraded\"/flagger-lab\\/revision: \"v3-$(date +%s)\"/" \
  "$ROOT_DIR/manifests/tp/02-degraded-v3.patch.yaml" >"$patch"
kubectl -n "$LAB_NS" patch deployment/podinfo --type strategic --patch-file "$patch" >/dev/null
log_ok "V3 dégradée demandée (manifests/tp/02-degraded-v3.patch.yaml)"
log_wait "canary Progressing + endpoints…"

ready=0
for i in $(seq 1 90); do
  phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  weight="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.canaryWeight}' 2>/dev/null || true)"
  if [[ "$phase" == "Progressing" ]]; then
    pods="$(kubectl -n "$LAB_NS" get endpointslice \
      -l kubernetes.io/service-name=podinfo-canary \
      -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null || true)"
    if [[ -n "$pods" ]]; then
      log_ok "canary prête  phase=$phase  weight=${weight:-0}"
      ready=1
      break
    fi
  fi
  if (( i % 10 == 1 )); then
    log_wait "phase=${phase:-?}  weight=${weight:-?}  · tick 10s"
  fi
  sleep 2
done
if (( ready == 0 )); then
  log_fail "Pas de canary prête après 180s — make status"
  exit 1
fi

logfile="$(mktemp)"
pfpid=''
cleanup() {
  if [[ -n "$pfpid" ]]; then
    kill "$pfpid" 2>/dev/null || true
    wait "$pfpid" 2>/dev/null || true
  fi
  rm -f "$logfile"
}
trap cleanup EXIT
kubectl -n "$LAB_NS" port-forward svc/podinfo-canary 19898:9898 >"$logfile" 2>&1 &
pfpid="$!"

for _ in $(seq 1 25); do
  if curl -sS --connect-timeout 1 --max-time 3 -o /tmp/flagger-fault.json \
     -X POST http://127.0.0.1:19898/fault_injection/enable 2>/dev/null; then
    log_ok "fault injection activée (canary only · healthz/readyz/metrics intacts)"
    log_info "à la main: port-forward svc/podinfo-canary 19898:9898 puis curl -X POST …/fault_injection/enable"
    exit 0
  fi
  if ! kill -0 "$pfpid" 2>/dev/null; then
    cat "$logfile" >&2
    log_fail "port-forward canary mort"
    exit 1
  fi
  sleep 1
done
cat "$logfile" >&2
log_fail "Fault injection timed out"
exit 1
