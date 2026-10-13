# Architecture technique et compromis

**Français** · **[English](en/01-architecture.md)**

```text
Mac macOS (curl / Marp)
       |
       | localhost:8080 -- kubectl port-forward
       v
  Envoy proxy data plane    <-- Envoy Gateway controller (Gateway API)
       |
       | HTTPRoute podinfo (genere et modifie par Flagger)
       |       90% / 10% ... puis 100% primary
       +------------------+-----------------------+
       v                  v                       |
 podinfo-primary      podinfo-canary              |
 (version stable)     (version testee)            |
                          |                       |
                          +--> /metrics :9797     |
                                     |            |
                               Prometheus         |
                                     |            |
                               MetricTemplate     |
                                     |            |
                                Flagger ----------+
```

Cilium (CNI) fournit la connectivite pod a pod sur Kind. Ce lab **conserve kube-proxy** pour gagner du temps ; ce n'est pas une reproduction de toutes les options reseau d'un AKS. Envoy Gateway implemente Gateway API v1 (GatewayClass, Gateway, HTTPRoute). Flagger observe le Deployment et gere **exclusivement** son HTTPRoute canary. Ne pas deployer de route ecrite a la main avec le meme host.

## Pourquoi la metrique vient de Podinfo

Les series Envoy Gateway exigeraient de valider un mapping de labels et de routes stable entre la gateway, les clusters upstream et les backends de l'HTTPRoute. Pour la pedagogie, on se limite au SLI applicatif Podinfo `http_requests_total`, filtre par les pods canary et le status HTTP. Le trafic qui produit ces metriques passe toutefois par Envoy Gateway.

Pour la production, il faut combiner signaux **upstream Envoy** et applicatifs, limiter les biais d'echantillonnage a faible trafic, inclure une metrique de disponibilite et etre rigoureux sur la fenetre d'observation, les timeouts et les conditions de rollback.

## Risques volontairement exclus

- Exposition TLS et politique d'authentification : HTTP sur localhost uniquement.
- Gestion declarative FluxCD du changement applicatif : aucun controller GitOps dans le lab.
- Admission policies, NetworkPolicy, supply chain, RBAC de production : hors perimetre.
- Reseau Cilium avec remplacement de kube-proxy, eBPF LB ou Hubble : non requis.
- HA Prometheus : une seule instance sans disque persistant, retention 3 h.