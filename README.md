# Flagger Demo Kind — progressive delivery avec Cilium et Envoy Gateway

**TP macOS de 60 minutes · 4 slides Marp · 3 démonstrations.**

Kubernetes sait effectuer un rolling update. Flagger décide si une nouvelle version **mérite de recevoir davantage de trafic**, en analysant des métriques Prometheus et en modifiant les poids d'un HTTPRoute Gateway API. Le trafic est servi par Envoy Gateway ; Cilium est l'unique CNI. **Aucun Istio, aucun service mesh supplémentaire.**

## Démarrage : cloner, un script, terminé

Prérequis externes : **macOS Apple Silicon ou Intel**, `git`, `curl`, un moteur de conteneurs compatible Docker (Docker Desktop, OrbStack ou Colima) **déjà installé et démarré**, environ **8 Go de RAM alloués** (12 Go recommandés) et un accès Internet pour les images.

```bash
git clone https://github.com/EtienneDeneuve/flagger-demo-kind.git
cd flagger-demo-kind
./setup.sh
```

Le script pose **3 questions**, avec des valeurs par défaut pertinentes :

1. **Shell** : `auto` (utilise ton `devenv` existant, sinon un zsh isolé).
2. **Créer le cluster Kind ?** Oui.
3. **Ouvrir le shell du lab ?** Oui.

Un moteur Docker arrêté ou absent est détecté. Le script ne l'installe **pas** silencieusement.

### Zéro mise à jour globale

Le setup installe **systématiquement les versions épinglées** de `kind`, `kubectl`, `helm` et `cilium` dans `.tools/bin/`, même si des versions sont déjà installées globalement. Téléchargements officiels, empreintes **SHA-256 vérifiées**, cache local. Aucun `brew upgrade`, aucun `sudo`, aucune écriture dans `~/.zshrc` ou `~/.kube/config`.

```text
flagger-demo-kind/
├── setup.sh             # 3 prompts ; installation outils et cluster
├── .tools/bin/           # versions CLI locales (ignoré par Git)
├── .tools/kubeconfig     # accès au seul cluster Kind du TP
├── .tools/helm/          # données Helm isolées
├── devenv.nix / .yaml   # option Nix personnelle
├── Brewfile              # option Docker Desktop, explicite
├── Brewfile.colima       # alternative Colima, explicite
├── kind/                 # Kind sans CNI d'origine
├── manifests/            # Gateway API, Flagger, Podinfo, métriques
├── scripts/              # commandes de manipulation du TP
├── docs/                 # guide formateur, diagnostic, publication
└── slides/               # quatre slides Marp
```

### Sans Nix

`./setup.sh` sélectionne automatiquement `zsh -f` s'il n'y a pas de `devenv`. Le shell n'édite aucun profil utilisateur. Pour l'ouvrir plus tard :

```bash
./scripts/shell.sh
```

Les commandes `make ...` fonctionnent **aussi depuis un terminal normal** : chacune charge les chemins et la configuration privés du dépôt.

### Avec devenv (facultatif)

Si `devenv` est déjà présent, `./setup.sh` entre dans `devenv shell` après installation. `devenv.yaml` épingle un commit nixpkgs ; `devenv.nix` ajoute `zsh`, `jq`, `curl`, `git`. **Les CLI Kubernetes proviennent toujours de `.tools/bin`** pour garantir la même expérience dans les deux modes. Nix n'est ni installé ni mis à jour pour les participants.

```bash
./setup.sh --mode=devenv      # utilise devenv s'il existe
./setup.sh --mode=local       # force le zsh isolé, même avec Nix
./setup.sh --tools-only      # prépare les CLI sans créer le cluster
./setup.sh --yes             # mode automatisé, sans shell interactif
./setup.sh --help
```

### Option Brew (sur demande seulement)

`Brewfile` n'installe que le moteur Docker Desktop ; `Brewfile.colima` installe Docker CLI + Colima. Aucun n'est exécuté par `setup.sh`. Le choix est volontaire, afin de ne pas toucher aux versions Homebrew des participants.

```bash
brew bundle --file=Brewfile          # option Docker Desktop
brew bundle --file=Brewfile.colima   # option Docker + Colima
colima start                          # uniquement si Colima a été choisi
```

