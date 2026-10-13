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

# Docker Desktop / OrbStack / Rancher Desktop (Moby) often ship a private CLI path.
# Rancher with pathManagementStrategy=manual keeps ~/.rd/bin off the default PATH.
# Important: ~/.rd/bin also ships kubectl/helm — never let them shadow .tools/bin pins.
ensure_docker_cli() {
  if command -v docker >/dev/null 2>&1; then
    export PATH="$TOOLS_BIN:$PATH"
    return 0
  fi
  local candidates=(
    "$HOME/.rd/bin"
    "/Applications/Docker.app/Contents/Resources/bin"
    "/Applications/OrbStack.app/Contents/MacOS"
  )
  local dir
  for dir in "${candidates[@]}"; do
    if [[ -x "$dir/docker" ]]; then
      export PATH="$TOOLS_BIN:$dir:$PATH"
      return 0
    fi
  done
  return 1
}
require_docker() {
  ensure_docker_cli || {
    echo "Docker CLI not found. Install/start Docker Desktop, OrbStack, Rancher Desktop (Moby) or Docker+Colima." >&2
    exit 1
  }
  docker info >/dev/null 2>&1 || {
    echo "Container engine unavailable. Start Docker Desktop / OrbStack / Rancher Desktop / Colima and retry." >&2
    exit 1
  }
}
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

# Avoid nested-quote breakage: stable="$(... jsonpath='...@.name=="X"...')" is invalid bash.
podinfo_ui_message() {
  local deploy="$1"
  kubectl -n "$LAB_NS" get deployment "$deploy" \
    -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"PODINFO_UI_MESSAGE\")].value}" \
    2>/dev/null || true
}

# --- terminal UI (TTY-aware; plain text when piped) ---
if [[ -t 1 ]]; then
  _C_RESET=$'\033[0m' _C_DIM=$'\033[2m' _C_BOLD=$'\033[1m'
  _C_GREEN=$'\033[32m' _C_YELLOW=$'\033[33m' _C_RED=$'\033[31m' _C_CYAN=$'\033[36m'
else
  _C_RESET= _C_DIM= _C_BOLD= _C_GREEN= _C_YELLOW= _C_RED= _C_CYAN=
fi
log_banner() {
  printf '%s\n' "${_C_CYAN}────────────────────────────────────────${_C_RESET}"
  printf '%s\n' "${_C_BOLD}$*${_C_RESET}"
  printf '%s\n' "${_C_CYAN}────────────────────────────────────────${_C_RESET}"
}
log_step()  { printf '%s\n' "${_C_BOLD}▸${_C_RESET} $*"; }
log_ok()    { printf '%s\n' "${_C_GREEN}✓${_C_RESET} $*"; }
log_wait()  { printf '%s\n' "${_C_DIM}… $*${_C_RESET}"; }
log_info()  { printf '%s\n' "  ${_C_DIM}$*${_C_RESET}"; }
log_warn()  { printf '%s\n' "${_C_YELLOW}!${_C_RESET} $*" >&2; }
log_fail()  { printf '%s\n' "${_C_RED}✗${_C_RESET} $*" >&2; }

# Quiet HTTP probe — never prints curl's "returned error: 500" noise.
http_code() {
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 3 "$@" 2>/dev/null || true)"
  [[ -n "$code" ]] || code=000
  printf '%s' "$code"
}
http_ok() {
  local code
  code="$(http_code "$@")"
  [[ "$code" == 2* ]]
}

# After Failed, a same-spec "set env" does nothing: lastAppliedSpec already
# matches primary. Soft pod-template patches are unreliable here — recreate
# the Canary CR (lab-safe) and wait for Initialized/Succeeded.
recover_canary_baseline() {
  local phase msg color attempts=0
  phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$phase" == "Succeeded" || "$phase" == "Initialized" ]]; then
    log_ok "canary baseline  phase=$phase"
    return 0
  fi
  # Always reset to VERSION STABLE so the next `make good` / smoke V2 is a real revision.
  # Copying primary when it is already V2 leaves Flagger Idle (Initialized) with nothing to promote.
  msg='FLAGGER LAB | VERSION STABLE'
  color='#285F80'

  log_warn "canary phase=${phase:-?} — recreate Canary sur VERSION STABLE"
  load_versions
  kubectl -n "$LAB_NS" delete canary podinfo --ignore-not-found --wait=true --timeout=120s >/dev/null
  sed "s|ghcr.io/stefanprodan/podinfo:6.15.0|ghcr.io/stefanprodan/podinfo:$PODINFO_VERSION|" \
    "$ROOT_DIR/manifests/02-podinfo.yaml" | kubectl apply -f - >/dev/null
  kubectl -n "$LAB_NS" set env deployment/podinfo \
    PODINFO_UI_MESSAGE="$msg" PODINFO_UI_COLOR="$color" >/dev/null
  kubectl -n "$LAB_NS" rollout status deployment/podinfo --timeout=180s >/dev/null
  kubectl apply -f "$ROOT_DIR/manifests/05-canary.yaml" >/dev/null

  while (( attempts < 90 )); do
    phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    if [[ "$phase" == "Succeeded" || "$phase" == "Initialized" ]]; then
      log_ok "baseline rétablie  phase=$phase"
      return 0
    fi
    if (( attempts % 8 == 0 )); then
      log_wait "baseline  phase=${phase:-?}  · init Flagger"
    fi
    sleep 2
    attempts=$((attempts+1))
  done
  log_fail "impossible de rétablir la canary (phase=${phase:-?})"
  return 1
}

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
    if (( attempts % 10 == 0 )); then
      log_wait "HTTPRoute $namespace/$route Accepted/ResolvedRefs…"
    fi
    sleep 2
  done
  log_fail "HTTPRoute $namespace/$route not Accepted/ResolvedRefs after 180s"
  kubectl -n "$namespace" describe httproute "$route" >&2 || true
  return 1
}
