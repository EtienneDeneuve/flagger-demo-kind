{ pkgs, ... }:
{
  # Optional QoL only. Participants WITHOUT Nix use ./scripts/shell.sh — same
  # KUBECONFIG / .tools/bin contract (see scripts/_common.sh). Never put kind /
  # kubectl / helm / cilium here: setup.sh pins them into .tools/bin for both modes.
  packages = with pkgs; [
    zsh
    jq
    curl
    git
    python3 # make browser; local mode uses macOS /usr/bin/python3 instead
  ];

  enterShell = ''
    export PATH="$PWD/.tools/bin:$PATH"
    export KUBECONFIG="$PWD/.tools/kubeconfig"
    export HELM_CONFIG_HOME="$PWD/.tools/helm/config"
    export HELM_CACHE_HOME="$PWD/.tools/helm/cache"
    export HELM_DATA_HOME="$PWD/.tools/helm/data"
    echo "Flagger lab | devenv | private KUBECONFIG | pinned local Kubernetes tools"
    echo "  (same contract as ./scripts/shell.sh — Nix is optional)"
  '';
}
