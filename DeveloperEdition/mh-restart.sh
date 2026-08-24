#!/usr/bin/env bash
# mh-restart.sh - refresh the full Mentor Hub Developer Edition stack (profile: all).
cd "$(dirname "$0")"
if [[ -f "$HOME/.mentorhub/HOST_NAME" ]]; then
  export HOST_NAME=$(<"$HOME/.mentorhub/HOST_NAME")
else
  export HOST_NAME=localhost
fi
docker compose --profile all down --volumes --remove-orphans

cd ..
git pull  # pull the latest docker-compose.yaml
cd "$(dirname "$0")"

docker compose --profile all pull
docker compose --profile all up --detach
