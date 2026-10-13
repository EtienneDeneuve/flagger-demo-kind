#!/usr/bin/env bash
# Tableau de bord TP : phase Canary, poids, messages UI primary/canary, derniers events.
# À laisser tourner pendant make good|fail|ab (docs/05-tp-participant.md).
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

bar() {
  local w="${1:-0}" max=50 filled empty i
  (( w > max )) && w=$max
  (( w < 0 )) && w=0
  filled=$((w / 2))
  empty=$((25 - filled))
  printf '['
  for ((i=0; i<filled; i++)); do printf '#'; done
  for ((i=0; i<empty; i++)); do printf '·'; done
  printf '] %s%%' "$w"
}

while true; do
  printf '\033[2J\033[H'
  phase="$(kubectl -n "$LAB_NS" get canary/podinfo -o jsonpath='{.status.phase}' 2>/dev/null || echo '?')"
  weight="$(kubectl -n "$LAB_NS" get canary/podinfo -o jsonpath='{.status.canaryWeight}' 2>/dev/null || echo 0)"
  failed="$(kubectl -n "$LAB_NS" get canary/podinfo -o jsonpath='{.status.failedChecks}' 2>/dev/null || echo 0)"
  primary="$(podinfo_ui_message podinfo-primary)"
  canary_msg="$(podinfo_ui_message podinfo)"
  [[ -n "$primary" ]] || primary='—'
  [[ -n "$canary_msg" ]] || canary_msg='—'
  http="$(http_code -H 'Host: podinfo.local' http://127.0.0.1:8080/)"

  printf '%s\n' "${_C_BOLD}Flagger lab · status${_C_RESET}  ${_C_DIM}$(date '+%H:%M:%S')${_C_RESET}"
  printf '%s\n' "${_C_CYAN}────────────────────────────────────────${_C_RESET}"
  printf '  phase     %s%s%s\n' "$_C_BOLD" "$phase" "$_C_RESET"
  printf '  canary    '; bar "$weight"; printf '\n'
  printf '  failed    %s\n' "$failed"
  printf '  gateway   HTTP %s  (Host: podinfo.local)\n' "${http:-—}"
  printf '%s\n' "${_C_CYAN}────────────────────────────────────────${_C_RESET}"
  printf '  primary   %s\n' "$primary"
  printf '  target    %s\n' "$canary_msg"
  echo
  echo "${_C_DIM}backends HTTPRoute${_C_RESET}"
  kubectl -n "$LAB_NS" get httproute/podinfo \
    -o jsonpath='{range .spec.rules[*]}{range .backendRefs[*]}  {.name}={.weight}{"\n"}{end}{end}' 2>/dev/null \
    || echo '  (route absente)'
  echo
  echo "${_C_DIM}deployments${_C_RESET}"
  kubectl -n "$LAB_NS" get deploy podinfo podinfo-primary --no-headers 2>/dev/null \
    | awk '{printf "  %-18s ready=%s\n", $1, $2}' || true
  echo
  echo "${_C_DIM}derniers événements Canary${_C_RESET}"
  kubectl -n "$LAB_NS" get events --field-selector involvedObject.kind=Canary \
    --sort-by=.lastTimestamp 2>/dev/null | tail -n 6 \
    | awk 'NR==1{next} {printf "  %s\n", substr($0, index($0,$5))}' || true
  sleep 3
done
