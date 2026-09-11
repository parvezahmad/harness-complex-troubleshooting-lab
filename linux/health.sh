#!/usr/bin/env bash
set -euo pipefail
FAILURE_MODE="${1:-NONE}"
RELEASE_VERSION="${2:-v1}"
PORT="${3:-8086}"

if [[ "$FAILURE_MODE" == "LINUX_HEALTH_FAILURE" ]]; then
  PORT=65530
  echo "INTENTIONAL LAB FAILURE: checking wrong port $PORT"
fi

body="$(curl -fsS --max-time 5 "http://127.0.0.1:${PORT}/health.txt")"
echo "health body: $body"
grep -F "$RELEASE_VERSION" <<<"$body" >/dev/null

echo "Linux health check PASSED"
