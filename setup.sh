#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
MODE=auto
WITH_CLUSTER=1
WITH_SHELL=1
YES=0
usage() {
  cat <<'HELP'
Usage: ./setup.sh [--yes] [--tools-only] [--no-shell] [--mode=auto|local|devenv]
  --yes          Noninteractive: install tools + cluster; never open a shell
  --tools-only   Install project-local pinned CLI tools, skip Kubernetes installation
  --no-shell     Return to your original terminal
  --mode=local   Use isolated /bin/zsh, without Nix
  --mode=devenv  Use existing devenv; never auto-install Nix
Default: three short questions, no brew upgrade, no dotfile or ~/.kube edits.
HELP
}
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1; WITH_SHELL=0 ;;
    --tools-only) WITH_CLUSTER=0 ;;
    --no-shell) WITH_SHELL=0 ;;
    --mode=auto) MODE=auto ;;
    --mode=local) MODE=local ;;
    --mode=devenv) MODE=devenv ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 2 ;;
  esac
done
if [[ "$(uname -s)" != Darwin ]]; then
  echo "This one-command onboarding currently supports macOS only." >&2
  exit 2
fi
interactive=0
if [[ -t 0 && "$YES" == 0 ]]; then interactive=1; fi
ask() {
  local question="$1" default="$2" answer
  if [[ "$interactive" == 0 ]]; then printf '%s' "$default"; return; fi
  read -r -p "$question [$default] : " answer
  if [[ -z "$answer" ]]; then answer="$default"; fi
  printf '%s' "$answer"
}
echo "Flagger Demo Kind — nothing is upgraded globally."
echo "Pinned tools live in .tools/bin, Kubernetes settings in .tools/kubeconfig."
if [[ "$interactive" == 1 ]]; then
  answer="$(ask '1/3 - Shell mode [auto/local/devenv]' "$MODE")"
  case "$answer" in auto|local|devenv) MODE="$answer";; *) echo "Invalid mode" >&2; exit 2;; esac
  answer="$(ask '2/3 - Install Kind cluster now? [Y/n]' Y)"
  case "$answer" in n|N|no|NO) WITH_CLUSTER=0;; esac
  answer="$(ask '3/3 - Enter the project shell afterward? [Y/n]' Y)"
  case "$answer" in n|N|no|NO) WITH_SHELL=0;; esac
fi
if [[ "$MODE" == auto ]]; then
  if command -v devenv >/dev/null 2>&1; then MODE=devenv; else MODE=local; fi
fi
if [[ "$MODE" == devenv ]] && ! command -v devenv >/dev/null 2>&1; then
  echo "devenv not installed; using isolated zsh without changing Nix or the host." >&2
  MODE=local
fi
bash "$ROOT/scripts/install-tools.sh"

if [[ "$WITH_CLUSTER" == 1 ]]; then
  # Only the container engine is outside the project toolchain.
  # shellcheck source=scripts/_common.sh
  source "$ROOT/scripts/_common.sh"
  ensure_docker_cli || true
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker CLI not found. Install/start Docker Desktop, OrbStack, Rancher Desktop (Moby) or Docker+Colima." >&2
    exit 2
  fi
  if ! docker info >/dev/null 2>&1; then
    if command -v colima >/dev/null 2>&1 && [[ "$interactive" == 1 ]]; then
      answer="$(ask 'Container engine stopped. Start installed Colima? [y/N]' N)"
      case "$answer" in y|Y|yes|YES) colima start;; esac
    fi
    if command -v rdctl >/dev/null 2>&1 && [[ "$interactive" == 1 ]]; then
      answer="$(ask 'Container engine stopped. Start installed Rancher Desktop? [y/N]' N)"
      case "$answer" in y|Y|yes|YES) rdctl start --container-engine.name=moby || true;; esac
    fi
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "Container engine unavailable. Start Docker Desktop/OrbStack/Rancher Desktop (Moby)/Colima and retry." >&2
    exit 2
  fi
  bash "$ROOT/scripts/bootstrap.sh"
fi

echo
echo "Ready."
if [[ "$MODE" == devenv ]]; then
  echo "  Reopen later:  devenv shell"
  echo "  Force no-Nix:  ./setup.sh --mode=local   then  ./scripts/shell.sh"
else
  echo "  Reopen later:  ./scripts/shell.sh   (isolated zsh, no Nix required)"
  echo "  Tip: make * works from any terminal once .tools/bin exists (scripts load _common.sh)."
fi
if [[ "$WITH_SHELL" == 1 ]]; then
  if [[ "$MODE" == devenv ]]; then
    exec devenv shell
  else
    exec bash "$ROOT/scripts/shell.sh"
  fi
fi
