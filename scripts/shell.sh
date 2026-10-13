#!/usr/bin/env bash
# Shell lab SANS Nix : même KUBECONFIG / PATH .tools/bin que devenv.nix enterShell.
# Prérequis : ./setup.sh (ou --tools-only). Nix / devenv non requis.
set -euo pipefail
source "$(dirname "$0")/_common.sh"
[[ -x "$TOOLS_BIN/kubectl" ]] || { echo "Run ./setup.sh first (or ./setup.sh --tools-only)." >&2; exit 1; }
export PS1='(flagger-lab) %1~ %# '
export PROMPT="$PS1"
export LAB_ROOT="$ROOT_DIR"
cd "$ROOT_DIR"

echo "Flagger lab | local zsh | private KUBECONFIG | pinned .tools/bin (no Nix)"
echo "  tools:      $TOOLS_BIN"
echo "  KUBECONFIG: $KUBECONFIG"
echo "  reopen:     ./scripts/shell.sh   ·   or: ./setup.sh --mode=local --no-shell && ./scripts/shell.sh"
echo "  commands:   make doctor | port | traffic | status | browser | good | fail | ab"
if ! command -v python3 >/dev/null 2>&1 && [[ ! -x /usr/bin/python3 ]]; then
  echo "  note:       python3 absent → make browser indisponible (curl + Host header OK)"
fi
exec /bin/zsh -f -i
