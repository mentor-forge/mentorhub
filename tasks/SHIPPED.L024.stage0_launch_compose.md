# L024 – Add Stage0 Launch to Developer Edition compose

Status: Shipped
Type: Feature
Depends On: L023.login_shared_origin_return_to
Description: Run Stage0 Launch beside welcome so the developer portal can link to it. Follow **stage0_launch README** mounts and env — do not invent a Specifications-only bind that the Launch image does not use.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh (already exports `GITHUB_TOKEN` from `~/.mentorhub/GITHUB_TOKEN`)
- ./Makefile (`make update`; **`make stage0-launch-ui`** is **out of date** vs Launch README)
- ../.stage0-launch.yaml stub created by `make install` (`umbrella: mentorhub`)
- **Canonical Launch contract:** `../stage0_launch/README.md` if present as a sibling, else https://github.com/agile-learning-institute/stage0_launch/blob/main/README.md
  - Image: `ghcr.io/agile-learning-institute/stage0_launch:latest`
  - Container listens on **8080**; Compose host port is **`LAUNCH_HOST_PORT`** (default 8080 in Launch’s own compose — **cannot** use 8080 here; welcome already owns it)
  - Volume: **`${LAUNCHPAD_HOST}:/Launchpad`** — launchpad **parent** of the umbrella (sibling repos + `mentorhub/Specifications`)
  - Do **not** set **`LAUNCHPAD_DIR`** for this layout (`/Launchpad` exists → used automatically)
  - Env: `GITHUB_TOKEN`, `GITHUB_USERNAME` (legacy `GH_*` mirrored in the image), optional **`DELETE_ENABLED=True`** (literal string), **`STAGE0_LAUNCH_CONTAINER_NAME`** matching `container_name`
  - Docker socket: `/var/run/docker.sock` for nested `docker run`
  - Interactive mode needs `.stage0-launch.yaml` at the **launchpad root** pointing at the umbrella folder; specs are **`<launchpad>/<umbrella>/Specifications`**, not a separate `/Specifications` mount
- ./tasks/SHIPPED.L015.wire_developer_edition_compose.md (`0.0.0.0` bind, profiles)

## Goals

- Add compose service **`stage0_launch`** (image above).
- **Host port:** **`0.0.0.0:8081:8080`** (or `${LAUNCH_HOST_PORT:-8081}:8080`). Never bind host **8080**. Document the override.
- **Volumes (README-accurate):**
  - `${LAUNCHPAD_HOST}:/Launchpad` — host directory that **contains** `mentorhub/` (and sibling journey repos).
  - `/var/run/docker.sock:/var/run/docker.sock`
  - Do **not** add a second bind for `Specifications` (current `Makefile` `stage0-launch-ui` `-v .../Specifications:/specifications` and `LAUNCHPAD_DIR=/launchpad` **disagree with Launch README**; retire that pattern).
- **`MENTORHUB_PATH`:** `make update` writes the absolute path of this umbrella repo to `~/.mentorhub/MENTORHUB_PATH`. `mh` (or compose) sets **`LAUNCHPAD_HOST`** to the **parent** of that path so `/Launchpad/mentorhub/Specifications` is the spec tree Launch already expects.
- **Env:**
  - `GITHUB_TOKEN: ${GITHUB_TOKEN:?}` (mh already loads the file)
  - `GITHUB_USERNAME: ${GITHUB_USERNAME:-}`
  - `DELETE_ENABLED: ${DELETE_ENABLED:-}` — pass through; default empty so Delete stays off unless the developer exports `True` (README: umbrella Makefile keeps Delete off the beaten path)
  - `STAGE0_LAUNCH_CONTAINER_NAME: stage0_launch`
  - `container_name: stage0_launch` so nested inspect matches
- Profiles: `all` and `stage0`. Welcome/portal can start without Launch if the profile omits it.
- `restart: no` (match other Developer Edition services).
- Align **`make stage0-launch-ui`** with this compose (delegate to `mh up stage0` **or** the same ports/mounts/env). Stop advertising `localhost:8080` for Launch.
- If Launch cannot enter interactive mode with this mount (discovery error), **stop and record a paste-ready `tasks/ISSUE.stage0_launch.*.md`** rather than setting `LAUNCHPAD_DIR` or a fake `/Specifications` mount. That is the only Stage0 source-change dependency this ticket allows.
- Do **not** reverse-proxy Launch under welcome `/{journey}/` (Flask app has its own `/api`; subpath needs a Launch change). Portal links use **:8081** (L025).

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml --profile stage0 config` lists `stage0_launch` with host **8081** (not 8080) and volume target **`/Launchpad`**.
- Rendered env includes `DELETE_ENABLED` (may be empty) and `STAGE0_LAUNCH_CONTAINER_NAME=stage0_launch`.
- No `LAUNCHPAD_DIR` on the service.
- `make update` writes `~/.mentorhub/MENTORHUB_PATH`; `mh` exports `LAUNCHPAD_HOST` as its parent.
- Optional smoke: `mh up stage0` (with `GITHUB_TOKEN`) → `curl -sS http://127.0.0.1:8081/api/status` returns JSON with `delete_enabled` and launchpad discovery (interactive if `../.stage0-launch.yaml` is valid).
- `make stage0-launch-ui` help/docs no longer say port 8080.

## Outputs

- `DeveloperEdition/docker-compose.yaml` — `stage0_launch` service.
- `DeveloperEdition/mh` — `LAUNCHPAD_HOST` from `MENTORHUB_PATH` parent; pass through `DELETE_ENABLED` / `GITHUB_USERNAME` if present.
- `Makefile` — `make update` writes `MENTORHUB_PATH`; `stage0-launch-ui` aligned or delegated.

## Execution Notes

- Added `stage0_launch` to Developer Edition compose with profiles `all` and
  `stage0`, host port `${LAUNCH_HOST_PORT:-8081}`, the launchpad parent mounted
  at `/Launchpad`, and the Docker socket. The service does not set
  `LAUNCHPAD_DIR` or mount `Specifications` separately.
- `make update` now records the absolute umbrella path in
  `~/.mentorhub/MENTORHUB_PATH`. `mh` reads that file and exports
  `LAUNCHPAD_HOST` as the path's parent.
- Replaced the obsolete `docker run` implementation of
  `make stage0-launch-ui` with the compose service and updated Launch
  documentation to use port 8081.
- Validation: the `stage0` compose config rendered host `0.0.0.0:8081` to
  container port `8080`, `/Launchpad` and Docker socket binds,
  `DELETE_ENABLED=""`, and
  `STAGE0_LAUNCH_CONTAINER_NAME=stage0_launch`, with no `LAUNCHPAD_DIR`.
  `zsh -n DeveloperEdition/mh`, `make help`, and `git diff --check` passed.
- Smoke test: `/api/status` returned `delete_enabled=false`,
  `launchpad=/Launchpad`, `specs_dir=/Launchpad/mentorhub/Specifications`,
  `discovery_ok=true`, `interactive_mode=true`, and no discovery error.
  No follow-up ISSUE was needed.
