#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
load_versions
for c in kind docker helm kubectl cilium; do require_command "$c"; done
docker info >/dev/null || { echo "Docker non disponible" >&2; exit 1; }

if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  echo "[1/8] Kind sans CNI par defaut"
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/kind/cluster.yaml" \
    --image "$KIND_NODE_IMAGE" --kubeconfig "$KUBECONFIG"
else
  echo "[1/8] Kind deja present"
  kind export kubeconfig --name "$CLUSTER_NAME" --kubeconfig "$KUBECONFIG"
fi
kubectl config use-context "$CLUSTER_CONTEXT" >/dev/null
require_context
node_version="$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}' 2>/dev/null || true)"
if [[ "$node_version" != "v$KUBERNETES_VERSION" ]]; then
  echo "Existing Kind cluster uses $node_version, expected v$KUBERNETES_VERSION." >&2
  echo "No automatic destructive upgrade. Run make cleanup and rerun ./setup.sh." >&2
  exit 2
fi

if ! helm -n kube-system status cilium >/dev/null 2>&1; then
  echo "[2/8] Cilium (kube-proxy conserve)"
  cilium install --version "$CILIUM_VERSION" --set operator.replicas=1 --set ipam.mode=kubernetes --set kubeProxyReplacement=false
fi
cilium status --wait
kubectl wait nodes --all --for=condition=Ready --timeout=300s

echo "[3/8] Envoy Gateway + Gateway API CRDs"
helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm \
  --version "$ENVOY_GATEWAY_VERSION" --namespace envoy-gateway-system \
  --create-namespace --wait --timeout 6m
kubectl -n envoy-gateway-system wait --for=condition=available deployment/envoy-gateway --timeout=300s

echo "[4/8] GatewayClass + Gateway"
kubectl apply -f "$ROOT_DIR/manifests/01-gateway.yaml"
# Un Service de type LoadBalancer peut rester Pending sur Kind sans LB controller.
# Le port-forward vers le proxy Envoy fonctionne sans IP LoadBalancer.
kubectl -n "$LAB_NS" get gateway lab-gateway
kubectl -n "$LAB_NS" wait --for=condition=Accepted gateway/lab-gateway --timeout=180s

echo "[5/8] Prometheus minimal"
kubectl create ns flagger-system --dry-run=client -o yaml | kubectl apply -f -
sed "s|prom/prometheus:v3.5.0|prom/prometheus:$PROMETHEUS_VERSION|" \
  "$ROOT_DIR/manifests/03-prometheus.yaml" | kubectl apply -f -
kubectl -n flagger-system rollout status deployment/prometheus-lab --timeout=300s

echo "[6/8] Flagger + Gateway API v1"
helm upgrade --install flagger oci://ghcr.io/fluxcd/charts/flagger \
  --version "$FLAGGER_VERSION" --namespace flagger-system --create-namespace \
  --wait --timeout 6m --set meshProvider=gatewayapi:v1 \
  --set prometheus.install=false \
  --set metricsServer=http://prometheus-lab.flagger-system.svc.cluster.local:9090

echo "[7/8] Podinfo et metrique de decision"
sed "s|ghcr.io/stefanprodan/podinfo:6.15.0|ghcr.io/stefanprodan/podinfo:$PODINFO_VERSION|" \
  "$ROOT_DIR/manifests/02-podinfo.yaml" | kubectl apply -f -
kubectl -n "$LAB_NS" rollout status deploy/podinfo --timeout=300s
kubectl apply -f "$ROOT_DIR/manifests/04-metrics.yaml"

echo "[8/8] Canary Flagger (HTTPRoute genere)"
kubectl apply -f "$ROOT_DIR/manifests/05-canary.yaml"
for i in $(seq 1 60); do
  if kubectl -n "$LAB_NS" get deploy podinfo-primary >/dev/null 2>&1; then break; fi
  sleep 3
done
kubectl -n "$LAB_NS" rollout status deploy/podinfo-primary --timeout=300s
kubectl -n "$LAB_NS" wait --for=condition=Accepted httproute/podinfo --timeout=180s
kubectl -n "$LAB_NS" get canary,httproute,deploy,svc
echo "Pret. Lancer make port, make traffic, make status dans 3 terminaux."
