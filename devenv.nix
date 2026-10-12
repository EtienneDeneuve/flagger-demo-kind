{ pkgs, ... }:
{
  # Quality-of-life tools come from pinned nixpkgs. Kubernetes CLIs still come
  # from ./setup.sh into .tools/bin, so Nix and non-Nix participants match.
  packages = with pkgs; [
    zsh
    jq
    curl
    git
  ];

  enterShell = ''
    export PATH="$PWD/.tools/bin:$PATH"
    export KUBECONFIG="$PWD/.tools/kubeconfig"
    export HELM_CONFIG_HOME="$PWD/.tools/helm/config"
    export HELM_CACHE_HOME="$PWD/.tools/helm/cache"
    export HELM_DATA_HOME="$PWD/.tools/helm/data"
    echo "Flagger lab | devenv | private KUBECONFIG | pinned local Kubernetes tools"
  '';
}
