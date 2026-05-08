#!/usr/bin/env bash
set -euo pipefail

JUPYTER_HOST="${JUPYTER_HOST:-0.0.0.0}"
JUPYTER_PORT="${JUPYTER_PORT:-8888}"
VISER_PORT="${VISER_PORT:-8080}"
NOTEBOOK_DIR="${NOTEBOOK_DIR:-/workspace}"
CUROBO_HOME="${CUROBO_HOME:-/opt/curobo}"
JUPYTER_TOKEN="${JUPYTER_TOKEN:-}"

mkdir -p "${NOTEBOOK_DIR}"

cleanup() {
  if [[ -n "${JUPYTER_PID:-}" ]]; then
    kill "${JUPYTER_PID}" 2>/dev/null || true
    wait "${JUPYTER_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

echo "Starting Jupyter Notebook on ${JUPYTER_HOST}:${JUPYTER_PORT}"
jupyter lab \
  --ip="${JUPYTER_HOST:-0.0.0.0}" \
  --port="${JUPYTER_PORT:-8888}" \
  --no-browser \
  --allow-root \
  --ServerApp.root_dir="${NOTEBOOK_DIR:-/workspace}" \
  --ServerApp.preferred_dir="${NOTEBOOK_DIR:-/workspace}" \
  --ServerApp.token="${JUPYTER_TOKEN:-}" \
  --ServerApp.password='' \
  --ServerApp.allow_remote_access=True \
  --ServerApp.allow_origin='*' \
  --ServerApp.trust_xheaders=True \
  --ServerApp.disable_check_xsrf=True \
  > /tmp/jupyter.log 2>&1 &
JUPYTER_PID=$!

echo "Starting cuRobo motion planning viewer on 0.0.0.0:${VISER_PORT}"
cd "${CUROBO_HOME}"
exec python3 -m curobo.examples.getting_started.motion_planning --visualize --port "${VISER_PORT}"
