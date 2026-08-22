# L021 – Add MailHog SMTP mock for Customer API

Status: Shipped
Type: Feature
Depends On: L020.document_cognito_local_mock
Description: Add a `mailhog/mailhog` container to Developer Edition compose (SMTP **1025**, Web UI **8025**) and point **Customer API** at it so invite and other outbound mail can be captured locally without a real SMTP provider.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Research/local_dev_mocks.md (L7 stripe-mock / L018 cognito-local compose pattern)
- ./Workshops/customer_journey_issues.md (F-CA08 member invite email; F-W10 local mocks)
- ./Research/cognito.md (Path B invite email in production is Cognito; local Customer API still needs SMTP for app-sent mail)
- ./DeveloperEdition/docker-compose.yaml (`mock_stripe_api`, `mock_cognito` after L018)
- ./Makefile (`make update` copies compose to `~/.mentorhub/docker-compose.yaml`)
- ./Specifications/ArchitectureDiagram.local.drawio (already has **mailhog (smtp mock)**)
- [mailhog/mailhog](https://hub.docker.com/r/mailhog/mailhog) — SMTP **1025**, HTTP UI **8025**, in-memory store, no auth
- ./tasks/PENDING.L018.add_cognito_local_compose.md (service naming, `0.0.0.0` bind, profiles, no `depends_on` on APIs)
- ./tasks/PENDING.L020.document_cognito_local_mock.md (README port list — this task adds 1025/8025 after 9229 is documented)

## Goals

- Add compose service **`mock_mailhog`** next to the other local mocks (`mock_stripe_api`, `mock_cognito`), using public image **`mailhog/mailhog:latest`** (no GHCR login).
- Publish both default MailHog ports, bound like every other Developer Edition service:

  | Purpose | Binding |
  | --- | --- |
  | SMTP (Customer API → MailHog) | **`0.0.0.0:1025:1025`** |
  | Web UI / HTTP API (inspect captured mail) | **`0.0.0.0:8025:8025`** |

- Compose **profiles** (Customer API at minimum): `all`, `customer`, `customer-api`. Do not add mentor/mentee-only profiles. Adding `admin` / `admin-api` is optional only if those services already send SMTP in this repo’s compose env; do not invent Admin mail wiring.
- `restart: no`. In-memory storage is fine (`mh down` already discards local state); do not add `MH_STORAGE` volumes unless required to start.
- Inline comment pointing at `Research/local_dev_mocks.md`, parallel to the stripe-mock / cognito-local comments.
- Wire **SMTP env on `customer_api` only** (minimum). Do **not** implement a mailer in `mentorhub_customer_api` in this task.

  | Variable | Default |
  | --- | --- |
  | `SMTP_HOST` | `${SMTP_HOST:-mock_mailhog}` |
  | `SMTP_PORT` | `${SMTP_PORT:-1025}` |
  | `SMTP_FROM` | `${SMTP_FROM:-noreply@mentorhub.local}` |
  | `SMTP_USER` | `${SMTP_USER:-}` (empty — MailHog has no auth) |
  | `SMTP_PASSWORD` | `${SMTP_PASSWORD:-}` |
  | `SMTP_STARTTLS` | `${SMTP_STARTTLS:-false}` |

- Do **not** add `depends_on: mock_mailhog` on `customer_api` (same as stripe-mock / cognito-local).
- Do **not** send real internet mail; do not add SES/SMTP production credentials.
- **Docs (same task — MailHog has no seed files):**
  - `README.md` Quick Start port note: add **1025/8025 (MailHog)** (keep 9229 and 12111).
  - `Research/local_dev_mocks.md`: document `mock_mailhog`, host UI `http://127.0.0.1:8025`, compose SMTP `mock_mailhog:1025`, and that Customer API is the first consumer (invite / app mail). Production Cognito invite email is unchanged.
  - `CONTRIBUTING.md`: only if the mocks one-liner from L020 exists — add MailHog to that list.
- Run `make update` so `~/.mentorhub/docker-compose.yaml` matches the repo file.
- Do **not** change `index.html`. Portal links for MailHog, Stripe mock, Cognito mock, and Stage0 Launch are **L025**.

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` parses without error.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer config` lists `mock_mailhog` with **1025** and **8025**, both `host_ip: 0.0.0.0`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer-api config` includes `mock_mailhog` and renders the `SMTP_*` defaults on `customer_api`.
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile mentee config` does **not** include `mock_mailhog`.
- Ports **1025** and **8025** do not collide with 8080, 27017, 8383–8398, 9229, 12111.
- `make update` succeeds; installed compose under `~/.mentorhub/` contains `mock_mailhog`.
- Optional smoke: `docker compose -f DeveloperEdition/docker-compose.yaml --profile customer-api up -d mock_mailhog` then `curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8025/` returns **200**.
- Markdown lint on touched docs if tooling is available.

## Outputs

- `DeveloperEdition/docker-compose.yaml` — `mock_mailhog` service, profiles, `SMTP_*` on `customer_api`.
- `Research/local_dev_mocks.md` — MailHog compose/env/UI notes.
- `README.md` — port list includes 1025/8025.
- `CONTRIBUTING.md` — only if a mocks cross-reference needs MailHog.

## Execution Notes

### Plan

1. Add `mock_mailhog` service after `mock_cognito` in `DeveloperEdition/docker-compose.yaml` — mirror stripe/cognito pattern (`restart: no`, `0.0.0.0` binds, profiles `all`/`customer`/`customer-api`, trailing comment).
2. Add six `SMTP_*` env vars on `customer_api` only (no `depends_on`, no admin wiring — admin_api has no SMTP today).
3. Document in `Research/local_dev_mocks.md` (new MailHog section + env table + testing matrix row).
4. Update `README.md` port note and `CONTRIBUTING.md` mocks one-liner.
5. Run `make update`; validate compose config, profiles, port collision, optional MailHog smoke.

### Results

| Test | Result |
| --- | --- |
| `docker compose config` parses | PASS |
| `--profile customer` → `mock_mailhog` ports 1025/8025, `host_ip: 0.0.0.0` | PASS |
| `--profile customer-api` → `mock_mailhog` + `SMTP_*` defaults on `customer_api` | PASS (`SMTP_HOST: mock_mailhog`, `SMTP_PORT: "1025"`, `SMTP_FROM: noreply@mentorhub.local`, empty user/password, `SMTP_STARTTLS: "false"`) |
| `--profile mentee` excludes `mock_mailhog` | PASS |
| Ports 1025/8025 no collision with 8080, 27017, 8383–8398, 9229, 12111 | PASS |
| `make update` succeeds; `~/.mentorhub/docker-compose.yaml` contains `mock_mailhog` | PASS |
| Smoke: `up -d mock_mailhog`; `curl http://127.0.0.1:8025/` → 200 | PASS (image pulls as linux/amd64 on arm64 host — runs via emulation) |
| Markdown lint (`npx markdownlint-cli2` on touched docs) | Pre-existing MD013/MD012 issues in all three files; no new structural errors from L021 edits |

**Blockers:** None.

**Admin profiles:** Skipped — `admin_api` has no SMTP env in compose; no invented admin mail wiring per task spec.

**Not changed:** `index.html` (portal links deferred to L025).