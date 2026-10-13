# Contributing

This repository is a **teaching lab**. Prefer clarity for workshop attendees over production generality.

## Before opening a PR

1. `bash -n lab setup.sh scripts/*.sh`
2. Prefer `bash scripts/ci-smoke.sh` on a machine that already has the lab cluster (or rely on CI E2E).
3. Keep participant-facing steps in `manifests/tp/` + `docs/` / `docs/en/` in sync with any `make` shortcut changes.
4. Do not commit `.tools/`, kubeconfigs, or `slides/social/` marketing exports.

## Docs languages

- French is canonical for facilitator notes (`docs/00-formateur.md`).
- English mirrors for the entry points: `README.en.md`, `docs/en/*`.
- Cross-link FR ↔ EN at the top of paired pages.

## Issues

Bug reports that include OS, container engine, `./lab kubectl version --short`, and Canary events (`describe canary/podinfo`) are most useful.
