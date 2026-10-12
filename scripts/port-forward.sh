#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
selector='gateway.envoyproxy.io/owning-gateway-namespace=flagger-demo,gateway.envoyproxy.io/owning-gateway-name=lab-gateway'
svc=''
ns=''
for i in $(seq 1 40); do
  svc="$(kubectl get svc -A -l "$selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  ns="$(kubectl get svc -A -l "$selector" -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || true)"
  if [[ -n "$svc" && -n "$ns" ]]; then break; fi
  sleep 3
done
if [[ -z "$svc" || -z "$ns" ]]; then echo "Service Envoy absent" >&2; exit 1; fi
echo "localhost:8080 -> $ns/$svc:80"
kubectl -n "$ns" port-forward "service/$svc" 8080:80
