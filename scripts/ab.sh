#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
kubectl apply -f "$ROOT_DIR/manifests/06-canary-ab.yaml"
kubectl -n "$LAB_NS" set env deployment/podinfo \
  PODINFO_UI_MESSAGE='FLAGGER LAB | V4 BETA' \
  PODINFO_UI_COLOR='#8C62D6'
echo 'A/B active while Progressing: start make traffic-ab in another terminal.'
