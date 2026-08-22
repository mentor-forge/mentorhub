# Local Development — Cognito, Stripe & MailHog Mocks

**Context:** Production uses **AWS Cognito** (Hosted UI + Admin API) and **Stripe** (Checkout, Portal, webhooks). Developer Edition must support local work **without AWS or Stripe accounts** for:

- **Returning users** — SPA login with JWT claims (existing `login.html`)
- **New primary user** — self-registration → new Customer + Profile + claims
- **Invited member** — new Profile under inviter’s `customer_id` + claims
- **Update user** — role / `customer_id` / attribute changes reflected in JWT
- **Subscribe / billing** — Checkout Session, webhooks, Portal (F-CA06+)

**Related:** `Research/cognito.md`, `Research/stripe_research.md`, `DeveloperEdition/docker-compose.yaml`, `login.html`, `welcome-auth.js`.

Mock **UIs** (MailHog **8025**, Stripe mock **12111**, Cognito mock **9229**) are linked from the welcome portal **Tools** section on their own ports — not under `/{journey}/` on **8080**.

---

## Locked decisions (2026-07-28)

These choices prioritize **best practice for local dev** (real API + MongoDB paths, no cloud credentials) with **minimal moving parts** (official API mocks in compose where justified; no Lambda in compose).

| # | Decision | Rationale |
| --- | --- | --- |
| **L1** | **Extend `login.html` / `welcome-auth.js` only** for Cognito-shaped flows locally | Matches today’s dev IdP; SPAs keep `IDP_LOGIN_URI` → welcome page; no Hosted UI locally |
| **L2** | **`COGNITO_ENABLED=false`** in Developer Edition | Customer API skips boto3 Admin calls; MongoDB Profile/Customer is source of truth locally |
| **L3** | **Shared registration service** — production Post Confirmation callback and dev routes call the same functions | One code path for E1/E4 provisioning; dev does not fork business logic |
| **L4** | **Dev-only HTTP routes** on Customer API, guarded by **`REGISTRATION_DEV_MODE=true`** | Routes are not mounted in production (404). Never ship dev mode to prod stacks |
| **L5** | **`mock_cognito` (cognito-local) in compose** — Cognito Admin / IDP wire protocol on port **9229** | Seeded user pool for boto3 integration tests and future `COGNITO_ENABLED=true` opt-in; **does not** replace `login.html` for daily SPA sign-in while **L2** holds |
| **L6** | **No Post Confirmation Lambda in compose** | `login.html` → dev register route → same service as F-CA05 production callback |
| **L7** | **`stripe-mock`** in compose for Stripe API calls | Official stub; `STRIPE_API_BASE` points at container |
| **L8** | **Webhook testing:** fixture POST in e2e + **`STRIPE_WEBHOOK_VERIFY=false`** in dev; Stripe CLI on host optional for manual test-mode runs | No `stripe listen` service in compose; daily dev does not need Stripe CLI |
| **L9** | **JWT unchanged:** HS256 minted client-side after API returns claims — `JWT_SECRET=local-dev-jwt-secret-fixed`, `iss: dev-idp`, `aud: dev-api` | Aligns with `DeveloperEdition/standards/api_standards.md` |

**Explicitly not doing locally (MVP):** Cognito Hosted UI, **real AWS Cognito** (cloud credentials), production Stripe keys, webhook signature verification in automated dev/e2e (still required in prod).

---

## Architecture (local vs production)

| Concern | Production | Local dev (locked) |
| --- | --- | --- |
| SPA sign-in UX | Cognito Hosted UI | **`login.html`** — tabs: Sign in, Register org, Join invite, Update claims |
| JWT validation | Cognito-issued (RS256/JWKS or configured) | HS256 minted by welcome page after API returns Profile claims |
| Primary self-reg | Hosted UI → Post Confirmation Lambda → F-CA05 | Register tab → **`POST /api/dev/register/primary`** → mint JWT |
| Invited member | F-CA08 AdminCreateUser + invite email | Join tab → **`POST /api/dev/register/invite`** → mint JWT (simulates invitee first login) |
| Update claims | AdminUpdateUserAttributes + Pre Token Gen | Update tab → **`PATCH /api/dev/profile/{id}/claims`** → re-mint JWT |
| Customer API → Cognito | Real `cognito-idp` when `COGNITO_ENABLED=true` | **`COGNITO_ENDPOINT` wired** to `mock_cognito`; boto3 **skipped** while `COGNITO_ENABLED=false` |
| Customer API → Stripe | `api.stripe.com` | **`http://mock_stripe_api:12111`** via `STRIPE_API_BASE` |
| Stripe webhooks | Verified signatures | Dev/e2e: fixture POST; verify off when `STRIPE_WEBHOOK_VERIFY=false` |

