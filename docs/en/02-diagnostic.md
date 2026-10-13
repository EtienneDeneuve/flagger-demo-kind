# Quick troubleshooting

**[Français](../02-diagnostic.md)** · English

## Mac cannot reach the Gateway LoadBalancer IP

Expected with Docker Desktop: Kind’s network lives in a Linux VM. Use `make port`, then `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/`. Do not edit `/etc/hosts` or macOS routing unless you choose to.

## No HTTPRoute/podinfo

```bash
./lab kubectl config current-context
./lab kubectl -n flagger-system logs deployment/flagger --tail=150
./lab kubectl -n flagger-demo describe canary/podinfo
./lab kubectl -n flagger-demo get gateway/lab-gateway -o yaml
```

Confirm Flagger `meshProvider=gatewayapi:v1`, Gateway `lab-gateway` is Accepted, and Gateway API v1 CRDs are present. Do not apply a competing hand-written `HTTPRoute` named `podinfo`.

## Missing metrics / “no values found”

```bash
./lab kubectl -n flagger-demo get pods -l app=podinfo -o wide
make metrics
```

In Prometheus try `up{job="podinfo-canary"}` then `http_requests_total{job="podinfo-canary"}`. Zero canary replicas between revisions → empty series is normal. During `Progressing`, wait for a few scrapes and ensure `make traffic` is not printing mostly `?`.

## Canary Failed before demo 2

Ensure `make traffic` and the Envoy tunnel are up. Do not confuse gateway 503s with Podinfo app 5xx. Check MetricTemplate results and Canary events.

## Port 8080 already in use

If `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/` already works, `make port` reuses it and exits OK. Otherwise free the port (`kill $(lsof -tiTCP:8080 -sTCP:LISTEN)`) then `make port`.

## Canary stuck Failed / recover not advancing

Flagger does **not** watch Deployment metadata annotations alone: you need a new **pod template** hash (env, image, or annotation under `spec.template`). See [../02-diagnostic.md](../02-diagnostic.md) for soft/hard reset commands, or `make cleanup && make up`.
