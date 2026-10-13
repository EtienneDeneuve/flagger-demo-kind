# Technical architecture and trade-offs

**[Français](../01-architecture.md)** · English

```text
macOS (curl / browser)
       |
       | localhost:8080 -- kubectl port-forward
       v
  Envoy data plane          <-- Envoy Gateway (Gateway API)
       |
       | HTTPRoute podinfo (owned and updated by Flagger)
       |       e.g. 75% / 25% … then 100% primary
       +------------------+-----------------------+
       v                  v                       |
 podinfo-primary      podinfo-canary              |
 (stable)             (candidate)                 |
                          |                       |
                          +--> /metrics :9797     |
                                     |            |
                               Prometheus         |
                                     |            |
                               MetricTemplate     |
                                     |            |
                                Flagger ----------+
```

Cilium (CNI) provides pod networking on Kind. This lab **keeps kube-proxy** to save setup time; it is not a full reproduction of every AKS networking option. Envoy Gateway implements Gateway API v1 (`GatewayClass`, `Gateway`, `HTTPRoute`). Flagger watches the Deployment and owns **only** its canary `HTTPRoute`. Do not deploy a hand-written route for the same host.

## Why the metric comes from Podinfo

Envoy Gateway series would require a stable label/route mapping across gateway, upstream clusters, and HTTPRoute backends. For teaching, we use Podinfo’s app SLI `http_requests_total`, filtered to **canary** pods and HTTP status. Traffic that generates those metrics still flows through Envoy Gateway.

In production, combine **Envoy upstream** and application signals, watch low-traffic sampling bias, add an availability metric, and be strict about observation windows, timeouts, and rollback conditions.

## Deliberately out of scope

- TLS and authn policies — localhost HTTP only.
- GitOps (Flux / Argo) driving the app change — none in the lab.
- Admission policies, NetworkPolicy, supply chain, production RBAC.
- Cilium kube-proxy replacement, eBPF LB, or Hubble — not required.
- HA Prometheus — single instance, no persistent disk, 3 h retention.

## Official references

- [Flagger — Gateway API progressive delivery](https://docs.flagger.app/tutorials/gatewayapi-progressive-delivery)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway](https://gateway.envoyproxy.io/)
- [Cilium docs](https://docs.cilium.io/en/stable/)
