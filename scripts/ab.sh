#!/usr/bin/env bash
# TP 3 — apply manifests/tp/03-ab-canary.yaml + patch 03-revision-v4.
# Participant : docs/05-tp-participant.md
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

kubectl apply -f "$ROOT_DIR/manifests/tp/03-ab-canary.yaml" >/dev/null

patch="$(mktemp)"
trap 'rm -f "$patch"' EXIT
sed "s/flagger-lab\\/revision: \"v4-beta\"/flagger-lab\\/revision: \"v4-$(date +%s)\"/" \
  "$ROOT_DIR/manifests/tp/03-revision-v4.patch.yaml" >"$patch"
kubectl -n "$LAB_NS" patch deployment/podinfo --type strategic --patch-file "$patch" >/dev/null

log_ok "A/B V4 : Canary match header + révision (manifests/tp/03-*)"
log_info "pendant Progressing: make traffic-ab  · sans header = primary"
log_info "à la main: apply 03-ab-canary.yaml puis patch 03-revision-v4.patch.yaml"
