# S49 – Remove Coordinator services from docker-compose.yaml

Status: Pending
Type: Feature
Depends On: S48
Description: F-W09 E0 — Strip `coordinator_api` and `coordinator_spa` from Developer Edition compose and align remaining services with `architecture.yaml` (Admin/Discovery compose services land in BLOCKED.S53 when F-W18 repos exist).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/customer_journey_issues.md (F-W09)
- ./Specifications/architecture.yaml (updated by S48)
- ./DeveloperEdition/docker-compose.yaml
- ./DeveloperEdition/mh
- ./tasks/SHIPPED.S44.compose_idp_login_uri_journey_spas.md

## Goals

- Delete `coordinator_api` and `coordinator_spa` service blocks from `DeveloperEdition/docker-compose.yaml`.
- Remove `coordinator` and `coordinator-api` from all compose **profiles** on shared services (`welcome`, `mongodb`, `mongodb_api`, `mongodb_spa`, etc.).
- Preserve **Customer** stack unchanged: `customer_api`, `customer_spa`, `mock_stripe_api`, Cognito-related env vars (`COGNITO_ENABLED`, `REGISTRATION_DEV_MODE`, etc.).
- Preserve mentor/mentee journey SPA `IDP_LOGIN_URI` wiring from S44.
- Update inline comments that reference coordinator or the removed VPN subsection in CONTRIBUTING (e.g. MongoDB security note — point to Step 3 `HOST_NAME` after S52, or a neutral “see CONTRIBUTING.md” reference).
- Run `make update` so `~/.mentorhub/docker-compose.yaml` matches the repo file.
- Do **not** add Admin/Discovery compose services in this task (F-W18 — see BLOCKED.S53).

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` — parses with no errors; no `coordinator` service or profile references remain.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer config` — still includes `customer_api`, `customer_spa`, `mock_stripe_api`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile all config` — service list matches architecture journey domains present in compose (schema, customer, mentor, mentee only).
- `make update` completes without error.
- Optional smoke: `mh up customer` starts without referencing coordinator images.

## Outputs

- `DeveloperEdition/docker-compose.yaml` — remove coordinator services and profile entries; adjust comments as needed.

## Execution Notes
