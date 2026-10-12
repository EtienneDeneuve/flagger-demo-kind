SHELL := /bin/bash
.PHONY: doctor up port traffic traffic-ab good fail ab status metrics cleanup slides

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
