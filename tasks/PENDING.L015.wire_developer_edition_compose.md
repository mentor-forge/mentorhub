# L015 – Wire Admin + Discovery services in Developer Edition compose

Status: Pending
Type: Feature
Depends On: L014.seed_repo_task_frameworks
Description: F-W18 — Add `admin_api`, `admin_spa`, `discovery_api`, and `discovery_spa` services to `DeveloperEdition/docker-compose.yaml` with correct ports, env, profiles, and `IDP_LOGIN_URI` wiring (stub images until F-AA01 / F-DA01 feature work).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Platform wiring, F-W18)
- ./Specifications/architecture.yaml (ports 8389, 8390, 8397, 8398)
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh
- ./tasks/SHIPPED.S44.compose_idp_login_uri_journey_spas.md (IDP_LOGIN_URI pattern)
- ./tasks/SHIPPED.S48.refactor_architecture_remove_coordinator.md (port assignments)

## Goals

- Add four compose services mirroring existing journey domain patterns:

| Service | Image | Host port | API env | Notes |
| --- | --- | --- | --- | --- |
| `admin_api` | `ghcr.io/mentor-forge/mentorhub_admin_api:latest` | **8389:8389** | `API_PORT=8389` | JWT + Mongo env like mentee_api; **no** Stripe/Cognito ingress env yet |
| `admin_spa` | `ghcr.io/mentor-forge/mentorhub_admin_spa:latest` | **8390:80** | `API_HOST=admin_api`, `API_PORT=8389` | `IDP_LOGIN_URI` from `${IDP_LOGIN_URI:-...}` |
| `discovery_api` | `ghcr.io/mentor-forge/mentorhub_discovery_api:latest` | **8397:8397** | `API_PORT=8397` | JWT + Mongo; no Stripe webhook env |
| `discovery_spa` | `ghcr.io/mentor-forge/mentorhub_discovery_spa:latest` | **8398:80** | `API_HOST=discovery_api`, `API_PORT=8397` | `IDP_LOGIN_URI` + default post-login target SPA |

- Add compose **profiles**: `admin`, `admin-api`, `discovery`, `discovery-api`; include new services in `all` profile dependency lists where appropriate.
- Bind ports `0.0.0.0` (consistent with S40).
- Add inline comment for journey SPAs / `IDP_LOGIN_URI` / `mh` HOST_NAME pattern on new SPA services (same as mentee_spa).
- Run `make update` so `~/.mentorhub/docker-compose.yaml` reflects changes.
- Document stub limitation in compose comment: services expect published GHCR images from L010–L013 bootstrap builds (local `docker build` acceptable for dev before first push).

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` parses without error.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile admin config` lists `admin_api` and `admin_spa` with ports **8389** / **8390**.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile discovery config` lists `discovery_api` and `discovery_spa` with ports **8397** / **8398**.
- SPA services expose `IDP_LOGIN_URI: ${IDP_LOGIN_URI:-http://127.0.0.1:8080/login.html}`.
- `make update` succeeds; installed compose under `~/.mentorhub/` matches repo file.
- Port grep across compose — no collision with customer (8387/8388), mentor (8391/8392), mentee (8393/8394), runbook (8395/8396).

## Outputs

- `DeveloperEdition/docker-compose.yaml` — four new services, profiles, and `all` profile wiring.

## Execution Notes
