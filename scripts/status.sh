#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
while true; do
  printf '\033[2J\033[H'
  date '+%H:%M:%S'
  echo '--- CANARY ---'
  kubectl -n "$LAB_NS" get canary/podinfo || true
  echo '--- ROUTE HTTP / BACKENDS ---'
  kubectl -n "$LAB_NS" get httproute/podinfo -o jsonpath='{range .spec.rules[*]}{range .backendRefs[*]}{.name}{"="}{.weight}{" "}{end}{"\n"}{end}' 2>/dev/null || true
  echo '--- DEPLOYMENTS ---'
  kubectl -n "$LAB_NS" get deploy podinfo podinfo-primary 2>/dev/null || true
  echo '--- EVENEMENTS ---'
  kubectl -n "$LAB_NS" get events --field-selector involvedObject.kind=Canary --sort-by=.lastTimestamp 2>/dev/null | tail -n 8 || true
  sleep 3
done