## Versions récentes épinglées

| Composant | Version |
|---|---|
| Kubernetes dans Kind | **1.36.4** (image officielle multiarch épinglée par digest) |
| Kind CLI | **0.33.0** |
| kubectl local | **1.36.4** |
| Helm CLI | **3.22.0** |
| Cilium CLI | **0.20.1** |
| Cilium CNI | **1.20.2** |
| Envoy Gateway | **1.9.2** |
| Flagger | **1.45.0** |
| Podinfo | **6.15.0** |
| Prometheus | **3.15.0** |

Kubernetes **1.36.4** remplace 1.36.3 car l'image Kind officielle, reproductible et précompilée du cycle 0.33.0 est publiée pour **1.36.4**, pas pour 1.36.3. Voir [les releases Kind](https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0). Pas de version `latest` flottante.

## Démarrer les démonstrations

Sur le cluster installé, dans **trois terminaux distincts** :

```bash
make port      # terminal 1 : Envoy Gateway sur localhost:8080
make traffic   # terminal 2 : appels HTTP continus vers Envoy
make status    # terminal 3 : phase Flagger, poids Gateway API, événements
```

Ouvrir d'autres terminaux pour les scénarios :

```bash
make good       # 1. Promotion progressive : 10 → 20 → 30 → 40 → 50 %, puis 100 %
make fail       # 2. Version dégradée : erreurs HTTP 5xx, rollback automatique
make traffic-ab # Trafic header x-canary: always (pendant le scénario A/B)
make ab         # 3. Routage de la cohorte pilote uniquement
```

Visualisation technique :

```bash
make metrics
kubectl -n flagger-demo describe canary/podinfo
kubectl -n flagger-demo get httproute/podinfo -o yaml
curl -H 'Host: podinfo.local' http://127.0.0.1:8080/
```

Le namespace est `flagger-demo`. Le cluster s'appelle `flagger-platform-lab`. Flagger crée et possède la `HTTPRoute` : **ne pas déployer une HTTPRoute manuelle concurrente**.

### Déroulé de l'heure

| Minute | Démonstration |
|---|---|
| 00–10 | Architecture, rôles de Cilium / Envoy / Flagger |
| 10–25 | Promotion par poids HTTPRoute |
| 25–40 | Rollback sur signal applicatif, pas sur readiness |
| 40–55 | A/B ciblé sur un header |
| 55–60 | Discussion métriques / GitOps / production |

Prévoir **l'installation initiale en amont** : téléchargement des images Kind, Cilium et Envoy Gateway peut dépasser le temps disponible en séance. Les scénarios eux-mêmes sont les 60 minutes de TP.

Pour revenir à zéro :

```bash
make cleanup  # supprime uniquement le cluster Kind flagger-platform-lab
```

## Slides, documentation et limites

- [4 slides Marp](slides/flagger-tp.marp.md) — source éditable Markdown.
- [Déroulé animateur](docs/00-formateur.md).
- [Architecture](docs/01-architecture.md).
- [Diagnostic](docs/02-diagnostic.md).
- [Checklist avant publication publique](docs/03-publication.md).

Marp n'est pas nécessaire pour **exécuter** le lab. Pour exporter les slides, installer Marp CLI séparément ou utiliser l'extension Marp de VS Code.

**Niveau de vérification :** la CI vérifie Bash et YAML. Le cluster complet n'a **pas encore été exécuté de bout en bout sur un Mac de participant** ; un essai à blanc est obligatoire avant la séance. Le repo est un support pédagogique, pas un template production. Les outils locaux sont limités au dossier du dépôt ; l'exécution de Kind créera en revanche les conteneurs Docker nommés du lab.

Sources : [Kind](https://kind.sigs.k8s.io/), [Cilium](https://docs.cilium.io/en/stable/), [Envoy Gateway](https://gateway.envoyproxy.io/), [Flagger Gateway API](https://docs.flagger.app/tutorials/gatewayapi-progressive-delivery), [Podinfo](https://github.com/stefanprodan/podinfo), [devenv](https://devenv.sh/).
