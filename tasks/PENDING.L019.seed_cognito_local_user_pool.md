# L019 – Seed cognito-local user pool and app client

Status: Pending
Type: Feature
Depends On: L018.add_cognito_local_compose
Description: Commit a Developer Edition Cognito user pool + app client under `DeveloperEdition/cognito-local/` so every `mh up` starts with a shared pool that already defines MentorHub `custom:*` attributes — no per-developer `aws cognito-idp create-user-pool` step.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Research/cognito.md (JWT claims / pool attributes: `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles`; email-as-username)
- ./Research/aws_cognito/aws_cognito_research.md
- ./Research/local_dev_mocks.md
- ./DeveloperEdition/docker-compose.yaml (`mock_cognito` volume from L018)
- ./DeveloperEdition/cognito-local/.cognito/config.json (from L018)
- [cognito-local User Pools and Clients](https://github.com/jagregory/cognito-local#user-pools-and-clients) — pools in `.cognito/db/$userPoolId.json`, clients in `.cognito/db/clients.json`; files may be committed so the team shares one pool
- ./tasks/PENDING.L018.add_cognito_local_compose.md

## Goals

- Add a **committed** cognito-local database seed (not an empty volume) so the mock is usable immediately after compose up:

  | File | Purpose |
  | --- | --- |
  | `DeveloperEdition/cognito-local/.cognito/config.json` | Keep L018 `ServerConfig` / `TokenConfig`; do not add Lambda `TriggerFunctions` |
  | `DeveloperEdition/cognito-local/.cognito/db/<poolId>.json` | User pool **`mentorhub-local`** (stable `Id`, e.g. `local_mentorhub`) |
  | `DeveloperEdition/cognito-local/.cognito/db/clients.json` | One app client for local Admin API / Hosted-UI-shaped calls |

- User pool schema must include MentorHub custom attributes (mutable strings), matching `Research/cognito.md`:

  - `custom:profile_id`
  - `custom:customer_id`
  - `custom:mentor_id`
  - `custom:roles`

- Username policy: email (`UsernameAttributes: ["email"]`). Password policy may be relaxed for local (cognito-local defaults are fine).
- Do **not** pre-seed end-user accounts that duplicate `login.html` personas — returning-user login stays on the welcome page (F-W10). An empty user list is acceptable; the pool + client must exist so `AdminCreateUser` / `SignUp` / `AdminUpdateUserAttributes` have a target.
- Export stable ids on compose services that already have `COGNITO_ENDPOINT`:

  | Variable | Source |
  | --- | --- |
  | `COGNITO_USER_POOL_ID` | Seed pool `Id` (e.g. `local_mentorhub`) |
  | `COGNITO_CLIENT_ID` | Seed app client `ClientId` |

  Defaults via `${COGNITO_USER_POOL_ID:-…}` / `${COGNITO_CLIENT_ID:-…}` on `customer_api` and `admin_api`.
- Keep `COGNITO_ENABLED` default **false**.
- Prefer generating the JSON by running cognito-local once and `aws --endpoint-url http://127.0.0.1:9229 cognito-idp create-user-pool` / `create-user-pool-client` with dummy `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`, then copying `.cognito/db/*` into git — hand-written JSON is allowed if it matches cognito-local’s on-disk shape.
- If bind-mount writes would dirty git during a running stack, document that developers should not commit incidental user records; seed files in git remain the empty pool + client only.
- Confirm `make update` still copies the expanded `cognito-local/` tree (L018 Makefile change).

## Testing Expectations

- After `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer-api up -d mock_cognito` (or equivalent), the following succeeds with dummy AWS credentials:

  ```bash
  AWS_ACCESS_KEY_ID=local AWS_SECRET_ACCESS_KEY=local AWS_DEFAULT_REGION=us-east-1 \
    aws --endpoint-url http://127.0.0.1:9229 cognito-idp list-user-pools --max-results 10
  ```

  Output includes the seeded pool id.

- `describe-user-pool` shows the four `custom:*` attributes.
- `list-user-pool-clients` returns the seeded client id matching compose `COGNITO_CLIENT_ID`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer config` renders `COGNITO_USER_POOL_ID` and `COGNITO_CLIENT_ID` on `customer_api` and `admin_api`.
- Seed JSON is valid JSON (`jq` parse). Do not commit secrets; cognito-local client secrets may be dummy local values.

## Outputs

- `DeveloperEdition/cognito-local/.cognito/config.json` — unchanged except if seed generation requires extra non-trigger settings.
- `DeveloperEdition/cognito-local/.cognito/db/<poolId>.json` — seeded user pool.
- `DeveloperEdition/cognito-local/.cognito/db/clients.json` — seeded app client.
- `DeveloperEdition/docker-compose.yaml` — `COGNITO_USER_POOL_ID` and `COGNITO_CLIENT_ID` on `customer_api` and `admin_api`.

## Execution Notes
