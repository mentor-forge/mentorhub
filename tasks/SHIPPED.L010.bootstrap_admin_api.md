# L010 – Bootstrap mentorhub_admin_api from mentorhub_mentee_api

Status: Shipped
Type: Feature
Depends On: none
Description: F-W18 — Copy `mentorhub_mentee_api` into the empty `mentorhub_admin_api` repo, strip mentee domain routes/services/tests/OpenAPI, and rename ports, images, and scripts to `admin-api` (port **8389**).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Copy sources table, F-W18)
- ./Specifications/architecture.yaml (admin_api port 8389)
- ../mentorhub_mentee_api/ (copy source — read only for planning; write target is admin_api)
- ../mentorhub_admin_api/ (empty repo — LICENSE + README only today)

## Goals

- Copy the full mentee API project tree from `../mentorhub_mentee_api/` into `../mentorhub_admin_api/` (exclude `.git`; preserve CI/Docker/scripts/test harness patterns).
- **Strip mentee domain surface:**
  - Remove route modules and blueprints: `journey`, `path`, `resource`, `aggregation`, `note` (and any mentee-only `event` routes if present).
  - Remove matching `src/services/*`, `test/services/*`, `test/routes/*`, and E2E fixtures tied to stripped domains.
  - Trim `docs/openapi.yaml` to platform shell only (`/api/config`, `/docs`, `/metrics`) — no mentee path/journey/resource schemas.
  - Update `src/server.py` to register only config, explorer, and metrics routes.
- **Rename to admin-api:**
  - `API_PORT` / dev defaults: **8389** (was 8393).
  - GHCR image: `ghcr.io/mentor-forge/mentorhub_admin_api:latest` (Dockerfile, `.github/workflows`, Pipfile `push`/`delete-package` scripts).
  - Pipfile `[scripts]`: `db`, `api`, `service` profiles → `admin-api` / `admin` compose profile names.
  - `README.md` title, clone path, and local URLs (`localhost:8389`).
- Keep **api-utils 0.5.x** dependency and CodeArtifact pipenv install pattern unchanged from mentee source.
- Initial commit in `mentorhub_admin_api` with meaningful message; push to `mentor-forge/mentorhub_admin_api` on the workflow branch.
- Do **not** implement F-AA01 ingress routes — stub shell only.

## Testing Expectations

- In `../mentorhub_admin_api/`: `pipenv run lint` passes.
- `pipenv run test` passes (unit tests only; no stripped-domain test imports remain).
- `pipenv run dev` starts on port **8389**; `curl -s http://localhost:8389/api/config` succeeds.
- `curl -s http://localhost:8389/docs/openapi.yaml` — no `/api/journey`, `/api/path`, `/api/resource`, `/api/aggregation`, or `/api/note` paths.
- Grep `../mentorhub_admin_api/` — no `mentee_api`, port `8393`, or stripped route module names in active code (except changelog/history if any).

## Outputs

- `../mentorhub_admin_api/` — full bootstrapped API repo (all copied/renamed/stripped files), including but not limited to:
  - `Pipfile`, `Pipfile.lock`
  - `src/server.py`, `src/routes/`, `src/services/`
  - `docs/openapi.yaml`
  - `test/`
  - `Dockerfile`, `scripts/`, `.github/workflows/`
  - `README.md`

## Execution Notes

- **Branch:** `F-W18-Discover-Admin-Bootstrap` in `mentorhub_admin_api`
- **Commit:** `e2532bc246b23ec28b0e4dc3e9ee2e796bc18d7f`
- **Copied** `mentorhub_mentee_api` → `mentorhub_admin_api` (excluded `.git`, `tasks/`)
- **Stripped** route modules: `journey`, `path`, `resource`, `aggregation`, `note`, `event`; matching `test/routes/*`, `test/e2e/*` (kept empty package `__init__.py` files)
- **Shell routes only:** `/api/config`, `/docs`, `/metrics` in `server.py` and trimmed `docs/openapi.yaml`
- **Renamed:** port 8389 (`COORDINATOR_API_PORT` in api-utils 0.5.2), GHCR image `mentorhub_admin_api`, Pipfile compose profiles `admin-api` / `admin`
- **Tests:** `pipenv run lint` — pass; `pipenv run test` — 13 passed
- **Manual:** `pipenv run dev` on port 8389; `/api/config` returns 401 (route live, auth required); `/docs/openapi.yaml` has no stripped domain paths; `/metrics` returns Prometheus output
- **Note:** api-utils 0.5.2 has no `ADMIN_API_PORT` yet; server uses `COORDINATOR_API_PORT` (default 8389) until api-utils adds admin port key
