# Ouverture publique — checklist

Le lab est conçu pour être public : pas d’AKS client, pas de secrets, kubeconfig isolé sous `.tools/`.  
**Ne pas automatiser** le passage public (Settings GitHub uniquement).

Dépôt : [EtienneDeneuve/flagger-demo-kind](https://github.com/EtienneDeneuve/flagger-demo-kind)

## Avant de changer la visibilité

### Contenu & hygiène

- [ ] Historique Git sans tokens / kubeconfigs / emails clients (`git log -p` spot-check).
- [ ] Aucun nom d’abonnement, tenant, domaine interne hors exemples pédagogiques.
- [ ] `LICENSE` (MIT) et copyright à jour.
- [ ] README FR + [README.en.md](../README.en.md) cohérents ; liens docs FR/EN OK.
- [ ] Avertissement « lab pédagogique, pas un template prod » visible en tête.
- [ ] `slides/social/` et exports marketing **hors** Git (voir `.gitignore`).
- [ ] Essai à blanc Mac : `./setup.sh --yes`, scénarios TP 1–3 ou `scripts/ci-smoke.sh`.
- [ ] CI verte sur `main` (validate + e2e).

### Métadonnées GitHub (à poser au moment du public)

```bash
gh repo edit EtienneDeneuve/flagger-demo-kind \
  --visibility public \
  --description "Hands-on Flagger lab on Kind: Gateway API, Cilium, Envoy Gateway — progressive delivery workshop (FR/EN)" \
  --homepage "https://etienne.deneuve.xyz/projects/flagger-demo-kind/" \
  --add-topic flagger \
  --add-topic gateway-api \
  --add-topic progressive-delivery \
  --add-topic kubernetes \
  --add-topic cilium \
  --add-topic envoy-gateway \
  --add-topic kind \
  --add-topic workshop
```

(`--visibility public` demande confirmation interactive — ou Settings → Danger Zone.)

### Site perso (projet OSS)

Repo site : `etiennedeneuve.github.io`

- [ ] Page `src/content/projects/flagger-demo-kind.md` : passer `draft: false`.
- [ ] Entrée `githubProjectsEditorial` (catégorie `kubernetes-platform`) active.
- [ ] Article Thinking FR/EN (si rédigé) : `draft: false` le jour J, `relatedProjects: [flagger-demo-kind]`.
- [ ] Vérifier `/projects/flagger-demo-kind/` et `/en/projects/flagger-demo-kind/`.

### Ordre recommandé le jour J

1. CI `main` verte sur le lab.
2. `gh repo edit … --visibility public` (+ topics / homepage).
3. Merger / publier la page projet (+ article) sur le site.
4. Smoke : clone anonyme → `./setup.sh --tools-only` au minimum ; lien README ↔ page projet.

## Après publication

- Surveiller Issues ; renvoyer les participants vers `docs/en/05-tp-participant.md` ou FR selon la langue.
- Ne pas promettre support prod ; préciser le périmètre (pas GitOps, pas TLS, métrique app Podinfo).
