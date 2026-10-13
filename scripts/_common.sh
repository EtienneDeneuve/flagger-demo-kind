#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/.tools"
TOOLS_BIN="$TOOLS_DIR/bin"
CLUSTER_NAME="flagger-platform-lab"
CLUSTER_CONTEXT="kind-$CLUSTER_NAME"
LAB_NS="flagger-demo"

# Private lab-specific kubectl, Helm and Kubernetes context, never ~/.kube/config.
umask 077
mkdir -p "$TOOLS_BIN" "$TOOLS_DIR/helm/config" "$TOOLS_DIR/helm/cache" "$TOOLS_DIR/helm/data"
export PATH="$TOOLS_BIN:$PATH"
export KUBECONFIG="$TOOLS_DIR/kubeconfig"
export HELM_CONFIG_HOME="$TOOLS_DIR/helm/config"
export HELM_CACHE_HOME="$TOOLS_DIR/helm/cache"
export HELM_DATA_HOME="$TOOLS_DIR/helm/data"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing $1. Run ./setup.sh from the repository root." >&2
    exit 1
  }
}
require_context() {
  require_command kubectl
  local current
  current="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$current" != "$CLUSTER_CONTEXT" ]]; then
    echo "Refusing kubectl operation: context '$current', expected '$CLUSTER_CONTEXT'." >&2
    echo "Run ./setup.sh to initialize the private project KUBECONFIG." >&2
    exit 1
  fi
}
load_versions() { source "$ROOT_DIR/versions.env"; }

# Gateway API HTTPRoute does not have top-level .status.conditions:
# acceptance is recorded under .status.parents[*].conditions.
wait_httproute_accepted() {
  local namespace="$1" route="$2" attempts=0 condition refs
  for ((attempts=0; attempts<90; attempts++)); do
    condition="$(kubectl -n "$namespace" get httproute "$route" \
      -o jsonpath='{.status.parents[*].conditions[?(@.type=="Accepted")].status}' 2>/dev/null || true)"
    refs="$(kubectl -n "$namespace" get httproute "$route" \
      -o jsonpath='{.status.parents[*].conditions[?(@.type=="ResolvedRefs")].status}' 2>/dev/null || true)"
    if [[ "$condition" == *True* && "$refs" != *False* ]]; then return 0; fi
    sleep 2
  done
  echo "HTTPRoute $namespace/$route not Accepted/ResolvedRefs after 180s" >&2
  kubectl -n "$namespace" describe httproute "$route" >&2 || true
  return 1
}
