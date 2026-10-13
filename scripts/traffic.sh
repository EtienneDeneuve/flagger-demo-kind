#!/usr/bin/env bash
# Charge HTTP via Envoy (make traffic | make traffic-ab).
# Sans trafic, Prometheus n’a pas de rate() utile → Flagger ne peut pas juger.
# Légende : .=2xx  x=5xx  ?=autre (souvent gateway pas prête / mauvais Host).
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
mode=normal
if (( $# > 0 )); then mode="$1"; fi
[[ "$mode" == "normal" || "$mode" == "ab" ]] || { log_fail 'Mode attendu : normal ou ab'; exit 2; }

log_ok "trafic Envoy · mode=$mode · ~5 req/s · Ctrl+C stop"
log_info "légende: ${_C_GREEN}.${_C_RESET}=2xx  ${_C_RED}x${_C_RESET}=5xx  ?=autre"
ok=0 err=0 other=0
tick=0
while true; do
  if [[ "$mode" == "ab" ]]; then
    code="$(http_code -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/)"
  else
    code="$(http_code -H 'Host: podinfo.local' http://127.0.0.1:8080/)"
  fi
  case "$code" in
    2*) printf '%s' "${_C_GREEN}.${_C_RESET}"; ok=$((ok+1)) ;;
    5*) printf '%s' "${_C_RED}x${_C_RESET}"; err=$((err+1)) ;;
    *)  printf '?'; other=$((other+1)) ;;
  esac
  tick=$((tick+1))
  if (( tick % 50 == 0 )); then
    printf '  %s\n' "${_C_DIM}ok=$ok  5xx=$err  other=$other${_C_RESET}"
  fi
  sleep 0.2
done
