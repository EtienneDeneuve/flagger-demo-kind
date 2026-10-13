# Manifests TP (à appliquer toi-même)

Les commandes `make good|fail|ab` appellent les **mêmes fichiers**. Lis le YAML, puis :

| Fichier | Commande | Concept |
|---|---|---|
| `01-promote-v2.patch.yaml` | `kubectl patch … --patch-file` | Nouvelle révision → canary par **poids** |
| `02-degraded-v3.patch.yaml` | idem + curl fault injection | Ready ≠ digne du trafic |
| `03-ab-canary.yaml` | `kubectl apply -f` | Canary en mode **match header** |
| `03-revision-v4.patch.yaml` | `kubectl patch …` | Version vue seulement par la cohorte |

Guide pas à pas : [docs/05-tp-participant.md](../../docs/05-tp-participant.md).