---

## Stripe mock (official)

**Image:** [`stripe/stripe-mock`](https://github.com/stripe/stripe-mock) — HTTP stub of Stripe API + fixture payloads.

**Compose:** `mock_stripe_api` on `127.0.0.1:12111` (profiles `customer-api`, `customer`, `all`).

**Customer API env (F-CA06):**

| Variable | Local value |
| --- | --- |
| `STRIPE_API_BASE` | `http://mock_stripe_api:12111` (compose network) or `http://127.0.0.1:12111` from host |
| `STRIPE_SECRET_KEY` | `sk_test_local_dev` (any test key — stripe-mock accepts it) |
| `STRIPE_WEBHOOK_SECRET` | Unused when `STRIPE_WEBHOOK_VERIFY=false` |
| `STRIPE_WEBHOOK_VERIFY` | `false` in Developer Edition |

**Webhook testing (locked):**

1. **Automated e2e / CI** — POST canned Event JSON to `POST /api/webhooks/stripe` with verify disabled.
2. **Manual (optional)** — Stripe CLI on host against **real** Stripe test mode: `stripe listen --forward-to localhost:8387/api/webhooks/stripe`. Not required for day-to-day compose.

**Docs:** [stripe-mock](https://github.com/stripe/stripe-mock), [Stripe CLI](https://docs.stripe.com/stripe-cli), [Testing](https://docs.stripe.com/testing).

---

## Cognito mock (cognito-local)

**Image:** [`jagregory/cognito-local`](https://github.com/jagregory/cognito-local) — local AWS Cognito Identity Provider API (Admin + IDP wire protocol).

**Compose:** `mock_cognito` on `127.0.0.1:9229` (profiles `all`, `customer`, `customer-api`, `admin`, `admin-api`). Persistent seed data in `DeveloperEdition/cognito-local/.cognito/`.

**Seeded user pool (L019):**

| Item | Value |
| --- | --- |
| Pool Id | `local_2LcVdLgK` (`mentorhub-local`) |
| App client Id | `34g5holmfkd8emq7v6vldbubg` (`mentorhub-local-client`) |
| Custom attributes | `custom:profile_id`, `custom:customer_id`, `custom:mentor_id`, `custom:roles` |

**API env (wired on `customer_api` and `admin_api`; boto3 not active until a later task sets `COGNITO_ENABLED=true`):**

| Variable | Local value |
| --- | --- |
| `COGNITO_ENDPOINT` | `http://mock_cognito:9229` (compose network) or `http://127.0.0.1:9229` from host / AWS CLI |
| `COGNITO_USER_POOL_ID` | `local_2LcVdLgK` |
| `COGNITO_CLIENT_ID` | `34g5holmfkd8emq7v6vldbubg` |
| `COGNITO_ENABLED` | `false` on `customer_api` (default) — daily login stays `login.html` + HS256 JWT (**L1**, **L2**, **L9**) |

**Host vs compose network:**

- From your machine or AWS CLI: `--endpoint-url http://127.0.0.1:9229`
- From API containers on the compose network: `http://mock_cognito:9229`

**AWS CLI smoke (dummy credentials — cognito-local accepts any):**

```sh
export AWS_ACCESS_KEY_ID=local AWS_SECRET_ACCESS_KEY=local AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url http://127.0.0.1:9229 cognito-idp list-user-pools --max-results 10

aws --endpoint-url http://127.0.0.1:9229 cognito-idp admin-create-user \
  --user-pool-id local_2LcVdLgK \
  --username dev@example.com \
  --user-attributes Name=email,Value=dev@example.com Name=email_verified,Value=true
```

**Docs:** [cognito-local](https://github.com/jagregory/cognito-local).

---

## MailHog (SMTP mock)

**Image:** [`mailhog/mailhog`](https://hub.docker.com/r/mailhog/mailhog) — in-memory SMTP capture + web UI (no auth).

**Compose:** `mock_mailhog` on SMTP **1025** and HTTP UI **8025** (profiles `all`, `customer`, `customer-api`).

**Customer API env (F-CA08 invite / app-sent mail):**

| Variable | Local value |
| --- | --- |
| `SMTP_HOST` | `mock_mailhog` (compose network) or `127.0.0.1` from host |
| `SMTP_PORT` | `1025` |
| `SMTP_FROM` | `noreply@mentorhub.local` |
| `SMTP_USER` | *(empty — MailHog has no auth)* |
| `SMTP_PASSWORD` | *(empty)* |
| `SMTP_STARTTLS` | `false` |

**Host vs compose network:**

- Web UI (inspect captured mail): [http://127.0.0.1:8025](http://127.0.0.1:8025)
- From API containers on the compose network: `mock_mailhog:1025`

**Consumer:** **Customer API** is the first compose consumer (member invite and other app-sent mail). Production Cognito invite email (Path B) is unchanged — MailHog captures only mail sent by the Customer API SMTP client locally.

**Docs:** [mailhog/mailhog](https://hub.docker.com/r/mailhog/mailhog).

---

## Cognito mock — welcome dev IdP (locked)

Production Cognito involves Hosted UI, Admin API, and Post Confirmation Lambda. For **daily local sign-in**, we simulate **outcomes** (MongoDB + JWT) via the welcome page and dev API routes (**L1**, **L2**, **L9**) — not Cognito Hosted UI or Cognito-issued tokens. The **cognito-local** container (above) exposes Admin/IDP wire protocol for integration tests and future opt-in; it does not replace `login.html` while `COGNITO_ENABLED=false`.

### `login.html` tabs (F-W10)

| Tab | Simulates | Flow |
| --- | --- | --- |
| **Sign in** (existing) | Returning user login | Pick seeded profile → mint JWT from stored claims |
| **Register organization** | E1 Path A — Hosted UI sign-up + Post Confirmation | Form: email, name, org name → `POST /api/dev/register/primary` → mint JWT with new `profile_id`, `customer_id`, `roles: ["customer"]`, `mentor_id: ""` |
| **Join as invited member** | E4 invitee first login (after AdminCreateUser in prod) | Form: sponsor `customer_id`, name, email → `POST /api/dev/register/invite` → mint JWT under inviter |
| **Update profile claims** | AdminUpdateUserAttributes + re-login | Pick profile, edit `roles` / `customer_id` / `mentor_id` → `PATCH /api/dev/profile/{profile_id}/claims` → re-mint JWT |

**JWT minting stays client-side** in `welcome-auth.js`; Customer API validates with shared `JWT_SECRET`.

### Customer API dev routes (F-CA05 — implement in `customer_api`)

Mounted only when `REGISTRATION_DEV_MODE=true`:

| Route | Purpose |
| --- | --- |
| `POST /api/dev/register/primary` | Body: `email`, `name`, `organization_name` → create Customer + Profile (owner) |
| `POST /api/dev/register/invite` | Body: `customer_id`, `email`, `name` → create Profile under customer |
| `PATCH /api/dev/profile/{profile_id}/claims` | Body: `roles`, `customer_id`, `mentor_id` → update Profile claim fields |

Production equivalents:

| Dev route | Production |
| --- | --- |
| `register/primary` | `POST /api/internal/cognito/post-confirmation` (service auth, F-CA05) |
| `register/invite` | `POST /api/invites` (F-CA08) with `COGNITO_ENABLED=true` |
| `update claims` | Profile PATCH + Cognito sync (steady-state) |

All paths call the same **`registration_service`** (or equivalent) — dev routes must not duplicate create/update logic.

### Deferred (not MVP)

| Approach | When to reconsider |
| --- | --- |
| **LocalStack Cognito** | Only if broader AWS emulation is already adopted — heavier than needed for onboarding |

---

## Local dev registration flow

```text
Developer Edition — new primary user (no AWS)

  login.html → "Register organization"
    → POST customer_api /api/dev/register/primary  (REGISTRATION_DEV_MODE=true)
         → registration_service: create Customer + Profile
         → COGNITO_ENABLED=false → skip AdminUpdateUserAttributes
    → welcome-auth mints JWT (profile_id, customer_id, roles, mentor_id "")
    → redirect to Customer SPA #access_token=…

Developer Edition — invited member

  login.html → "Join as invited member"
    → POST customer_api /api/dev/register/invite
    → mint JWT under inviter customer_id

Developer Edition — update claims

  login.html → "Update profile claims"
    → PATCH /api/dev/profile/{id}/claims
    → re-mint JWT for same sub

Developer Edition — billing

  Customer SPA checkout → Customer API → stripe-mock (STRIPE_API_BASE)
  Webhook sync → fixture POST or optional Stripe CLI on host
```

Production path unchanged: Cognito Hosted UI + Lambdas + real Admin API + Stripe.

---

## Environment variables (Developer Edition)

| Service | Variable | Local value |
| --- | --- | --- |
| All APIs | `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`, `JWT_ALGORITHM` | `local-dev-jwt-secret-fixed`, `dev-idp`, `dev-api`, `HS256` |
| Customer SPA | `IDP_LOGIN_URI` / `VITE_IDP_LOGIN_URI` | `http://127.0.0.1:8080/login.html` |
| Customer API | `STRIPE_API_BASE` | `http://mock_stripe_api:12111` |
| Customer API | `STRIPE_SECRET_KEY` | `sk_test_local_dev` |
| Customer API | `STRIPE_WEBHOOK_VERIFY` | `false` |
| Customer API | `COGNITO_ENABLED` | `false` |
| Customer API | `COGNITO_ENDPOINT` | `http://mock_cognito:9229` |
| Customer API | `COGNITO_USER_POOL_ID` | `local_2LcVdLgK` |
| Customer API | `COGNITO_CLIENT_ID` | `34g5holmfkd8emq7v6vldbubg` |
| Customer API | `REGISTRATION_DEV_MODE` | `true` |
| Customer API | `SMTP_HOST` | `mock_mailhog` |
| Customer API | `SMTP_PORT` | `1025` |
| Customer API | `SMTP_FROM` | `noreply@mentorhub.local` |
| Customer API | `SMTP_USER` | *(empty)* |
| Customer API | `SMTP_PASSWORD` | *(empty)* |
| Customer API | `SMTP_STARTTLS` | `false` |
| Admin API | `COGNITO_ENDPOINT` | `http://mock_cognito:9229` |
| Admin API | `COGNITO_USER_POOL_ID` | `local_2LcVdLgK` |
| Admin API | `COGNITO_CLIENT_ID` | `34g5holmfkd8emq7v6vldbubg` |

---

## Testing matrix

| Use case | Local tooling |
| --- | --- |
| Returning customer login | Persona picker → JWT |
| Primary self-reg | Register tab → `/api/dev/register/primary` → JWT |
| Invite member | Join tab → `/api/dev/register/invite` → JWT |
| Primary invites via SPA | F-CA08 with `COGNITO_ENABLED=false` (Profile only, no AdminCreateUser) |
| Update roles / customer_id | Update tab → PATCH claims → re-mint JWT |
| Checkout | stripe-mock + F-CA06 |
| Webhook sync | Fixture POST (`STRIPE_WEBHOOK_VERIFY=false`) |
| Cognito Admin API contract | Unit mocks in `customer_api` tests; optional live calls against `mock_cognito:9229` |
| Invite / app-sent email | MailHog UI at `http://127.0.0.1:8025`; Customer API → `mock_mailhog:1025` |

---

## Implementation tracking

| ID | Repo | Scope |
| --- | --- | --- |
| **F-W10** | `mentorhub` | stripe-mock + cognito-local in compose (done); extend `login.html` / `welcome-auth.js` with four tabs; document env vars |
| **F-CA05** | `customer_api` | `registration_service` + production Post Confirmation callback + dev routes (`REGISTRATION_DEV_MODE`) |
| **F-CA06** | `customer_api` | `STRIPE_API_BASE` override; `STRIPE_WEBHOOK_VERIFY` for dev/e2e |
| **F-CA08** | `customer_api` | When `COGNITO_ENABLED=false`, create Profile only (skip AdminCreateUser) — same service as dev invite |

---

## Anti-patterns

| Anti-pattern | Prefer (locked) |
| --- | --- |
| Require **real AWS Cognito** for daily Developer Edition login | `login.html` + `COGNITO_ENABLED=false`; `mock_cognito` for wire-protocol tests only |
| Use production Stripe keys locally | stripe-mock + optional CLI test mode |
| Dev JWT without `profile_id` / `customer_id` | Always mint full claim set from Profile document |
| Dev registration routes in production | `REGISTRATION_DEV_MODE` — routes not mounted when false |
| Duplicate provisioning logic in login.html | API owns creates; welcome page only mints JWT |

---

## References

- [stripe/stripe-mock](https://github.com/stripe/stripe-mock)
- [mailhog/mailhog](https://hub.docker.com/r/mailhog/mailhog)
- `DeveloperEdition/standards/api_standards.md` — dev JWT
- `DeveloperEdition/standards/spa_standards.md` — `IDP_LOGIN_URI`
- `Research/cognito.md` — production onboarding
