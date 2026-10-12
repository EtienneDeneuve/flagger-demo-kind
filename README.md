# Progressive Delivery Lab — Kind, Cilium, Envoy Gateway, Flagger

**Un TP de 60 minutes sur Mac, trois démonstrations, quatre slides Marp.**

Faire passer une nouvelle version de **0 à 50 % de trafic**, décider sur des métriques Prometheus, promouvoir si tout va bien, revenir à la version stable si une dégradation apparaît, puis cibler une beta avec un header HTTP.

La stack est volontairement réduite à **Kind + Cilium CNI + Envoy Gateway + Gateway API + Flagger + Prometheus + Podinfo**. Pas de service mesh supplémentaire. Les décisions de Flagger modifient un `HTTPRoute` Gateway API; les requêtes passent par Envoy Gateway.

> **Etat de validation :** scripts vérifiés syntaxiquement et manifests vérifiés comme YAML, mais **pas d'exécution Kubernetes de bout en bout dans l'environnement de préparation** (pas de Docker/Kind disponible). Faire un `make up` et un essai de chaque scénario sur un Mac avant d'animer le TP. Ne pas présenter cette archive comme déjà testée en production.

## Prérequis macOS

- Mac Apple Silicon ou Intel, Docker Desktop démarré ; recommander **8 Go de RAM alloués à Docker** et une connexion Internet pour le premier pull.
- Homebrew ; `kubectl`, `kind`, `helm`, `cilium` CLI et `curl`.
- `marp` uniquement pour générer les slides.

```bash
brew install kind kubectl helm cilium-cli marp-cli
make doctor
```

La configuration crée un cluster Kind distinct, nommé `flagger-platform-lab`, avec deux nœuds et **sans CNI Kind par défaut**. Cilium assure le réseau des pods ; kube-proxy est conservé pour simplifier le TP. Envoy Gateway déploie son proxy de données. Sur macOS, les IP `LoadBalancer` internes à Docker ne sont pas accessibles directement : un `port-forward` est utilisé.

## Installation

Depuis la racine de ce projet :

```bash
make up
```

Le script installe et attend successivement Cilium, Envoy Gateway, Prometheus, Flagger, Podinfo et la ressource Canary. Il utilise le chart OCI de Flagger avec `meshProvider=gatewayapi:v1`. Le `Gateway` écoute `Host: podinfo.local` en HTTP sur son port 80.

Ouvrir **trois terminaux** et laisser chacun tourner :

```bash
make port      # terminal 1 : Envoy Gateway sur localhost:8080
make traffic   # terminal 2 : requetes HTTP continues via Envoy
make status    # terminal 3 : phase, poids, routes et evenements
```

Vérification initiale :

```bash
curl -i -H 'Host: podinfo.local' http://127.0.0.1:8080/
kubectl -n flagger-demo get gateway,canary,httproute
kubectl -n flagger-demo get deploy,pods,svc
```

**Important :** il n'y a pas de `HTTPRoute` manuel. Flagger crée puis modifie `httproute/podinfo` et les services `podinfo-primary` / `podinfo-canary`.

## Exercices — 60 minutes

| Temps | Action | Résultat observable |
|---|---|---|
| 00–10 min | Architecture et `make doctor` / bootstrap préalable | Kind, Cilium, Gateway et contrôleurs prêts |
| 10–25 min | Démo 1 : promotion automatisée | `HTTPRoute` : poids canary 10 → 20 → 30 → 40 → 50 %, puis promotion |
| 25–40 min | Démo 2 : nouvelle version avec erreurs aléatoires HTTP | Flagger bloque, évalue puis revient à la version stable |
| 40–55 min | Démo 3 : A/B sur `x-canary: always` | Les requêtes du groupe beta ciblent la canary pendant l'analyse |
| 55–60 min | Débrief / nettoyage | Différence « Deployment mis à jour » vs « promotion autorisée » |

### Démo 1 — Promotion progressive

Dans un **quatrième terminal** :

```bash
make good
```

Le Deployment cible reçoit une nouvelle version de configuration visuelle. Flagger met en place une révision canary, augmente les poids du `HTTPRoute`, analyse le taux d'erreur 5xx issu de Prometheus, puis copie la version validée vers `podinfo-primary`.

Suivre :

```bash
kubectl -n flagger-demo describe canary/podinfo
kubectl -n flagger-demo get httproute/podinfo -o yaml
```

Attendre la phase `Succeeded` avant de commencer la démo suivante. Un passage successif par 10/20/30/40/50 % peut être trop rapide pour l'oeil ; `make status` tourne toutes les 3 secondes. À la fin, le trafic retourne à 100 % sur `podinfo-primary` qui exécute désormais la nouvelle version.

