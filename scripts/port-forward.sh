#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

# Idempotent: a leftover e2e / prior `make port` often still holds :8080.
if http_ok -H 'Host: podinfo.local' http://127.0.0.1:8080/; then
  log_ok "localhost:8080 déjà actif (Host: podinfo.local → HTTP OK)"
  log_info "curl -H 'Host: podinfo.local' http://127.0.0.1:8080/   ·  make browser pour l’UI"
  log_info "pour forcer un nouveau tunnel : kill \$(lsof -tiTCP:8080 -sTCP:LISTEN) puis make port"
  exit 0
fi

selector='gateway.envoyproxy.io/owning-gateway-namespace=flagger-demo,gateway.envoyproxy.io/owning-gateway-name=lab-gateway'
svc=''
ns=''
log_wait "recherche Service Envoy Gateway…"
for i in $(seq 1 40); do
  svc="$(kubectl get svc -A -l "$selector" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  ns="$(kubectl get svc -A -l "$selector" -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || true)"
  if [[ -n "$svc" && -n "$ns" ]]; then break; fi
  sleep 3
done
if [[ -z "$svc" || -z "$ns" ]]; then
  log_fail "Service Envoy absent"
  exit 1
fi
log_ok "localhost:8080  →  $ns/$svc:80"
log_info "curl -H 'Host: podinfo.local' http://127.0.0.1:8080/   ·  make browser pour l’UI"
kubectl -n "$ns" port-forward "service/$svc" 8080:80
