# Flagger + Gateway API — progressive delivery lab on Kind

**[Français](README.md) · [English](README.en.md)**

**A reproducible 60-minute Kubernetes lab for canary delivery, rollback and A/B testing with Flagger, Gateway API, Envoy Gateway, Cilium and Prometheus.**

Kubernetes can deploy a new revision. This lab focuses on the next question: **who decides that the revision deserves more traffic, which metrics support that decision, and how the routing change is actually enforced**.

<p align="center">
  <a href="https://etienne.deneuve.xyz/en/projects/flagger-demo-kind/?utm_source=github&utm_medium=repository&utm_campaign=flagger-demo-kind&utm_content=readme-en">Project page</a> ·
  <a href="docs/en/05-tp-participant.md">Participant lab</a> ·
  <a href="docs/en/01-architecture.md">Architecture</a> ·
  <a href="slides/flagger-tp.marp.md">Slides</a>
</p>

## What the lab demonstrates

- **Progressive canary delivery** driven by Flagger and Prometheus metrics.
- **Gateway API HTTPRoute** as the traffic-control surface.
- **Envoy Gateway** as the data plane and **Cilium** as the CNI — no Istio or additional service mesh.
- Observable, reproducible **promotion, rollback and A/B testing** on an isolated Kind cluster.

> Teaching lab, not a production template. Versions are pinned and tooling stays isolated inside the repository.

## Quick start

**Prerequisites:** macOS (Apple Silicon or Intel), `git`, `curl`, a running Docker-compatible engine (Docker Desktop, OrbStack, **Rancher Desktop in Moby mode**, or Colima), ~8 GB RAM for the engine (12 GB recommended), and network access for images. With Rancher, leave built-in Kubernetes off (Kind owns the cluster). Lab scripts may add `~/.rd/bin` for `docker`, but keep pinned `kubectl`/`helm` from `.tools/bin` ahead of Rancher’s copies (`make doctor` must show `.tools/bin`).

```bash
git clone https://github.com/EtienneDeneuve/flagger-demo-kind.git
cd flagger-demo-kind
./setup.sh
```

The script asks **3 questions** (sensible defaults): shell mode, create Kind cluster, open the lab shell. It never silently installs Docker, Nix, or edits your `~/.zshrc` / `~/.kube/config`.

**Nix is optional.** Default path without devenv: `./setup.sh --mode=local` then `./scripts/shell.sh`. Same contract as devenv: private `KUBECONFIG` + pinned CLIs in `.tools/bin/`. `make …` works from a normal terminal (scripts source `_common.sh`). Use `./lab kubectl …` for an isolated kubectl. Facilitator check without Nix: `bash scripts/verify-local-demo.sh`.

`make browser` needs `python3` (typically macOS `/usr/bin/python3`); otherwise use `curl -H 'Host: podinfo.local'`.

## Demo terminals

```bash
make port      # Envoy → localhost:8080 (reuses a healthy tunnel)
make traffic   # background HTTP load
make status    # Flagger phase / weights / events
make browser   # UI with Host: podinfo.local via :18080
```

Plain `http://127.0.0.1:8080/` returns **404** without `Host: podinfo.local`.

## Participant path (apply config yourself)

Full walkthrough: [docs/en/05-tp-participant.md](docs/en/05-tp-participant.md) · French: [docs/05-tp-participant.md](docs/05-tp-participant.md)

```bash
# 1. Promote a healthy V2 (weight steps)
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/01-promote-v2.patch.yaml

# 2. Degraded V3 + fault injection on canary only — see the TP guide

# 3. A/B: Canary match header, then V4 revision
./lab kubectl apply -f manifests/tp/03-ab-canary.yaml
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/03-revision-v4.patch.yaml
```

Optional shortcuts (same YAML under the hood): `make good` · `make fail` · `make ab`.

## Docs

| Topic | English | Français |
|---|---|---|
| Participant exercises | [docs/en/05-tp-participant.md](docs/en/05-tp-participant.md) | [docs/05-tp-participant.md](docs/05-tp-participant.md) |
| Architecture & trade-offs | [docs/en/01-architecture.md](docs/en/01-architecture.md) | [docs/01-architecture.md](docs/01-architecture.md) |
| Facilitator notes | — | [docs/00-formateur.md](docs/00-formateur.md) |
| Troubleshooting | [docs/en/02-diagnostic.md](docs/en/02-diagnostic.md) | [docs/02-diagnostic.md](docs/02-diagnostic.md) |
| Go-public checklist | — | [docs/03-publication.md](docs/03-publication.md) |

Upstream docs: [Flagger Gateway API tutorial](https://docs.flagger.app/tutorials/gatewayapi-progressive-delivery) · [Envoy Gateway](https://gateway.envoyproxy.io/) · [Cilium](https://docs.cilium.io/en/stable/) · [Kind](https://kind.sigs.k8s.io/) · [Podinfo](https://github.com/stefanprodan/podinfo)

## Cleanup

```bash
make cleanup   # deletes only the Kind cluster flagger-platform-lab
```

## License

MIT — see [LICENSE](LICENSE).
