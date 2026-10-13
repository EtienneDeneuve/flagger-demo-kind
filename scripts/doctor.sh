#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
ensure_docker_cli || true

log_banner "Flagger lab · doctor"
missing=0
for c in kind docker helm kubectl cilium curl; do
  if command -v "$c" >/dev/null 2>&1; then
    loc="$(command -v "$c")"
    if [[ "$c" != docker && "$c" != curl && "$loc" != "$TOOLS_BIN/$c" ]]; then
      log_warn "$c  $loc  (pas .tools/bin)"
    else
      log_ok "$c  $loc"
    fi
  else
    log_fail "$c manquant"
    missing=1
  fi
done
(( missing == 0 )) || exit 1

if ! docker info >/dev/null 2>&1; then
  log_fail "Docker non disponible"
  exit 1
fi
log_ok "engine  $(docker info --format '{{.Name}} / {{.ServerVersion}}' 2>/dev/null || echo '?')"

if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  log_warn "cluster absent — make up"
  exit 0
fi
require_context
echo
log_info "nodes"
kubectl get nodes
echo
log_info "flagger-system"
kubectl -n flagger-system get deploy prometheus-lab flagger
echo
log_info "flagger-demo"
kubectl -n "$LAB_NS" get gateway,canary,httproute,pods 2>/dev/null || true
gw="$(kubectl -n "$LAB_NS" get gateway lab-gateway -o jsonpath='{.status.conditions[?(@.type=="Programmed")].reason}' 2>/dev/null || true)"
if [[ "$gw" == "AddressNotAssigned" ]]; then
  log_info "Gateway Programmed=False (AddressNotAssigned) : normal sur Kind — utiliser make port"
fi