### Démo 2 — Rollback sur erreur HTTP

Garder `make traffic` actif, puis :

```bash
make fail
```

La modification active `--random-error=true` **uniquement sur la nouvelle version canary** (environ un tiers de réponses dégradées). Les probes Kubernetes sont volontairement tolérantes pour illustrer un rollback fondé sur la qualité du trafic, et non un crash immédiat. Le `MetricTemplate` `podinfo-canary-error-rate` calcule le taux de 5xx sur le **pod canary uniquement**, avec un seuil de 5 %. Après trois contrôles non conformes, la phase passe à `Failed` et Flagger retire le trafic canary.

```bash
kubectl -n flagger-demo describe canary/podinfo
kubectl -n flagger-demo get httproute/podinfo -o yaml
```

**À retenir :** le rollback est opérationnel ; il ne crée pas automatiquement un revert Git. En environnement GitOps, il faut réaligner la source déclarative pour éviter que la mauvaise révision revienne lors d'un futur reconcile.

### Démo 3 — A/B testing par header

Une fois le rollback terminé, démarrer **un second générateur** avec un header dédié :

```bash
make traffic-ab  # autre terminal : X-Canary: always
make ab          # modifie la strategie Canary puis lance V4 sans defaut
```

Pendant la phase `Progressing`, comparer les deux requêtes :

```bash
curl -s -H 'Host: podinfo.local' http://127.0.0.1:8080/
curl -s -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/
```

Avec A/B, il ne faut **pas** attendre des poids progressifs 10→50 : Flagger crée une règle ciblée pour le header, et la promotion intervient après le nombre d'itérations configuré. Le routage sélectif vaut **pendant l'analyse**, pas après promotion (la nouvelle version devient la primary pour tous).

## Prometheus et métrique de décision

Dans un autre terminal :

```bash
make metrics
```

Interface : http://localhost:9090/graph ; requêtes PromQL utiles :

```promql
sum(rate(http_requests_total{job="podinfo-canary"}[1m]))
```

```promql
100 * (sum(rate(http_requests_total{job="podinfo-canary",status=~"5.."}[1m])) or vector(0)) / clamp_min(sum(rate(http_requests_total{job="podinfo-canary"}[1m])), 0.001)
```

Le Prometheus minimal ne scrappe **que les pods cibles de la version canary** (étiquette `app=podinfo`, port nommé `http-metrics`). Cela permet d'illustrer un signal applicatif. Pour un environnement réel, prévoir des SLIs **vus depuis Envoy**, de la disponibilité de bout en bout, une période de mesure plus longue et la qualité du trafic avant d'automatiser des rollbacks.

## Présentation Marp

Fichier source : [`slides/flagger-tp.marp.md`](slides/flagger-tp.marp.md). Quatre slides éditables en Markdown.

```bash
make slides
marp slides/flagger-tp.marp.md --pdf --output slides/flagger-tp.pdf
```

## Structure

```text
.
├── kind/cluster.yaml            # 2 noeuds; pas de CNI Kind
├── manifests/                  # Gateway, Podinfo, Prometheus, MetricTemplate, Canary, A/B
├── scripts/                    # Bootstrap, trafic, scenarios, monitoring, cleanup
├── slides/flagger-tp.marp.md    # 4 slides
├── docs/                       # Guide formateur, architecture, diagnostic, public checklist
├── versions.env                # Composants epingles
├── Makefile
└── README.md
```

## Nettoyage

```bash
make cleanup   # supprime uniquement le cluster kind "flagger-platform-lab"
```

## Références / crédits

- [Flagger — progressive delivery via Gateway API](https://docs.flagger.app/tutorials/gatewayapi-progressive-delivery)
- [Flagger — MetricTemplate](https://docs.flagger.app/usage/metrics)
- [Gateway API HTTPRoute](https://gateway-api.sigs.k8s.io/guides/user-guides/http-routing/)
- [Envoy Gateway, installation Helm](https://gateway.envoyproxy.io/v1.7/install/install-helm/)
- [Cilium, installation sur Kind](https://docs.cilium.io/en/stable/installation/kind/)
- [Podinfo](https://github.com/stefanprodan/podinfo)
- [k8ssecurity/k8s_gateway_api_tutorial](https://github.com/k8ssecurity/k8s_gateway_api_tutorial) (projet existant étudié comme référence, **non inclus** ni forké)

Ce lab est un environnement d'enseignement, pas un template pour un cluster exposé en production.