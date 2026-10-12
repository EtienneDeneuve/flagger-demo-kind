#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
mode=normal
if (( $# > 0 )); then mode="$1"; fi
[[ "$mode" == "normal" || "$mode" == "ab" ]] || { echo 'Mode attendu : normal ou ab' >&2; exit 2; }
echo "Trafic via Envoy, mode=$mode, 5 req/s. Ctrl+C pour stopper."
while true; do
  if [[ "$mode" == "ab" ]]; then
    code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 3 \
      -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/ || true)"
  else
    code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 3 \
      -H 'Host: podinfo.local' http://127.0.0.1:8080/ || true)"
  fi
  case "$code" in 2*) printf '.';; 5*) printf 'X';; *) printf '?';; esac
  sleep 0.2
done
