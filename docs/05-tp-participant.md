# TP participant — progressive delivery avec Flagger

Tu manipules le cluster **avec des fichiers de conf**, pas seulement des raccourcis `make`.
Les `make good|fail|ab` existent encore (même YAML en coulisse) — en séance, **ouvre et applique** les fichiers sous `manifests/tp/`.

Prévoir **~50 minutes** une fois le lab installé (`./setup.sh` en amont).

## Idée centrale

```text
1. Tu changes le Deployment target (patch YAML)     → nouvelle révision
2. Flagger détecte le hash du pod template
3. Flagger modifie la HTTPRoute (poids ou match)     → tu n’y touches PAS
4. Prometheus + MetricTemplate                       → verdict promote / rollback
```

## Préparation (une fois)

| Terminal | Commande | Rôle |
|---|---|---|
| 1 | `make port` | Tunnel Envoy → `:8080` |
| 2 | `make traffic` | Charge HTTP — **laisser tourner** |
| 3 | `make status` | Phase / poids / events |

```bash
curl -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/ | head
./lab kubectl -n flagger-demo get canary/podinfo
```

> Sans `Host: podinfo.local` → **404**. Ne crée pas de `HTTPRoute` manuelle.

Index des fichiers : [manifests/tp/README.md](../manifests/tp/README.md).

---

## TP 0 — Lire avant d’agir (5 min)

1. Ouvre `manifests/05-canary.yaml` : `interval`, `stepWeight`, `maxWeight`, `thresholdRange.max`.
2. Ouvre `manifests/tp/01-promote-v2.patch.yaml` : qu’est-ce qui change dans le pod template ?
3. Regarde l’état :

```bash
./lab kubectl -n flagger-demo get deploy podinfo,podinfo-primary -o wide
./lab kubectl -n flagger-demo get httproute podinfo -o yaml | less
```

**À noter :** qui écrit les poids de la HTTPRoute ? Que mesure `04-metrics.yaml` ?

---

## TP 1 — Promotion progressive (conf à patcher)

**Fichier :** `manifests/tp/01-promote-v2.patch.yaml`

1. Lis le fichier (message UI + annotation `flagger-lab/revision`).
2. Applique-le :

```bash
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/01-promote-v2.patch.yaml
```

3. Observe 30–60 s : trafic (`.`), `make status` (poids 25→50 → Succeeded), UI **V2 VALIDEE**.

```bash
./lab kubectl -n flagger-demo get canary/podinfo
curl -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/api/info
```

**Questions :** quand `podinfo-primary` reçoit V2 ? Après Succeeded, où va le trafic public ?

**Réussite :** phase `Succeeded`, primary = `FLAGGER LAB | V2 VALIDEE`.

> Relancer le **même** patch sans changer `flagger-lab/revision` peut ne rien faire (hash identique). Bumpe l’annotation (`v2-b`) si besoin.

---

## TP 2 — Rollback 5xx (patch + faute explicite)

**Fichier :** `manifests/tp/02-degraded-v3.patch.yaml`

Ici le concept est en **deux couches** (volontairement pas magique) :

| Étape | Quoi | Pourquoi |
|---|---|---|
| A | Patch Deployment V3 | Flagger démarre une canary **Ready** |
| B | `POST …/fault_injection/enable` sur le Service **canary** | 5xx HTTP sans casser `/readyz` |

1. Remets le Canary en mode poids (au cas où) :

```bash
./lab kubectl apply -f manifests/05-canary.yaml
```

2. Demande V3 :

```bash
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/02-degraded-v3.patch.yaml
```

3. Attends `Progressing` + endpoints canary (`make status`).

4. Dans un **autre** terminal, active la panne **uniquement sur la canary** :

```bash
./lab kubectl -n flagger-demo port-forward svc/podinfo-canary 19898:9898
# autre shell :
curl -sS -X POST http://127.0.0.1:19898/fault_injection/enable
```

5. Observe `x` dans le trafic, events `Halt … error-rate > 5`, phase `Failed`, primary encore V2.

```bash
./lab kubectl -n flagger-demo describe canary/podinfo | tail -40
```

**Questions :** pourquoi `/readyz` OK + 5xx utilisateurs ? Rollback Flagger vs `git revert` ?

**Réussite :** `Failed`, primary V2, HTTP public 200.

> **Pause ~15 s** avant le TP 3 (fenêtre Prometheus `rate([{{ interval }}])`).

---

## TP 3 — A/B : apply Canary + patch révision

Deux fichiers, deux concepts :

1. **Stratégie de routage** (objet Canary) — `manifests/tp/03-ab-canary.yaml`
2. **Nouvelle version** (Deployment) — `manifests/tp/03-revision-v4.patch.yaml`

```bash
# Terminal charge cohorte (header) :
make traffic-ab

# Stratégie A/B :
./lab kubectl apply -f manifests/tp/03-ab-canary.yaml

# Révision V4 :
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/03-revision-v4.patch.yaml
```

Pendant `Progressing` :

```bash
curl -sS -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/api/info   # → V4
curl -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/api/info                         # → V2
```

Repère dans le YAML : `match.headers` et `iterations` (plus de `stepWeight`).

**Questions :** que devient le match après promotion ? Pourquoi `iterations` plutôt que des poids ?

**Réussite :** split header/public pendant Progressing ; puis primary = **V4 BETA**.

---

## Raccourcis (optionnels)

| Make | Équivalent TP |
|---|---|
| `make good` | patch `01-promote-v2.patch.yaml` |
| `make fail` | apply `05-canary` + patch `02-…` + fault curl |
| `make ab` | apply `03-ab-canary.yaml` + patch `03-revision-v4` |

---

## Défi optionnel

Change `thresholdRange.max` dans `manifests/05-canary.yaml` (ex. `5` → `1`),  
`./lab kubectl apply -f manifests/05-canary.yaml`, discute les faux positifs, puis `git checkout -- manifests/05-canary.yaml` + ré-apply.

---

## Hors périmètre

GitOps, alerting, TLS, NetworkPolicy, métriques Envoy E2E, Istio.

**À retenir :** tu déclenches une révision (YAML) ; Flagger décide du trafic (HTTPRoute + métriques).

## Aide

- [02-diagnostic.md](02-diagnostic.md) · [01-architecture.md](01-architecture.md) · [00-formateur.md](00-formateur.md)
