SHELL := /bin/bash
.PHONY: help setup tools shell doctor up port browser traffic traffic-ab good fail ab status metrics cleanup slides
help:
	@printf '%s\n' \
		'setup: ./setup.sh (3 prompts)' \
		'tools / shell / doctor / up: toolchain, zsh isolé, diagnostic, bootstrap' \
		'port / browser / traffic / status: tunnel Envoy, UI, charge, phase Flagger' \
		'good / fail / ab: raccourcis (= manifests/tp/*.yaml) — préférer kubectl apply/patch' \
		'cleanup: remove lab cluster' \
		'slides: Marp HTML' \
		'docs: docs/05-tp-participant.md · docs/00-formateur.md'
setup:
	bash setup.sh
tools:
	bash scripts/install-tools.sh
shell:
	bash scripts/shell.sh
doctor:
	bash scripts/doctor.sh
up:
	bash scripts/bootstrap.sh
port:
	bash scripts/port-forward.sh
browser:
	bash scripts/browser.sh
traffic:
	bash scripts/traffic.sh
traffic-ab:
	bash scripts/traffic.sh ab
good:
	bash scripts/promotion.sh
fail:
	bash scripts/rollback.sh
ab:
	bash scripts/ab.sh
status:
	bash scripts/status.sh
metrics:
	bash scripts/prometheus.sh
cleanup:
	bash scripts/cleanup.sh
slides:
	marp slides/flagger-tp.marp.md --html --output slides/flagger-tp.html
