#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
ensure_docker_cli || true

log_banner "Flagger lab · doctor"
log_info "mode  KUBECONFIG=$KUBECONFIG"
log_info "path  .tools/bin=$TOOLS_BIN"
if [[ -n "${DEVENV_ROOT:-}${DEVENV_RUNTIME:-}" ]] || [[ "${IN_NIX_SHELL:-}" == "1" || -n "${DEVENV_DIR:-}" ]]; then
  log_info "shell  devenv/nix détecté (CLI K8s restent .tools/bin)"
else
  log_info "shell  local (sans Nix) — normal pour la majorité des participants"
fi

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

# make browser needs a working http.server (devenv ships python3; local = macOS /usr/bin).
py_ok=0
for candidate in python3 /usr/bin/python3; do
  if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then
    if "$candidate" -c 'import http.server, http.client' >/dev/null 2>&1; then
      log_ok "python3  $(command -v "$candidate" 2>/dev/null || echo "$candidate")  (make browser)"
      py_ok=1
      break
    fi
  fi
done
if (( py_ok == 0 )); then
  log_warn "python3/http.server absent — make browser KO ; curl -H 'Host: podinfo.local' suffit"
fi

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
