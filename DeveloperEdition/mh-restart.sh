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
export LAUNCHPAD_DIR="${LAUNCHPAD_DIR:-$MENTORHUB_PATH}"

if [[ -z "${IDP_LOGIN_URI:-}" ]]; then
  file_idp_uri="$(read_mh_file "${MH_DIR}/IDP_LOGIN_URI")"
  if [[ -n "${file_idp_uri}" ]]; then
    export IDP_LOGIN_URI="${file_idp_uri}"
  fi
fi

if [[ -z "${IDP_LOGIN_URI:-}" ]]; then
  HOST_NAME="$(read_mh_file "${MH_DIR}/HOST_NAME")"
  if [[ -n "${HOST_NAME}" ]]; then
    # If HOST_NAME already includes a scheme (e.g. https://spark-478a.tailb0d293.ts.net)
    if [[ "${HOST_NAME}" =~ ^https?:// ]]; then
      base_url="${HOST_NAME%/login.html}"
      base_url="${base_url%/}"
      export IDP_LOGIN_URI="${base_url}/login.html"
      h_only="${base_url#*://}"
      h_only="${h_only%%:*}"
      export HOST_NAME="${h_only%%/*}"
    elif [[ "${HOST_NAME}" =~ \.ts\.net$ ]]; then
      # If on a Tailscale .ts.net domain, check if Tailscale Funnel is active
      is_funnel=false
      if command -v tailscale >/dev/null 2>&1; then
        if tailscale funnel status 2>/dev/null | grep -Eqi "(funnel is on|active|https://${HOST_NAME})" || \
           sudo -n tailscale funnel status 2>/dev/null | grep -Eqi "(funnel is on|active|https://${HOST_NAME})"; then
          is_funnel=true
        fi
      fi
      if [[ "$is_funnel" == "true" || "${FUNNEL:-}" == "true" ]]; then
        export IDP_LOGIN_URI="https://${HOST_NAME}/login.html"
      else
        export IDP_LOGIN_URI="http://${HOST_NAME}:8080/login.html"
      fi
      export HOST_NAME="${HOST_NAME}"
    else
      export HOST_NAME="${HOST_NAME}"
      export IDP_LOGIN_URI="http://${HOST_NAME}:8080/login.html"
    fi
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
echo "LAUNCHPAD_DIR=${LAUNCHPAD_DIR}"

# Stop first so pull is not racing running containers; up --detach recreates
# from the newly pulled tags (start would keep old container filesystems).
docker compose --profile all stop
docker compose --profile all pull
# Build local welcome container image from current repo files so local edits are applied
docker build -t ghcr.io/mentor-forge/mentorhub:latest "${SCRIPT_DIR}/.."
docker compose --profile all up --detach
