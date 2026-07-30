#!/usr/bin/env bash
# mh-restart.sh - refresh the full Mentor Hub Developer Edition stack (profile: all).
#
# Stops running services, pulls the latest images, then recreates them.
# Target runtime: the Spark server (ZeroClaw AI agent account), invoked by
# absolute path. cd into the script's own directory so the default
# docker-compose.yaml beside it resolves regardless of the caller's CWD.
set -euo pipefail
cd "$(dirname "$0")"

# Optional, non-fatal GHCR login so private ghcr.io/mentor-forge images can pull.
if [[ -z "${GITHUB_TOKEN:-}" && -f "$HOME/.mentorhub/GITHUB_TOKEN" ]]; then
  GITHUB_TOKEN="$(<"$HOME/.mentorhub/GITHUB_TOKEN")"
fi
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${MH_GHCR_ORG:-mentor-forge}" --password-stdin >/dev/null 2>&1 \
    || echo "Warning: GHCR login failed; continuing (cached images may still work)." >&2
fi

docker compose --profile all stop
docker compose --profile all pull
# `up --detach` (not `start`) recreates containers so freshly pulled images take effect.
docker compose --profile all up --detach
