# Vérification devenv + Rancher Desktop (Moby)

Compte rendu du 13 octobre 2026 sur le Mac formateur (Apple Silicon).

> **Participants sans Nix :** utiliser `bash scripts/verify-local-demo.sh` (ou `./setup.sh --mode=local`).  
> devenv est un confort formateur ; le contrat lab (`.tools/bin` + KUBECONFIG privé) est identique.

## Contexte machine

| Élément | État observé |
|---|---|
| `devenv` | 2.4.0 (`aarch64-darwin`), présent |
| `devenv.nix` / lock | OK — packages `zsh`, `jq`, `curl`, `git` ; CLI K8s toujours via `.tools/bin` |
| Profil devenv préconstruit | OK — `.devenv/profile/bin/{jq,zsh,curl,git}` |
| Moteur conteneurs | **Rancher Desktop**, engine **Moby**, 16 Go RAM VM, `pathManagementStrategy: manual` |
| CLI Docker | `~/.rd/bin/docker` (hors PATH par défaut) |
| Cluster Kind lab | Non exécuté de bout en bout depuis l’agent Cursor (sandbox bloque `docker.sock` et le daemon Nix) |

## Correctifs appliqués pendant la vérif

1. **Découverte Rancher / OrbStack** — `ensure_docker_cli` dans `scripts/_common.sh` ajoute `~/.rd/bin` (et chemins Docker Desktop / OrbStack) si `docker` n’est pas dans le PATH. Utilisé par `setup.sh`, `bootstrap.sh`, `doctor.sh`.
2. **`doctor`** — affiche le chemin réel de chaque binaire et signale si `kubectl`/`helm`/`kind`/`cilium` ne viennent pas de `.tools/bin` (piège Rancher qui ship aussi `kubectl`/`helm` dans `~/.rd/bin`).
3. **Prompt Rancher** — si le moteur est arrêté et `rdctl` est présent, `setup.sh` propose `rdctl start --container-engine.name=moby`.

## Checklist à jouer dans un terminal local (hors agent)

Le sandbox Cursor ne peut pas joindre `unix://$HOME/.rd/docker.sock` ni `/nix/var/nix/daemon-socket/socket`. Lancer **dans Terminal / iTerm** :

```bash
cd /Users/etiennedeneuve/Developer/omnivya/flagger-demo-kind
export PATH="$HOME/.rd/bin:$PATH"

# 1. Moby joignable
docker info

# 2. Shell devenv (PATH .tools + KUBECONFIG privé)
devenv shell
# message attendu : Flagger lab | devenv | private KUBECONFIG | ...

# 3. Outils épinglés + cluster
./setup.sh --yes --mode=devenv --no-shell
make doctor

# 4. Smoke des 3 démos
bash scripts/ci-smoke.sh
```

Ou d’un coup : `bash scripts/verify-devenv-demo.sh` (écrit `.tools/verify-devenv-demo.log`).

### Critères de succès

- [ ] `docker info` → Server Version Rancher/Moby
- [ ] `devenv shell` → `jq` Nix + `.tools/bin` en tête de PATH + `KUBECONFIG=.../.tools/kubeconfig`
- [ ] `make doctor` → `kind`/`kubectl`/`helm`/`cilium` sous `.tools/bin`, cluster `flagger-platform-lab`
- [ ] `ci-smoke.sh` → PASS (promotion, rollback métrique, A/B header)
- [ ] Navigateur : `make port` puis `make browser` → UI HTML sur http://127.0.0.1:18080/ (Host `podinfo.local` injecté ; `:8080` sans Host = 404)

## Points d’attention formateur

- Avec Rancher en **manual PATH**, sans le correctif `ensure_docker_cli`, un shell « nu » ne voit pas `docker` → faux négatif « Docker CLI not found ».
- Ne pas laisser `doctor` passer sur le `kubectl` Rancher : les versions lab sont celles de `versions.env` / `.tools/bin`.
- Kubernetes Rancher intégré : **désactivé recommandé** pour ce TP (Kind porte le cluster). Engine = Moby uniquement.
- Prévoir l’essai à blanc ci-dessus **avant** la séance ; la CI YAML/Bash ne remplace pas ce passage.
