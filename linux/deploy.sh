#!/usr/bin/env bash
set -euo pipefail

FAILURE_MODE="${1:-NONE}"
RELEASE_VERSION="${2:-v1}"
APP_DIR="${HOME}/harness-multi-infra-lab"
PORT="${3:-8086}"

printf '=== Linux deployment ===\n'
printf 'host=%s user=%s failureMode=%s release=%s\n' "$(hostname)" "$(id -un)" "$FAILURE_MODE" "$RELEASE_VERSION"

if [[ "$FAILURE_MODE" == "LINUX_SCRIPT_FAILURE" ]]; then
  echo "INTENTIONAL LAB FAILURE: Linux deploy exits with code 61" >&2
  exit 61
fi

mkdir -p "$APP_DIR"
cat > "$APP_DIR/index.html" <<HTML
<!doctype html>
<html><body><h1>Harness Linux Troubleshooting Lab</h1><p>Release: ${RELEASE_VERSION}</p><p>Host: $(hostname)</p></body></html>
HTML

echo "OK - Linux - ${RELEASE_VERSION}" > "$APP_DIR/health.txt"

if [[ -f "$APP_DIR/http.pid" ]]; then
  oldpid="$(cat "$APP_DIR/http.pid" || true)"
  kill "$oldpid" 2>/dev/null || true
fi

cd "$APP_DIR"
nohup python3 -m http.server "$PORT" >http.log 2>&1 &
echo $! > http.pid
sleep 1

echo "Linux sample service started on port $PORT"
