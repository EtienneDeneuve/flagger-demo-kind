# Flagger Demo Kind — progressive delivery avec Cilium et Envoy Gateway

**Français** · **[English](README.en.md)**

**TP macOS de 60 minutes · 4 slides Marp · YAML à appliquer (pas seulement `make`).**

Page projet (site) : [etienne.deneuve.xyz/projects/flagger-demo-kind](https://etienne.deneuve.xyz/projects/flagger-demo-kind/) (après ouverture publique).

Kubernetes sait effectuer un rolling update. Flagger décide si une nouvelle version **mérite de recevoir davantage de trafic**, en analysant des métriques Prometheus et en modifiant les poids d'un HTTPRoute Gateway API. Le trafic est servi par Envoy Gateway ; Cilium est l'unique CNI. **Aucun Istio, aucun service mesh supplémentaire.**

## Démarrage : cloner, un script, terminé

Prérequis externes : **macOS Apple Silicon ou Intel**, `git`, `curl`, un moteur de conteneurs compatible Docker (Docker Desktop, OrbStack, **Rancher Desktop en mode Moby**, ou Colima) **déjà installé et démarré**, environ **8 Go de RAM alloués** (12 Go recommandés) et un accès Internet pour les images. Avec Rancher, laisser Kubernetes intégré désactivé (Kind porte le cluster) et s’assurer que `docker` répond (`~/.rd/bin` est ajouté automatiquement si le PATH est en mode manual).

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
├── lab                  # kubectl/helm protégés par kubeconfig privé
├── .tools/bin/           # versions CLI locales (ignoré par Git)
├── .tools/kubeconfig     # accès au seul cluster Kind du TP
├── .tools/helm/          # données Helm isolées
├── devenv.nix / .yaml   # option Nix personnelle
├── Brewfile              # option Docker Desktop, explicite
├── Brewfile.colima       # alternative Colima, explicite
├── kind/                 # Kind sans CNI d'origine
├── manifests/            # Gateway, Podinfo, métriques, Canary
├── manifests/tp/         # YAML TP à patch/apply soi-même (anti-magique)
├── scripts/              # raccourcis make (= mêmes fichiers tp/)
├── docs/                 # formateur, participant, diagnostic
└── slides/               # quatre slides Marp
```


### Sans Nix

`./setup.sh` sélectionne automatiquement `zsh -f` s'il n'y a pas de `devenv`. Le shell n'édite aucun profil utilisateur. Pour l'ouvrir plus tard :

```bash
./scripts/shell.sh
```

Les commandes `make ...` fonctionnent **aussi depuis un terminal normal** : chacune charge les chemins et la configuration privés du dépôt. Pour une commande `kubectl` isolée depuis n'importe quel terminal, utiliser **`./lab kubectl ...`**. Le wrapper refuse d'agir si le contexte attendu n'est pas celui du TP.

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
make browser   # UI podinfo dans le navigateur (proxy Host: podinfo.local → :18080)
```

Sans `make browser` : `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/` (un `http://127.0.0.1:8080/` nu renvoie **404** — la HTTPRoute matche le hostname). Alternative : `127.0.0.1 podinfo.local` dans `/etc/hosts`, puis http://podinfo.local:8080/.

Scénarios **recommandés** (fichiers lus + appliqués) — détail : [docs/05-tp-participant.md](docs/05-tp-participant.md) :

```bash
# 1. Promotion : patch Deployment → Flagger avance les poids
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/01-promote-v2.patch.yaml

# 2. Rollback : patch V3 + fault injection sur svc/podinfo-canary (voir le guide)

# 3. A/B : apply Canary (match header) puis patch V4
./lab kubectl apply -f manifests/tp/03-ab-canary.yaml
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/03-revision-v4.patch.yaml
```

Raccourcis équivalents (même YAML) : `make good` · `make fail` · `make traffic-ab` + `make ab`.

Visualisation technique :

```bash
make metrics
./lab kubectl -n flagger-demo describe canary/podinfo
./lab kubectl -n flagger-demo get httproute/podinfo -o yaml
curl -H 'Host: podinfo.local' http://127.0.0.1:8080/
```

Le namespace est `flagger-demo`. Le cluster s'appelle `flagger-platform-lab`. Flagger crée et possède la `HTTPRoute` : **ne pas déployer une HTTPRoute manuelle concurrente**.

### Déroulé de l'heure

Guide à suivre **participant** : [docs/05-tp-participant.md](docs/05-tp-participant.md) (exercices + questions).  
Fiche **animateur** : [docs/00-formateur.md](docs/00-formateur.md).

| Minute | Qui | Contenu |
|---|---|---|
| 00–10 | binôme | Architecture + TP 0 (lire Canary / HTTPRoute) |
| 10–25 | binôme | TP 1 — `make good` (promotion par poids) |
| 25–40 | binôme | TP 2 — `make fail` (rollback 5xx) |
| 40–55 | binôme | TP 3 — `make ab` (cohorte header) |
| 55–60 | plénière | Limites lab, GitOps / prod, cleanup |

Prévoir **l'installation initiale en amont** : téléchargement des images Kind, Cilium et Envoy Gateway peut dépasser le temps disponible en séance. Les scénarios eux-mêmes sont les 60 minutes de TP.

Pour revenir à zéro :

```bash
make cleanup  # supprime uniquement le cluster Kind flagger-platform-lab
```

## Slides, documentation et limites

- [4 slides Marp](slides/flagger-tp.marp.md) — source éditable Markdown.
- [**TP participant**](docs/05-tp-participant.md) · [English](docs/en/05-tp-participant.md).
- [Déroulé animateur](docs/00-formateur.md).
- [Architecture](docs/01-architecture.md) · [English](docs/en/01-architecture.md).
- [Diagnostic](docs/02-diagnostic.md) · [English](docs/en/02-diagnostic.md).
- [Checklist ouverture publique](docs/03-publication.md).
- [Vérification devenv + Rancher Moby](docs/04-verification-devenv.md).
- [Contributing](CONTRIBUTING.md).

Marp n'est pas nécessaire pour **exécuter** le lab. Pour exporter les slides, installer Marp CLI séparément ou utiliser l'extension Marp de VS Code.

**Niveau de vérification :** la CI vérifie Bash et YAML. Le cluster complet n'a **pas encore été exécuté de bout en bout sur un Mac de participant** ; un essai à blanc est obligatoire avant la séance. Le repo est un support pédagogique, pas un template production. Les outils locaux sont limités au dossier du dépôt ; l'exécution de Kind créera en revanche les conteneurs Docker nommés du lab.

Sources : [Kind](https://kind.sigs.k8s.io/), [Cilium](https://docs.cilium.io/en/stable/), [Envoy Gateway](https://gateway.envoyproxy.io/), [Flagger Gateway API](https://docs.flagger.app/tutorials/gatewayapi-progressive-delivery), [Podinfo](https://github.com/stefanprodan/podinfo), [devenv](https://devenv.sh/).
