# S42 – Add mh-start.sh and mh-restart.sh for the Spark server

Status: Pending
Type: Feature
Depends On: S40
Description: Provide two thin wrapper scripts in `DeveloperEdition/` so the Spark server (running under the ZeroClaw AI agent account) can start and refresh the full Developer Edition stack non-interactively (issue F-W08 #40).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh

## Background

- Target runtime is the Spark server; the script is invoked by absolute path (e.g. `~/source/mentor-forge/mentorhub/DeveloperEdition/mh-restart.sh`).
- Because the working directory at invocation is not guaranteed, each script must `cd "$(dirname "$0")"` so the default `docker-compose.yaml` beside it resolves.
- The compose images are private (`ghcr.io/mentor-forge/...`), so a `pull` needs a GHCR login. Reuse the existing `mh` pattern: read `~/.mentorhub/GITHUB_TOKEN` and `docker login ghcr.io`.

## Goals

- `DeveloperEdition/mh-start.sh`:
  - `cd "$(dirname "$0")"`.
  - Optional, non-fatal GHCR login from `~/.mentorhub/GITHUB_TOKEN` (org `${MH_GHCR_ORG:-mentor-forge}`).
  - `docker compose --profile all up --detach`.
- `DeveloperEdition/mh-restart.sh`:
  - `cd "$(dirname "$0")"`.
  - Optional, non-fatal GHCR login (same as above).
  - `docker compose --profile all stop`, then `docker compose --profile all pull`, then `docker compose --profile all up --detach`.
  - Note in a comment that `up --detach` (not `start`) is what actually applies freshly pulled images.
- Both scripts use `#!/usr/bin/env bash` and `set -euo pipefail`, and are created executable (`chmod +x`).
- Scripts rely on the default `docker-compose.yaml` in the same directory (no `-f` needed after `cd`).

## Testing Expectations

- `bash -n DeveloperEdition/mh-start.sh` and `bash -n DeveloperEdition/mh-restart.sh` — no syntax errors.
- `shellcheck` on both scripts if available (no errors; warnings noted).
- Confirm both files are marked executable.

## Outputs

- `DeveloperEdition/mh-start.sh` — new file (executable).
- `DeveloperEdition/mh-restart.sh` — new file (executable).

## Execution Notes

**Summary of changes**
- Added `DeveloperEdition/mh-start.sh`: `set -euo pipefail`, `cd "$(dirname "$0")"`, optional non-fatal GHCR login from `~/.mentorhub/GITHUB_TOKEN`, then `docker compose --profile all up --detach`.
- Added `DeveloperEdition/mh-restart.sh`: same header/login, then `stop` → `pull` → `up --detach` (comment notes `up --detach`, not `start`, applies freshly pulled images).
- Both created with `#!/usr/bin/env bash` and marked executable (`chmod +x`).

**Verification results**
- `ls -l` → both files are `-rwxr-xr-x` (executable; git records mode 100755).
- `bash -n` on both scripts → no syntax errors.
- `shellcheck` → not installed on this host, skipped (task says "if available").

**Follow-up tasks**
- `mh-restart.sh` pulls the published welcome image; for local testing of unreleased `welcome-auth.js` changes use `make container` + `mh up` instead (documented for developers in S43 / earlier guidance).
