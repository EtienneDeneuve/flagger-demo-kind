#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
missing=0
for c in kind docker helm kubectl cilium curl; do
  if command -v "$c" >/dev/null 2>&1; then echo "OK $c"; else echo "MANQUANT $c"; missing=1; fi
done
(( missing == 0 )) || exit 1
docker info >/dev/null || { echo 'Docker non disponible'; exit 1; }
if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  echo "Cluster absent. Lancer make up."
  exit 0
fi
require_context
kubectl get nodes
kubectl -n flagger-system get deploy prometheus-lab flagger
kubectl -n "$LAB_NS" get gateway,canary,httproute,pods 2>/dev/null || true
