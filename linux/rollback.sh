#!/usr/bin/env bash
set -euo pipefail
APP_DIR="${HOME}/harness-multi-infra-lab"

if [[ -f "$APP_DIR/http.pid" ]]; then
  pid="$(cat "$APP_DIR/http.pid" || true)"
  kill "$pid" 2>/dev/null || true
  rm -f "$APP_DIR/http.pid"
fi

echo "Linux lab service stopped/rolled back"
