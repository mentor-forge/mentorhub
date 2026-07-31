# S44 – Confirm compose `IDP_LOGIN_URI` wiring for journey SPAs

Status: Shipped
Type: Defect
Depends On: none
Description: Ensure Developer Edition compose passes `IDP_LOGIN_URI` into journey SPA containers so runtime login redirects honor `~/.mentorhub/HOST_NAME` (via `mh`) instead of hard-coded `127.0.0.1`. Run `make update` so local `mh up` uses the updated compose file (issue F-W08 — SPA login guardrails).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh
- ./tasks/SHIPPED.S41.idp_login_uri_magic_hostname.md
- ./tasks/SHIPPED.S40.compose_bind_0.0.0.0.md

## Background (why this is needed)

S41 wired `mh` to export `IDP_LOGIN_URI="http://<HOST_NAME>:8080/login.html"` when `~/.mentorhub/HOST_NAME` is present, and compose already references `${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}`. Journey SPA containers still redirect to `127.0.0.1` at runtime because the client reads only build-time `VITE_IDP_LOGIN_URI` (see spa_utils 0.5.6 hostname-rewrite workaround). This task confirms the **compose / `mh` side** is correct before spa_utils and SPA container changes land.

## Goals

- `DeveloperEdition/docker-compose.yaml` sets `IDP_LOGIN_URI: ${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}` on **mentee_spa** and **mentor_spa** (and any other journey SPAs in this workflow if missing).
- Compose default remains `http://127.0.0.1:8080/login.html` when `HOST_NAME` is absent (no behavior change for localhost-only developers).
- Run `make update` from the mentorhub repo root so the installed `~/.mentorhub/docker-compose.yaml` matches `DeveloperEdition/docker-compose.yaml`.
- Add a brief inline comment in compose (if helpful) documenting that `IDP_LOGIN_URI` is sourced from `mh` / `~/.mentorhub/HOST_NAME`, not baked into SPA images.

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml --profile mentee config` → static parse only; `mentee_spa.environment.IDP_LOGIN_URI` references `${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}`.
- `make update` completes without error; confirm `~/.mentorhub/docker-compose.yaml` reflects the change.
- **Runtime env via `mh` (preferred over raw compose for this check):**
  - With `~/.mentorhub/HOST_NAME` set, run `make update`, then `mh up mentee`.
  - Inspect the running mentee SPA container: `IDP_LOGIN_URI` must be `http://<HOST_NAME>:8080/login.html` (not the compose default).
  - Without `HOST_NAME`, `mh up mentee` should leave `IDP_LOGIN_URI` at `http://127.0.0.1:8080/login.html`.
- Markdown lint on any docs touched.

## Outputs

- `DeveloperEdition/docker-compose.yaml` — confirm or adjust `IDP_LOGIN_URI` on journey SPA services.
- `CONTRIBUTING.md` — only if a one-line note is needed that compose consumes `mh`-exported `IDP_LOGIN_URI` at container runtime (avoid duplicating S43 VPN section).

## Execution Notes

**Summary of changes**
- Confirmed `mentee_spa` and `mentor_spa` already set `IDP_LOGIN_URI: ${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}` (no env key changes required).
- Added inline compose comment before `mentor_spa` documenting `mh` / `HOST_NAME` sourcing and runtime consumption.

**Verification results**
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile mentee config` → `mentee_spa` `IDP_LOGIN_URI` defaults to `http://127.0.0.1:8080/login.html` when unset.
- With `IDP_LOGIN_URI=http://m5max.tailb0d293.ts.net:8080/login.html` exported (as `mh` does when `~/.mentorhub/HOST_NAME` is set), compose config renders MagicDNS URI on both `mentee_spa` and `mentor_spa`.
- `make update` → success; `~/.mentorhub/docker-compose.yaml` matches repo compose.
- `mh up mentee` → `docker inspect mentorhub-mentee_spa-1` → `IDP_LOGIN_URI=http://m5max.tailb0d293.ts.net:8080/login.html`.

**Follow-up tasks**
- spa_utils F029, mentee_spa L122 — wire SPA client to honor runtime `IDP_LOGIN_URI`.

**Branch:** `F-W08-expose-0.0.0.0`
