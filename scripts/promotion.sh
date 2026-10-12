#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
kubectl -n "$LAB_NS" set env deployment/podinfo PODINFO_UI_MESSAGE='FLAGGER LAB | V2 VALIDEE' PODINFO_UI_COLOR='#16A085'
echo 'V2 demandee; observer promotion et poids Gateway API.'
