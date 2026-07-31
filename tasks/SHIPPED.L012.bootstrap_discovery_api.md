# L012 – Bootstrap mentorhub_discovery_api from mentorhub_customer_api

Status: Shipped
Type: Feature
Depends On: none
Description: F-W18 — Copy `mentorhub_customer_api` into the empty `mentorhub_discovery_api` repo, strip card/dashboard/subscription/journey/rating/note domains, plan **api-utils 0.2→0.5** upgrade path, keep **customer + profile** routes as the F-DA01 starting point, and rename to `discovery-api` (port **8397**).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Copy sources table, F-W18)
- ./Workshops/discovery_journey_issues.md (F-DA01 starting point)
- ./Specifications/architecture.yaml (discovery_api port 8397)
- ../mentorhub_customer_api/ (copy source — api-utils **0.2.1**)
- ../mentorhub_mentee_api/ (reference for api-utils **0.5.x** harvest patterns)
- ../mentorhub_discovery_api/ (empty repo — LICENSE + README only today)

## Goals

- Copy the full customer API project tree from `../mentorhub_customer_api/` into `../mentorhub_discovery_api/` (exclude `.git`).
- **Strip customer control/create domains not owned by Discovery:**
  - Remove routes, services, tests, and OpenAPI for: `card`, `dashboard`, `subscription`, `journey`, `rating`, `note`.
  - Remove Stripe/Cognito dev env vars and webhook routes from discovery bootstrap (ingress moves to Admin — F-AA01).
- **Keep for F-DA01:**
  - `customer_routes` + `CustomerService` (list/get patterns).
  - `profile_routes` + `ProfileService` (list/get patterns).
  - Platform shell: config, explorer, metrics.
- **api-utils 0.2→0.5 upgrade path (bootstrap scope):**
  - Bump `Pipfile` `api-utils` to **0.5.x** (align with mentee/mentor).
  - Migrate `CustomerService` and `ProfileService` toward `api_utils.services` harvest patterns where straightforward; document remaining local-service debt in `README.md` for F-UA08 / F-DA01 follow-up.
  - Remove obsolete local `_collection_name()` fallbacks if superseded by Config constants in 0.5.x.
- **Rename to discovery-api:**
  - `API_PORT` / dev defaults: **8397** (was 8387).
  - GHCR image: `ghcr.io/mentor-forge/mentorhub_discovery_api:latest`.
  - Pipfile `[scripts]`: compose profile names → `discovery-api` / `discovery`.
  - `README.md` title, clone path, local URLs (`localhost:8397`).
- Initial commit in `mentorhub_discovery_api`; push to `mentor-forge/mentorhub_discovery_api`.
- Do **not** implement F-DA01 dashboard aggregate or Notification dismiss — keep inherited customer/profile list endpoints only.

## Testing Expectations

- In `../mentorhub_discovery_api/`: `pipenv run lint` passes.
- `pipenv run test` passes after strip and api-utils bump.
- `pipenv run dev` on port **8397**; `curl -s http://localhost:8397/api/config` succeeds.
- OpenAPI served at `/docs/openapi.yaml` includes `/api/customer` and `/api/profile` (or equivalent kept paths); **excludes** card, dashboard, subscription, journey, rating, note.
- `Pipfile` shows `api-utils == 0.5.x` from CodeArtifact index.
- Grep — no `mentorhub_customer_api`, port **8387**, or stripped domain route prefixes in active code.

## Outputs

- `../mentorhub_discovery_api/` — full bootstrapped API repo, including but not limited to:
  - `Pipfile`, `Pipfile.lock`
  - `src/server.py`, `src/routes/customer_routes.py`, `src/routes/profile_routes.py`
  - `src/services/` (trimmed)
  - `docs/openapi.yaml`
  - `test/`
  - `Dockerfile`, `scripts/`, `.github/workflows/`
  - `README.md` (includes api-utils migration notes)

## Execution Notes

**Completed 2026-07-31 (F-W18, branch `F-W18-Discover-Admin-Bootstrap`, commit `5e077c3`).**

- Copied `mentorhub_customer_api/` → `mentorhub_discovery_api/` (excluded `.git`).
- Stripped routes/services/tests/e2e/OpenAPI for: card, dashboard, subscription, journey, rating, note, event.
- Kept: `customer_routes`, `profile_routes`, `CustomerService`, `ProfileService`, config/explorer/metrics shell.
- Bumped `api-utils` **0.2.1 → 0.5.2**; services remain local (list/get infinite-scroll pattern differs from `api_utils.services.ProfileService` mentor-dashboard API). Migration debt documented in `README.md`.
- Renamed: port **8397** (`API_PORT` / `DISCOVERY_API_PORT`), GHCR `ghcr.io/mentor-forge/mentorhub_discovery_api:latest`, Pipfile profiles `discovery-api` / `discovery`.
- No Stripe/Cognito webhook env in bootstrap (ingress deferred to Admin F-AA01).
- **Tests:** `pipenv run lint` ✅ | `pipenv run test` ✅ (51 passed, 8 e2e deselected).
