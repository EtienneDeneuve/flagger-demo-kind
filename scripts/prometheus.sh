#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context
echo "Prometheus -> http://localhost:9090/graph"
kubectl -n flagger-system port-forward svc/prometheus-lab 9090:9090
