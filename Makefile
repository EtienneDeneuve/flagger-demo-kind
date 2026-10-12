.PHONY: doctor up port traffic traffic-ab good fail ab status metrics cleanup slides
doctor:
	./scripts/doctor.sh
up:
	./scripts/bootstrap.sh
port:
	./scripts/port-forward.sh
traffic:
	./scripts/traffic.sh
traffic-ab:
	./scripts/traffic.sh ab
good:
	./scripts/promotion.sh
fail:
	./scripts/rollback.sh
ab:
	./scripts/ab.sh
status:
	./scripts/status.sh
metrics:
	./scripts/prometheus.sh
cleanup:
	./scripts/cleanup.sh
slides:
	marp slides/flagger-tp.marp.md --html --output slides/flagger-tp.html
