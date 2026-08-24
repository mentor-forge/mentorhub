#!/usr/bin/env bash
# mh-start.sh - start the full Mentor Hub Developer Edition stack (profile: all).
cd "$(dirname "$0")"
if [[ -f "$HOME/.mentorhub/HOST_NAME" ]]; then
  export HOST_NAME=$(<"$HOME/.mentorhub/HOST_NAME")
else
  export HOST_NAME=localhost
fi
docker compose --profile all up --detach
