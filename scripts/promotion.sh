#!/usr/bin/env bash
# TP 1 — même effet que patch manifests/tp/01-promote-v2.patch.yaml
# (annotation unique pour que CI / re-runs déclenchent toujours Flagger).
# Participant : préfère lire et appliquer le fichier à la main.
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"
require_context

want_msg='FLAGGER LAB | V2 VALIDEE'
patch="$(mktemp)"
trap 'rm -f "$patch"' EXIT
# Bumpe la révision pour forcer un nouveau hash même si on relance make good.
sed "s/flagger-lab\\/revision: \"v2\"/flagger-lab\\/revision: \"v2-$(date +%s)\"/" \
  "$ROOT_DIR/manifests/tp/01-promote-v2.patch.yaml" >"$patch"

kubectl -n "$LAB_NS" patch deployment/podinfo --type strategic --patch-file "$patch" >/dev/null

target="$(podinfo_ui_message podinfo)"
if [[ "$target" != "$want_msg" ]]; then
  log_fail "target Deployment pas à jour (lu: ${target:-vide})"
  exit 1
fi
log_ok "V2 demandée via manifests/tp/01-promote-v2.patch.yaml"
log_info "Flagger: poids 25→50 % puis promote · intervalle 10s"
log_info "à la main: ./lab kubectl -n $LAB_NS patch deploy/podinfo --type strategic --patch-file manifests/tp/01-promote-v2.patch.yaml"

for i in $(seq 1 30); do
  phase="$(kubectl -n "$LAB_NS" get canary podinfo -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  case "$phase" in
    Progressing|Finalising|Promoting|Succeeded)
      log_ok "Flagger a détecté la révision  phase=$phase"
      exit 0
      ;;
  esac
  if (( i % 5 == 1 )); then
    log_wait "attente détection Flagger  phase=${phase:-?}  target=$target"
  fi
  sleep 2
done
log_fail "Flagger toujours en phase=${phase:-?} — pas de nouvelle révision détectée"
exit 1
