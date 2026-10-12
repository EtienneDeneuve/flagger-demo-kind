# Fiche animateur — 60 minutes

## Objectif à dire à l'oral (60 secondes)

« Kubernetes sait remplacer des pods, mais ne sait pas décider seul si une version mérite 100 % du trafic. Flagger observe le Deployment, pilote les poids d'un HTTPRoute via Envoy Gateway et vérifie un SLI Prometheus. Le test de ce soir porte sur la décision, pas sur le YAML. »

## Préparation impérative avant l'atelier

**Ne pas compter sur l'installation à froid en séance.** Cilium, Envoy Gateway et les images de Kind prennent un temps dépendant du Mac et du réseau. Le formateur doit avoir exécuté `./setup.sh --yes`, `make port`, `make traffic`, puis les trois expériences sur sa machine. Les participants peuvent lancer `./setup.sh --yes` en amont ou travailler par binôme sur un cluster précréé. Le planning ci-dessous suppose cette préinstallation ; autrement le TP risque de dépasser 60 minutes.

Faire un essai à blanc et relever :

- `./lab kubectl -n flagger-demo get canary/podinfo` = `Succeeded` initialement
- `./lab kubectl -n flagger-demo get httproute/podinfo` retourne une route acceptée
- `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/` fonctionne via Envoy
- `make metrics` : après démarrage de la canary et d'un flux HTTP, le compteur 5xx est disponible
- Promotion complète en moins de ~6 minutes, rollback en quelques cycles, A/B par header

## Fil narratif

**0–10 — Le piège du rolling update.** Faire expliquer pourquoi `Ready` ne garantit ni latence ni 5xx. Montrer la slide 2 : Cilium s'occupe du réseau, Envoy du routage, Flagger de la stratégie et Prometheus du verdict.

**10–25 — Gagner la confiance progressivement.** Montrer la primary en vert / message « VERSION STABLE ». Lancer `make good`. Laisser tourner le trafic et `make status`. Faire lire les backendRefs de la route Flagger. Attendre la promotion de V2. Question de contrôle : « qu'est-ce qui a changé dans le HTTPRoute, et qui l'a changé ? »

**25–40 — Se protéger d'une version qui démarre bien mais répond mal.** Lancer `make fail`, conserver le trafic. Regarder le signal applicatif dans Prometheus puis les événements `Halt` et `Rolling back`. Insister sur la différence entre rollback runtime et revert Git.

**40–55 — Tester une nouvelle version sur un groupe choisi.** Démarrer `make traffic-ab`, puis `make ab`. Comparer les flux avec/sans header pendant `Progressing`. Expliquer que ce routage ciblé ne survit pas à la promotion.

**55–60 — Questions, limites et nettoyage.** Recentrer sur Flagger = boucle de contrôle. Dire explicitement que ce lab n'intègre ni alerting, ni GitOps, ni métriques Envoy de bout en bout, ni policies de sécurité. Montrer `make cleanup`.

## Gestion du temps / secours

- Si la canary met du temps à démarrer : vérifier les pods puis l'image Podinfo.
- Si une métrique est vide : le script de trafic ne tourne peut-être pas, la canary n'est peut-être pas encore routée, le port Prometheus 9797 ou les étiquettes de pod ne correspondent pas. Cf. docs/02-diagnostic.md.
- Si le Mac ne peut pas lancer Kind : utiliser le Mac du formateur pour la démo. Ne pas improviser un nouveau CNI/mesh au milieu de la séance.
- Ne jamais provoquer la panne sur la primary. Faire l'injection via le Deployment surveillé, que Flagger traite comme canary.

## Message final

« On ne remplace pas le processus de livraison par Flagger : on automatise un contrôle de qualité à l'endroit où le trafic rencontre une nouvelle version. »