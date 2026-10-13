# Fiche animateur — 60 minutes

Guide participant (FR) : [05-tp-participant.md](05-tp-participant.md) · (EN) : [en/05-tp-participant.md](en/05-tp-participant.md).  
Ouverture publique : [03-publication.md](03-publication.md).

## Objectif à dire à l'oral (60 secondes)

« Kubernetes sait remplacer des pods, mais ne sait pas décider seul si une version mérite 100 % du trafic. Flagger observe le Deployment, pilote les poids d'un HTTPRoute via Envoy Gateway et vérifie un SLI Prometheus. Le test de ce soir porte sur la décision, pas sur le YAML. »

## Préparation impérative avant l'atelier

**Ne pas compter sur l'installation à froid en séance.** Cilium, Envoy Gateway et les images de Kind prennent un temps dépendant du Mac et du réseau. Le formateur doit avoir exécuté `./setup.sh --yes`, `make port`, `make traffic`, puis les trois expériences sur sa machine. Les participants peuvent lancer `./setup.sh --yes` en amont ou travailler par binôme sur un cluster précréé. Le planning ci-dessous suppose cette préinstallation ; autrement le TP risque de dépasser 60 minutes.

Faire un essai à blanc et relever :

- `./lab kubectl -n flagger-demo get canary/podinfo` = `Succeeded` initialement
- `./lab kubectl -n flagger-demo get httproute/podinfo` retourne une route acceptée
- `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/` fonctionne via Envoy
- `make metrics` : après démarrage de la canary et d'un flux HTTP, le compteur 5xx est disponible
- Promotion complète en ~30–60s (intervalle 10s, steps 25→50), rollback en ~20s, A/B par header

Si le Mac formateur utilise **Rancher Desktop (Moby)** + **devenv**, suivre aussi [docs/04-verification-devenv.md](04-verification-devenv.md) (`docker info`, `devenv shell`, `./setup.sh --yes --mode=devenv --no-shell`, `scripts/ci-smoke.sh`).

## Support participant

Exercices : [05-tp-participant.md](05-tp-participant.md) + fichiers sous [manifests/tp/](../manifests/tp/).  
**Leviers principaux :** `kubectl patch --patch-file` / `kubectl apply -f` — pas `make good|fail|ab` en premier.  
Les `make *` restent un filet (même YAML) si un binôme est perdu ou pour ta démo de secours.

## Fil narratif

**0–10 — Piège rolling update + TP 0.** Ready ≠ digne du trafic. Slide 2. Ils ouvrent `05-canary.yaml` **et** `tp/01-promote-v2.patch.yaml` (qu’est-ce qui change dans le hash ?).

**10–25 — TP 1.** Ils patchent `01-promote-v2.patch.yaml` eux-mêmes. Status + `backendRefs`. Question : qui a écrit la HTTPRoute ?

**25–40 — TP 2.** Deux gestes visibles : patch `02-degraded-v3` puis `curl …/fault_injection/enable` sur le Service canary. Halt / Failed. Rollback ≠ git revert. **Pause ~15 s** avant TP 3.

**40–55 — TP 3.** `apply 03-ab-canary.yaml` puis patch `03-revision-v4`. Split header/public. Insister : un fichier = stratégie Canary, l’autre = révision app.

**55–60 — Limites + cleanup.** Flagger = boucle de contrôle. Pas d’alerting / GitOps / Envoy E2E / policies sécu.

## Gestion du temps / secours

- Si la canary met du temps à démarrer : vérifier les pods puis l'image Podinfo.
- Si une métrique est vide : le script de trafic ne tourne peut-être pas, la canary n'est peut-être pas encore routée, le port Prometheus 9797 ou les étiquettes de pod ne correspondent pas. Cf. docs/02-diagnostic.md.
- Si le Mac ne peut pas lancer Kind : utiliser le Mac du formateur pour la démo. Ne pas improviser un nouveau CNI/mesh au milieu de la séance.
- Ne jamais provoquer la panne sur la primary. Faire l'injection via le Deployment surveillé, que Flagger traite comme canary.

## Message final

« On ne remplace pas le processus de livraison par Flagger : on automatise un contrôle de qualité à l'endroit où le trafic rencontre une nouvelle version. »