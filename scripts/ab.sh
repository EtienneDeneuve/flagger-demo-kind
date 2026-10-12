#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
kubectl apply -f "$ROOT_DIR/manifests/06-canary-ab.yaml"
kubectl -n "$LAB_NS" patch deployment podinfo --type=strategic -p '
{"spec":{"template":{"spec":{"containers":[{
  "name":"podinfod",
  "args":["--port=9898","--port-metrics=9797","--grpc-port=9999","--level=info","--random-error=false"],
  "env":[{"name":"PODINFO_UI_MESSAGE","value":"FLAGGER LAB | V4 BETA"},
         {"name":"PODINFO_UI_COLOR","value":"#8C62D6"}]
}]}}}}'
echo 'A/B : ouvrir make traffic-ab pendant la phase Progressing.'
