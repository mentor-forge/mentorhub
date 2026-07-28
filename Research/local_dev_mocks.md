# Local Development — Cognito & Stripe Mocks

**Context:** Production uses **AWS Cognito** (Hosted UI + Admin API) and **Stripe** (Checkout, Portal, webhooks). Developer Edition must support local work **without AWS or Stripe accounts** for:

- **Returning users** — SPA login with JWT claims (existing `login.html`)
- **New primary user** — self-registration → new Customer + Profile + claims
- **Invited member** — new Profile under inviter’s `customer_id` + claims
- **Update user** — role / `customer_id` / attribute changes reflected in JWT
- **Subscribe / billing** — Checkout Session, webhooks, Portal (F-CA06+)

**Related:** `Research/cognito.md`, `Research/stripe_research.md`, `DeveloperEdition/docker-compose.yaml`, `login.html`, `welcome-auth.js`.

---

## Locked decisions (2026-07-28)

These choices prioritize **best practice for local dev** (real API + MongoDB paths, no cloud credentials) with **minimal moving parts** (no extra IdP containers, no Lambda in compose).

| # | Decision | Rationale |
| --- | --- | --- |
| **L1** | **Extend `login.html` / `welcome-auth.js` only** for Cognito-shaped flows locally | Matches today’s dev IdP; SPAs keep `IDP_LOGIN_URI` → welcome page; no Hosted UI locally |
| **L2** | **`COGNITO_ENABLED=false`** in Developer Edition | Customer API skips boto3 Admin calls; MongoDB Profile/Customer is source of truth locally |
| **L3** | **Shared registration service** — production Post Confirmation callback and dev routes call the same functions | One code path for E1/E4 provisioning; dev does not fork business logic |
| **L4** | **Dev-only HTTP routes** on Customer API, guarded by **`REGISTRATION_DEV_MODE=true`** | Routes are not mounted in production (404). Never ship dev mode to prod stacks |
| **L5** | **No cognito-local, LocalStack, or Cognito container** for MVP local dev | Admin API contract tests use unit mocks; optional cognito-local is a **future** follow-on only if boto3 integration tests justify it |
| **L6** | **No Post Confirmation Lambda in compose** | `login.html` → dev register route → same service as F-CA05 production callback |
| **L7** | **`stripe-mock`** in compose for Stripe API calls | Official stub; `STRIPE_API_BASE` points at container |
| **L8** | **Webhook testing:** fixture POST in e2e + **`STRIPE_WEBHOOK_VERIFY=false`** in dev; Stripe CLI on host optional for manual test-mode runs | No `stripe listen` service in compose; daily dev does not need Stripe CLI |
| **L9** | **JWT unchanged:** HS256 minted client-side after API returns claims — `JWT_SECRET=local-dev-jwt-secret-fixed`, `iss: dev-idp`, `aud: dev-api` | Aligns with `DeveloperEdition/standards/api_standards.md` |

**Explicitly not doing locally (MVP):** Cognito Hosted UI, real Cognito Admin API, production Stripe keys, webhook signature verification in automated dev/e2e (still required in prod).

---

## Architecture (local vs production)

| Concern | Production | Local dev (locked) |
| --- | --- | --- |
| SPA sign-in UX | Cognito Hosted UI | **`login.html`** — tabs: Sign in, Register org, Join invite, Update claims |
| JWT validation | Cognito-issued (RS256/JWKS or configured) | HS256 minted by welcome page after API returns Profile claims |
| Primary self-reg | Hosted UI → Post Confirmation Lambda → F-CA05 | Register tab → **`POST /api/dev/register/primary`** → mint JWT |
| Invited member | F-CA08 AdminCreateUser + invite email | Join tab → **`POST /api/dev/register/invite`** → mint JWT (simulates invitee first login) |
| Update claims | AdminUpdateUserAttributes + Pre Token Gen | Update tab → **`PATCH /api/dev/profile/{id}/claims`** → re-mint JWT |
| Customer API → Cognito | Real `cognito-idp` when `COGNITO_ENABLED=true` | **Skipped** — no boto3 calls |
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

## Cognito mock — welcome dev IdP (locked)

Production Cognito involves Hosted UI, Admin API, and Post Confirmation Lambda. Locally we simulate **outcomes** (MongoDB + JWT) via the welcome page and dev API routes — not Cognito wire protocol.

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
| **cognito-local** container | Only if integration tests must exercise boto3 Admin API against a local endpoint without mocks |
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
| Customer API | `REGISTRATION_DEV_MODE` | `true` |

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
| Cognito Admin API contract | Unit mocks in `customer_api` tests — not a local container |

---

## Implementation tracking

| ID | Repo | Scope |
| --- | --- | --- |
| **F-W10** | `mentorhub` | stripe-mock in compose (done); extend `login.html` / `welcome-auth.js` with four tabs; document env vars |
| **F-CA05** | `customer_api` | `registration_service` + production Post Confirmation callback + dev routes (`REGISTRATION_DEV_MODE`) |
| **F-CA06** | `customer_api` | `STRIPE_API_BASE` override; `STRIPE_WEBHOOK_VERIFY` for dev/e2e |
| **F-CA08** | `customer_api` | When `COGNITO_ENABLED=false`, create Profile only (skip AdminCreateUser) — same service as dev invite |

---

## Anti-patterns

| Anti-pattern | Prefer (locked) |
| --- | --- |
| Require AWS Cognito in compose for every developer | Welcome extension + `COGNITO_ENABLED=false` |
| cognito-local “just in case” on day one | Unit mocks; add container only when justified |
| Use production Stripe keys locally | stripe-mock + optional CLI test mode |
| Dev JWT without `profile_id` / `customer_id` | Always mint full claim set from Profile document |
| Dev registration routes in production | `REGISTRATION_DEV_MODE` — routes not mounted when false |
| Duplicate provisioning logic in login.html | API owns creates; welcome page only mints JWT |

---

## References

- [stripe/stripe-mock](https://github.com/stripe/stripe-mock)
- `DeveloperEdition/standards/api_standards.md` — dev JWT
- `DeveloperEdition/standards/spa_standards.md` — `IDP_LOGIN_URI`
- `Research/cognito.md` — production onboarding
