#!/usr/bin/env bash
# Ouvre podinfo dans le navigateur macOS.
# Envoy matche hostname podinfo.local → sans Host header, localhost:8080 renvoie 404.
# Ce script :
#   1) vérifie que make port (ou équivalent) écoute déjà sur 8080
#   2) lance un proxy local :18080 qui injecte Host: podinfo.local
#   3) ouvre http://127.0.0.1:18080/ dans le navigateur par défaut
set -euo pipefail
source "$(dirname "$BASH_SOURCE")/_common.sh"

UPSTREAM="${PODINFO_UPSTREAM:-127.0.0.1:8080}"
LISTEN="${PODINFO_BROWSER_PORT:-18080}"
HOST_HEADER="${PODINFO_HOST:-podinfo.local}"

pick_python() {
  local candidate
  # Prefer a working interpreter: devenv/nix python3, then system.
  # Skip broken shims (mise/asdf) that print "tool not found".
  for candidate in python3 /usr/bin/python3; do
    if ! command -v "$candidate" >/dev/null 2>&1 && [[ ! -x "$candidate" ]]; then
      continue
    fi
    if "$candidate" -c 'import http.server, http.client' >/dev/null 2>&1; then
      command -v "$candidate" 2>/dev/null || printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if ! http_ok -H "Host: $HOST_HEADER" "http://$UPSTREAM/"; then
  log_fail "Envoy inaccessible sur http://$UPSTREAM (Host: $HOST_HEADER)"
  log_info "dans un autre terminal : make port"
  exit 1
fi

proxy_pid=''
cleanup() {
  if [[ -n "$proxy_pid" ]]; then kill "$proxy_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT

# Already listening? reuse.
if ! http_ok "http://127.0.0.1:$LISTEN/"; then
  if ! PYTHON="$(pick_python)"; then
    log_fail "python3 introuvable (http.server requis pour le proxy Host)"
    log_info "depuis ce dépôt : direnv allow / devenv shell  (python3 est dans devenv.nix)"
    exit 1
  fi
  "$PYTHON" - "$LISTEN" "$UPSTREAM" "$HOST_HEADER" <<'PY' &
import http.client, http.server, sys

listen, upstream, host_header = int(sys.argv[1]), sys.argv[2], sys.argv[3]
up_host, up_port = upstream.rsplit(":", 1)
up_port = int(up_port)

class Handler(http.server.BaseHTTPRequestHandler):
    def _proxy(self):
        length = int(self.headers.get("Content-Length", "0") or 0)
        body = self.rfile.read(length) if length else None
        conn = http.client.HTTPConnection(up_host, up_port, timeout=10)
        headers = {k: v for k, v in self.headers.items() if k.lower() not in ("host", "transfer-encoding")}
        headers["Host"] = host_header
        conn.request(self.command, self.path, body=body, headers=headers)
        resp = conn.getresponse()
        payload = resp.read()
        self.send_response(resp.status)
        for k, v in resp.getheaders():
            if k.lower() in ("transfer-encoding", "connection", "content-encoding"):
                continue
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(payload)
        conn.close()

    def do_GET(self): self._proxy()
    def do_HEAD(self): self._proxy()
    def do_POST(self): self._proxy()
    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

http.server.ThreadingHTTPServer(("127.0.0.1", listen), Handler).serve_forever()
PY
  proxy_pid=$!
  ready=0
  for _ in $(seq 1 20); do
    if http_ok "http://127.0.0.1:$LISTEN/"; then
      ready=1
      break
    fi
    if ! kill -0 "$proxy_pid" 2>/dev/null; then
      log_fail "proxy Host mort au démarrage (python=$PYTHON)"
      exit 1
    fi
    sleep 0.2
  done
  if (( ready == 0 )); then
    log_fail "proxy Host n'écoute pas sur :$LISTEN"
    exit 1
  fi
fi

log_ok "http://127.0.0.1:$LISTEN/  →  $UPSTREAM  (Host: $HOST_HEADER)"
log_info "alt: 127.0.0.1 $HOST_HEADER dans /etc/hosts → http://$HOST_HEADER:8080/"
open "http://127.0.0.1:$LISTEN/" || log_warn "ouvre manuellement http://127.0.0.1:$LISTEN/"
# Keep proxy alive while browser is used (Ctrl-C to stop).
if [[ -n "$proxy_pid" ]]; then wait "$proxy_pid"; fi
