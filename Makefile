SHELL := /bin/bash
.PHONY: help setup tools shell doctor up port traffic traffic-ab good fail ab status metrics cleanup slides
help:
	@printf '%s\n' 'setup: ./setup.sh (3 prompts)' 'tools: local pinned toolchain only' 'shell: isolated zsh' 'doctor: diagnostics' 'up: cluster bootstrap' 'port: Envoy port-forward' 'traffic: requests' 'status: Flagger status' 'good/fail/ab: demos' 'cleanup: remove lab cluster'
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
