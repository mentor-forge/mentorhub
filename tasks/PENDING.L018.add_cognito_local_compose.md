# L018 – Add cognito-local mock service to Developer Edition compose

Status: Pending
Type: Feature
Depends On: none
Description: Follow-on to F-W10 **L5** — add a `jagregory/cognito-local` container to `DeveloperEdition/docker-compose.yaml` that exposes the AWS Cognito Identity Provider API on host port **9229**, so Customer/Admin APIs can target a local IdP endpoint without AWS credentials.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Research/local_dev_mocks.md (locked L5 deferred cognito-local; L2 `COGNITO_ENABLED=false`; L7 stripe-mock pattern)
- ./Research/cognito.md (production Admin API / custom claims — do not implement API clients here)
- ./Workshops/customer_journey_issues.md (F-W10 — stripe-mock done; cognito-local was deferred)
- ./DeveloperEdition/docker-compose.yaml (`mock_stripe_api` on **12111** is the compose pattern to mirror)
- ./DeveloperEdition/mh
- ./Makefile (`make update` copies compose to `~/.mentorhub/docker-compose.yaml`)
- [jagregory/cognito-local](https://github.com/jagregory/cognito-local) — default listen port **9229**; image `jagregory/cognito-local:latest`
- ./tasks/SHIPPED.L015.wire_developer_edition_compose.md (profile / `0.0.0.0` bind conventions)
- ./tasks/SHIPPED.S40.compose_bind_0.0.0.0.md

## Goals

- Add a compose service named **`mock_cognito`** next to `mock_stripe_api`, using public image `jagregory/cognito-local:latest` (no GHCR login required).
- Publish **`0.0.0.0:9229:9229`** (cognito-local default). Do not remap the container port.
- Bind-mount a repo-owned config directory so the process listens on all interfaces inside the container (default `ServerConfig.hostname` is `localhost` and would be unreachable from other compose services):

  | Host path (relative to compose file) | Container path |
  | --- | --- |
  | `./cognito-local/.cognito` | `/app/.cognito` |

  Minimal `config.json` for this task (full user-pool seed is **L019**):

  ```json
  {
    "ServerConfig": { "hostname": "0.0.0.0", "port": 9229 },
    "TokenConfig": { "IssuerDomain": "http://localhost:9229" },
    "UserPoolDefaults": { "UsernameAttributes": ["email"] }
  }
  ```

- Compose **profiles**: `all`, `customer`, `customer-api`, `admin`, `admin-api` (same consumers as Customer/Admin Cognito Admin API / ingress — not mentor/mentee-only profiles).
- `restart: no` (match other Developer Edition services).
- Inline comment pointing at `Research/local_dev_mocks.md`, parallel to the existing `stripe-mock` comment.
- Wire **endpoint env only** so APIs can opt in later. Do **not** set `COGNITO_ENABLED=true` (login.html / HS256 path must keep working).

  | Service | Variable | Default |
  | --- | --- | --- |
  | `customer_api` | `COGNITO_ENDPOINT` | `${COGNITO_ENDPOINT:-http://mock_cognito:9229}` |
  | `admin_api` | `COGNITO_ENDPOINT` | `${COGNITO_ENDPOINT:-http://mock_cognito:9229}` |

- Do **not** add `depends_on: mock_cognito` to APIs (`customer_api` does not depend on `mock_stripe_api` either).
- Do **not** add Lambda / Post Confirmation trigger config (locked L6 still applies).
- Do **not** change `login.html`, `welcome-auth.js`, SPA `IDP_LOGIN_URI`, or JWT minting.
- Copy the new `DeveloperEdition/cognito-local/` tree in **`make update`** (and `make install` if that target later copies compose) so `~/.mentorhub/cognito-local/.cognito` exists beside the installed compose file. Relative volume `./cognito-local` must resolve both from the repo (`mh-start.sh` cds to `DeveloperEdition/`) and from `~/.mentorhub/` after `make update`.
- Run `make update` so `~/.mentorhub/docker-compose.yaml` matches the repo file.

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` parses without error.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer config` lists `mock_cognito` with published **9229** and `host_ip: 0.0.0.0`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile admin-api config` lists `mock_cognito`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile mentee config` does **not** include `mock_cognito`.
- Rendered `customer_api` / `admin_api` include `COGNITO_ENDPOINT: http://mock_cognito:9229` and still have `COGNITO_ENABLED` default **false** on `customer_api`.
- Port **9229** does not collide with existing compose ports (8080, 27017, 8383–8398, 12111).
- `make update` succeeds; `~/.mentorhub/docker-compose.yaml` contains `mock_cognito`; `~/.mentorhub/cognito-local/.cognito/config.json` exists.
- Optional smoke (if images can be pulled): `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer-api up -d mock_cognito` then `curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9229/` returns an HTTP status (any response from the listener is success; Cognito APIs are AWS JSON POSTs, not REST GETs).

## Outputs

- `DeveloperEdition/docker-compose.yaml` — `mock_cognito` service, profiles, `COGNITO_ENDPOINT` on `customer_api` and `admin_api`.
- `DeveloperEdition/cognito-local/.cognito/config.json` — listen on `0.0.0.0:9229`.
- `Makefile` — copy `DeveloperEdition/cognito-local/` to `~/.mentorhub/cognito-local/` on `make update` (and install if compose is copied there).

## Execution Notes
