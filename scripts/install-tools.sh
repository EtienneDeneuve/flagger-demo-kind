#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_common.sh"
load_versions

case "$(uname -s)" in
  Darwin) platform=darwin ;;
  Linux) platform=linux ;;
  *) echo "Unsupported OS" >&2; exit 2 ;;
esac
case "$(uname -m)" in
  arm64|aarch64) arch=arm64 ;;
  x86_64) arch=amd64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 2 ;;
esac
for c in curl shasum tar mktemp install mv awk; do require_command "$c"; done
mkdir -p "$TOOLS_DIR/cache" "$TOOLS_DIR/state"

# These artifact SHA-256 values are from the upstream release asset metadata.
case "$platform:$arch" in
  darwin:arm64)
    kind_digest=0c8c7dbe5e23594a198b786c4bc13dacc101fa6196b0cb0b23a1ca44e61f4b4f
    cilium_digest=3521cb6af8f621d64dac63c7537fd9aa2ff878fb1f7a6f50e69b31bf45c02cb8 ;;
  darwin:amd64)
    kind_digest=5a99f26f57246dc9319dd294803313197a0f34d33c525b3ea8b655db5916ece0
    cilium_digest=b5ac658a9a87c933a3cc662f035d8ab4a3cbfdf67d942526b37566907a0d88ad ;;
  linux:arm64)
    kind_digest=20022bee6cfcd5086cb7234d218e3454e6090022f2a8f55d1fa7fcf42c3867a2
    cilium_digest=d237550b882af6f2e01e8985e1e024d57c0774611c0a527c7a20dcee7dc4fd07 ;;
  linux:amd64)
    kind_digest=aee6151561422756b764a4ae28e7f44cda5af5a9eead3cc9985112b1de8d8e0d
    cilium_digest=24e817dcfcc8a12e325ce7547617bcbcf171c5b0b335bb24d2bb1207ba047f61 ;;
esac
temp_dir="$(mktemp -d "$TOOLS_DIR/staging.XXXXXX")"
trap 'rm -rf "$temp_dir"' EXIT
sha256_file() { shasum -a 256 "$1" | awk '{print $1}'; }
verify_sha() {
  if [[ "$(sha256_file "$1")" != "$2" ]]; then
    echo "SHA-256 verification failed: $1" >&2
    exit 1
  fi
}
download() {
  local url="$1" dest="$2" expected="$3" part="$temp_dir/download.$$"
  if [[ -s "$dest" && "$(sha256_file "$dest")" == "$expected" ]]; then return; fi
  echo "Download: $url"
  curl --fail --location --silent --show-error --retry 3 \
    --connect-timeout 15 --max-time 300 "$url" -o "$part"
  verify_sha "$part" "$expected"
  mv -f "$part" "$dest"
}
remote_sha256() {
  local checksum
  checksum="$(curl --fail --location --silent --show-error --retry 3 "$1" | awk 'NR==1 {print $1}')"
  [[ "$checksum" =~ ^[0-9a-fA-F]{64}$ ]] || {
    echo "Invalid upstream checksum: $1" >&2; exit 1;
  }
  printf '%s' "$checksum"
}
installed() {
  [[ -x "$TOOLS_BIN/$1" && -f "$TOOLS_DIR/state/$1.version" ]] &&
    [[ "$(cat "$TOOLS_DIR/state/$1.version")" == "$2" ]]
}
save_binary() {
  local name="$1" version="$2" source="$3"
  install -m 755 "$source" "$TOOLS_BIN/$name.tmp.$$"
  mv -f "$TOOLS_BIN/$name.tmp.$$" "$TOOLS_BIN/$name"
  printf '%s\n' "$version" > "$TOOLS_DIR/state/$name.version"
}

if ! installed kind "$KIND_CLI_VERSION"; then
  name="kind-$platform-$arch"
  artifact="$TOOLS_DIR/cache/$name-$KIND_CLI_VERSION"
  download "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_CLI_VERSION/$name" "$artifact" "$kind_digest"
  save_binary kind "$KIND_CLI_VERSION" "$artifact"
fi
if ! installed kubectl "$KUBECTL_CLI_VERSION"; then
  base="https://dl.k8s.io/release/$KUBECTL_CLI_VERSION/bin/$platform/$arch/kubectl"
  sha="$(remote_sha256 "$base.sha256")"
  artifact="$TOOLS_DIR/cache/kubectl-$KUBECTL_CLI_VERSION-$arch"
  download "$base" "$artifact" "$sha"
  save_binary kubectl "$KUBECTL_CLI_VERSION" "$artifact"
fi
if ! installed helm "$HELM_CLI_VERSION"; then
  name="helm-$HELM_CLI_VERSION-$platform-$arch.tar.gz"
  base="https://get.helm.sh/$name"
  sha="$(remote_sha256 "$base.sha256sum")"
  artifact="$TOOLS_DIR/cache/$name"
  download "$base" "$artifact" "$sha"
  tar -xzf "$artifact" -C "$temp_dir" "$platform-$arch/helm"
  save_binary helm "$HELM_CLI_VERSION" "$temp_dir/$platform-$arch/helm"
fi
if ! installed cilium "$CILIUM_CLI_VERSION"; then
  name="cilium-$platform-$arch.tar.gz"
  artifact="$TOOLS_DIR/cache/cilium-$CILIUM_CLI_VERSION-$name"
  download "https://github.com/cilium/cilium-cli/releases/download/$CILIUM_CLI_VERSION/$name" "$artifact" "$cilium_digest"
  tar -xzf "$artifact" -C "$temp_dir" cilium
  save_binary cilium "$CILIUM_CLI_VERSION" "$temp_dir/cilium"
fi

echo
echo "Pinned tools installed in $TOOLS_BIN:"
"$TOOLS_BIN/kind" version
"$TOOLS_BIN/kubectl" version --client=true
"$TOOLS_BIN/helm" version --short
"$TOOLS_BIN/cilium" version --client
echo "No global tool installations were upgraded."
