#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
[[ -x "$TOOLS_BIN/kubectl" ]] || { echo "Run ./setup.sh first." >&2; exit 1; }
export PS1='(flagger-lab) %1~ %# '
export PROMPT="$PS1"
export LAB_ROOT="$ROOT_DIR"
cd "$ROOT_DIR"
echo "Local tools: $TOOLS_BIN"
echo "Isolated KUBECONFIG: $KUBECONFIG"
echo "Commands: make doctor | port | traffic | status | good | fail | ab"
exec /bin/zsh -f -i
