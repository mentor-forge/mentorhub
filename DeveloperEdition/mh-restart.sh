#!/usr/bin/env bash
# mh-restart.sh — refresh the full Mentor Hub Developer Edition stack (profile: all)
# without using `mh`. Intended for the GB10 / Spark host over Tailscale.
#
# `docker compose up --detach` (not `start`) is what applies freshly pulled images.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
MH_DIR="${HOME}/.mentorhub"

read_mh_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    tr -d '\r' <"$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  fi
}

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  GITHUB_TOKEN="$(read_mh_file "${MH_DIR}/GITHUB_TOKEN")"
  export GITHUB_TOKEN
fi
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Error: GITHUB_TOKEN is not set. Save it as ${MH_DIR}/GITHUB_TOKEN" >&2
  exit 1
fi

if [[ -z "${MENTORHUB_PATH:-}" ]]; then
  MENTORHUB_PATH="$(read_mh_file "${MH_DIR}/MENTORHUB_PATH")"
  export MENTORHUB_PATH
fi
if [[ -z "${MENTORHUB_PATH:-}" ]]; then
  MENTORHUB_PATH="$(cd "${SCRIPT_DIR}/.." && pwd)"
  export MENTORHUB_PATH
fi
export LAUNCHPAD_HOST="${LAUNCHPAD_HOST:-$(dirname "$MENTORHUB_PATH")}"

if [[ -z "${IDP_LOGIN_URI:-}" ]]; then
  HOST_NAME="$(read_mh_file "${MH_DIR}/HOST_NAME")"
  if [[ -n "${HOST_NAME}" ]]; then
    export HOST_NAME
    export IDP_LOGIN_URI="http://${HOST_NAME}:8080/login.html"
  else
    export HOST_NAME=localhost
    export IDP_LOGIN_URI="http://127.0.0.1:8080/login.html"
  fi
fi

if [[ -z "${JWT_SECRET:-}" ]]; then
  JWT_SECRET="$(read_mh_file "${MH_DIR}/JWT_DEV_SECRET")"
  export JWT_SECRET="${JWT_SECRET:-local-dev-jwt-secret-fixed}"
fi

# Private ghcr.io/mentor-forge images. Login is best-effort so a stale token
# does not block using already-pulled images.
ghcr_org="${MH_GHCR_ORG:-mentor-forge}"
if ! echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$ghcr_org" --password-stdin >/dev/null; then
  echo "Warning: GHCR login failed; image pull may fail if images are not cached." >&2
fi

# Refresh this umbrella repo so docker-compose.yaml is current.
if git -C "${SCRIPT_DIR}/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${SCRIPT_DIR}/.." pull || echo "Warning: git pull of mentorhub failed; continuing with local compose." >&2
fi

echo "IDP_LOGIN_URI=${IDP_LOGIN_URI}"
echo "LAUNCHPAD_HOST=${LAUNCHPAD_HOST}"

# Stop first so pull is not racing running containers; up --detach recreates
# from the newly pulled tags (start would keep old container filesystems).
docker compose --profile all stop
docker compose --profile all pull
docker compose --profile all up --detach
