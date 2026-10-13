#!/usr/bin/env bash
# À lancer dans Terminal/iTerm (pas depuis le sandbox Cursor).
# Log : .tools/verify-devenv-demo.log
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG="$ROOT/.tools/verify-devenv-demo.log"
mkdir -p "$ROOT/.tools"
exec > >(tee "$LOG") 2>&1

export PATH="$HOME/.rd/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) verify-devenv-demo ==="
echo "cwd=$ROOT uid=$(id -u) user=$(id -un)"
echo "path_docker=$(command -v docker || true)"
echo "path_devenv=$(command -v devenv || true)"

echo
echo "=== Docker (Rancher Moby) ==="
docker info
docker version

echo
echo "=== devenv shell env ==="
devenv shell -- bash -lc '
  set -euo pipefail
  echo DEVENV_OK
  echo "KUBECONFIG=$KUBECONFIG"
  echo "PATH_has_tools=$([[ ":$PATH:" == *":$PWD/.tools/bin:"* ]] && echo yes || echo no)"
  jq --version
'

echo
echo "=== install + cluster + doctor + e2e ==="
bash setup.sh --yes --mode=devenv --no-shell
bash scripts/doctor.sh
bash scripts/ci-smoke.sh

echo "PASS verify-devenv-demo $(date -u +%Y-%m-%dT%H:%M:%SZ)"
