#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
kubectl -n "$LAB_NS" patch deployment podinfo --type=strategic -p '
{"spec":{"template":{"spec":{"containers":[{
  "name":"podinfod",
  "args":["--port=9898","--port-metrics=9797","--grpc-port=9999","--level=info","--random-error=true"],
  "env":[{"name":"PODINFO_UI_MESSAGE","value":"FLAGGER LAB | V3 DEGRADEE"},
         {"name":"PODINFO_UI_COLOR","value":"#D64949"}]
}]}}}}'
echo 'Version deployee avec 5xx aleatoires. Garder make traffic actif.'
