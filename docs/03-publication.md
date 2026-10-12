# Publication du dépôt

Le projet a été conçu pour devenir public : pas de configuration AKS, pas de noms de clients, pas de domaines internes, pas de secrets. Vérifier le diff final, les captures d'écran ajoutées et l'historique de commits avant de changer la visibilité.

## Dépôt créé (privé)

Le dépôt de travail est [EtienneDeneuve/flagger-demo-kind](https://github.com/EtienneDeneuve/flagger-demo-kind), créé privé le 12 octobre 2026.

Pour le cloner :

```bash
gh repo clone EtienneDeneuve/flagger-demo-kind
cd flagger-demo-kind
```

## Passer public ultérieurement (action volontaire)

Sur GitHub : **Settings > General > Danger Zone > Change repository visibility > Public**, après avoir revu les fichiers et l'historique. Ne pas automatiser ce changement de visibilité dans un script ou une GitHub Action.

## À contrôler avant publication

- [ ] Secrets et tokens absents de l'historique Git.
- [ ] Aucun cluster, abonnement, tenant, email ou domaine de client.
- [ ] Tous les scripts fonctionnent sur un Mac de test avec les versions épinglées.
- [ ] Slides relues et rendues (`make slides`).
- [ ] Sources officielles et licences correctement créditées.
- [ ] Le README conserve l'avertissement « lab pédagogique ».