#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
CLUSTER_NAME=flagger-platform-lab
CLUSTER_CONTEXT="kind-$CLUSTER_NAME"
LAB_NS=flagger-demo
require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Commande manquante : $1" >&2; exit 1; }
}
require_context() {
  require_command kubectl
  current="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$current" != "$CLUSTER_CONTEXT" ]]; then
    echo "Contexte incorrect: $current (attendu $CLUSTER_CONTEXT)" >&2
    exit 1
  fi
}
load_versions(){ source "$ROOT_DIR/versions.env"; }
