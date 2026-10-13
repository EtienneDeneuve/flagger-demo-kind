# Participant lab — progressive delivery with Flagger

**[Français](../05-tp-participant.md)** · English

You drive the cluster **with config files**, not only `make` shortcuts.
`make good|fail|ab` still exist (same YAML underneath) — in session, **open and apply** files under `manifests/tp/`.

Budget **~50 minutes** once the lab is installed (`./setup.sh` beforehand).

## Core idea

```text
1. You change the target Deployment (YAML patch)  → new revision
2. Flagger detects the pod-template hash
3. Flagger updates the HTTPRoute (weights or match) → you do NOT edit it
4. Prometheus + MetricTemplate                    → promote / rollback
```

## Prep (once)

| Terminal | Command | Role |
|---|---|---|
| 1 | `make port` | Envoy tunnel → `:8080` |
| 2 | `make traffic` | HTTP load — **leave running** |
| 3 | `make status` | Phase / weight / events |

```bash
curl -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/ | head
./lab kubectl -n flagger-demo get canary/podinfo
```

> Without `Host: podinfo.local` → **404**. Do not create a manual `HTTPRoute`.

File index: [manifests/tp/README.md](../../manifests/tp/README.md).

---

## Lab 0 — Read before you act (5 min)

1. Open `manifests/05-canary.yaml`: `interval`, `stepWeight`, `maxWeight`, `thresholdRange.max`.
2. Open `manifests/tp/01-promote-v2.patch.yaml`: what changes in the pod template?
3. Inspect state:

```bash
./lab kubectl -n flagger-demo get deploy podinfo,podinfo-primary -o wide
./lab kubectl -n flagger-demo get httproute podinfo -o yaml | less
```

**Note:** who writes HTTPRoute weights? What does `04-metrics.yaml` measure?

---

## Lab 1 — Progressive promotion (patch a config)

**File:** `manifests/tp/01-promote-v2.patch.yaml`

```bash
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/01-promote-v2.patch.yaml
```

Watch 30–60 s: traffic (`.`), `make status` (weights 25→50 → Succeeded), UI **V2 VALIDEE**.

**Pass:** phase `Succeeded`, primary = `FLAGGER LAB | V2 VALIDEE`.

> Re-applying the same patch without bumping `flagger-lab/revision` may be a no-op (same hash).

---

## Lab 2 — Rollback on 5xx (patch + explicit fault)

**File:** `manifests/tp/02-degraded-v3.patch.yaml`

| Step | What | Why |
|---|---|---|
| A | Patch Deployment V3 | Flagger starts a **Ready** canary |
| B | `POST …/fault_injection/enable` on **canary** Service | HTTP 5xx without breaking `/readyz` |

```bash
./lab kubectl apply -f manifests/05-canary.yaml
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/02-degraded-v3.patch.yaml
```

When `Progressing` + canary endpoints exist:

```bash
./lab kubectl -n flagger-demo port-forward svc/podinfo-canary 19898:9898
curl -sS -X POST http://127.0.0.1:19898/fault_injection/enable
```

**Pass:** phase `Failed`, primary still V2, public HTTP 200.

> **Wait ~15 s** before lab 3 (Prometheus `rate([{{ interval }}])` window).

---

## Lab 3 — A/B: apply Canary + patch revision

```bash
make traffic-ab
./lab kubectl apply -f manifests/tp/03-ab-canary.yaml
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/03-revision-v4.patch.yaml
```

During `Progressing`:

```bash
curl -sS -H 'Host: podinfo.local' -H 'x-canary: always' http://127.0.0.1:8080/api/info   # → V4
curl -sS -H 'Host: podinfo.local' http://127.0.0.1:8080/api/info                         # → V2
```

**Pass:** header/public split while Progressing; then primary = **V4 BETA**.

---

## Optional shortcuts

| Make | Lab equivalent |
|---|---|
| `make good` | patch `01-promote-v2.patch.yaml` |
| `make fail` | apply `05-canary` + patch `02-…` + fault curl |
| `make ab` | apply `03-ab-canary.yaml` + patch `03-revision-v4` |

## Out of scope

GitOps, alerting, TLS, NetworkPolicy, end-to-end Envoy metrics, Istio.

**Takeaway:** you trigger a revision (YAML); Flagger decides traffic (HTTPRoute + metrics).

## Help

- [02-diagnostic.md](02-diagnostic.md) · [01-architecture.md](01-architecture.md) · FR facilitator: [../00-formateur.md](../00-formateur.md)
