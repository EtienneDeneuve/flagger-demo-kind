#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

# New version remains healthy; failure is enabled only at the HTTP layer.
kubectl -n "$LAB_NS" set env deployment/podinfo \
  PODINFO_UI_MESSAGE='FLAGGER LAB | V3 DEGRADEE' \
  PODINFO_UI_COLOR='#D64949'
echo "Waiting for canary to enter Progressing and receive endpoints..."
ready=0
for _ in $(seq 1 90); do
  phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$phase" == "Progressing" ]]; then
    pods="$(kubectl -n "$LAB_NS" get endpointslice \
      -l kubernetes.io/service-name=podinfo-canary \
      -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null || true)"
    if [[ -n "$pods" ]]; then ready=1; break; fi
  fi
  sleep 2
done
if (( ready == 0 )); then
  echo "No ready canary after 180 seconds; inspect make status." >&2
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
  if curl -fsS --connect-timeout 1 --max-time 3 \
     -X POST http://127.0.0.1:19898/fault_injection/enable; then
    echo
    echo "Fault injection ENABLED in canary only (healthz/readyz/metrics unaffected)."
    exit 0
  fi
  if ! kill -0 "$pfpid" 2>/dev/null; then cat "$logfile" >&2; exit 1; fi
  sleep 1
done
cat "$logfile" >&2
echo "Fault injection timed out." >&2
exit 1
