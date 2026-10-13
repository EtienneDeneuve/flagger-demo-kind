# Flagger Demo Kind — progressive delivery with Cilium and Envoy Gateway

**[Français](README.md)** · English

**60-minute macOS workshop · 4 Marp slides · hands-on YAML (not just `make`).**

Kubernetes can roll pods. Flagger decides whether a new revision **deserves more traffic**, using Prometheus metrics and Gateway API `HTTPRoute` weights. Traffic is served by Envoy Gateway; Cilium is the only CNI. **No Istio, no extra service mesh.**

This is a **teaching lab**, not a production template.

Project page: [etienne.deneuve.xyz/projects/flagger-demo-kind](https://etienne.deneuve.xyz/projects/flagger-demo-kind/).  
**Repository goes public:** 13 October 2026, **10:30** (Europe/Paris).

## Quick start

**Prerequisites:** macOS (Apple Silicon or Intel), `git`, `curl`, a running Docker-compatible engine (Docker Desktop, OrbStack, **Rancher Desktop in Moby mode**, or Colima), ~8 GB RAM for the engine (12 GB recommended), and network access for images.

```bash
git clone https://github.com/EtienneDeneuve/flagger-demo-kind.git
cd flagger-demo-kind
./setup.sh
```

The script asks **3 questions** (sensible defaults): shell mode, create Kind cluster, open the lab shell. It never silently installs Docker or edits your `~/.zshrc` / `~/.kube/config`.

Pinned `kind` / `kubectl` / `helm` / `cilium` land in `.tools/bin/` with SHA-256 checks. Use `./lab kubectl …` for an isolated context.

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
