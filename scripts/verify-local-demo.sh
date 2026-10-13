#!/usr/bin/env bash
# Vérifie le parcours SANS Nix (mode local) — le chemin par défaut des participants.
# À lancer dans Terminal/iTerm (pas depuis le sandbox Cursor).
# Log : .tools/verify-local-demo.log
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG="$ROOT/.tools/verify-local-demo.log"
mkdir -p "$ROOT/.tools"
exec > >(tee "$LOG") 2>&1

# Minimal PATH: system + optional Rancher/OrbStack/Docker Desktop — no Nix profiles required.
export PATH="$HOME/.rd/bin:/Applications/Docker.app/Contents/Resources/bin:/Applications/OrbStack.app/Contents/MacOS:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) verify-local-demo (no Nix) ==="
echo "cwd=$ROOT uid=$(id -u) user=$(id -un)"
echo "path_docker=$(command -v docker || true)"
echo "path_devenv=$(command -v devenv || true)  (may be set; we force --mode=local)"
echo "path_python=$(command -v python3 || true)"
echo "usr_bin_python=$([[ -x /usr/bin/python3 ]] && echo yes || echo no)"

echo
echo "=== Docker ==="
docker info
docker version

echo
echo "=== install + cluster in LOCAL mode (isolated zsh toolchain) ==="
bash setup.sh --yes --mode=local --no-shell

echo
echo "=== shell env simulation (same exports as scripts/shell.sh / _common.sh) ==="
# shellcheck source=scripts/_common.sh
source "$ROOT/scripts/_common.sh"
echo "KUBECONFIG=$KUBECONFIG"
echo "PATH_has_tools=$([[ ":$PATH:" == *":$ROOT/.tools/bin:"* ]] && echo yes || echo no)"
echo "kubectl=$(command -v kubectl)"
kubectl version --client=true

echo
echo "=== doctor + e2e ==="
bash scripts/doctor.sh
bash scripts/ci-smoke.sh

echo "PASS verify-local-demo $(date -u +%Y-%m-%dT%H:%M:%SZ)"
