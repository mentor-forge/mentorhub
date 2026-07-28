# Customer Journey Issues

Sources (Mike PR #31 review prompts + research):

- `Workshops/customer_workshop_2.md` (User Journey Reflect — experiences, pages, data)
- `Research/stripe_research.md` (Checkout + Customer Portal + webhooks; anti-patterns)
- `Research/cognito.md` (AWS Cognito — primary self-registration + invitation onboarding; JWT claims)
- `Research/local_dev_mocks.md` (Developer Edition — Cognito & Stripe mocks; extend `login.html`)
- `Workshops/2026-07-21 Mary-Anderson (2).md` (embed subscriptions on Customer; drop Card / Dashboard; Payment webhooks)
- `Workshops/exercise_templates/journey_mapping.md` (Make → Data / API / UI tickets per step group)
- `tasks/_PLANNING.md` (task file layout for each repo)
- Existing code: `mentorhub_customer_api`, `mentorhub_customer_spa` (template CRUD + working AWS Cognito / IdP redirect)
- Schemas (provisional files; runtime configurator is definitive): `mentorhub_mongodb_api/configurator/dictionaries/*.yaml`

**Actor:** Cat the Customer (paying sponsor).

**How to use:** Each Experience has paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md` (assume `_PLANNING.md` / `_ORCHESTRATE.md` already exist from a separate bootstrap ticket). **Do not** reference specific task filenames here; Cursor breaks work into appropriately sized tasks. Locked Product, Subscription, and Discount shapes are below. Prefer delete+create over rename in the configurator. When dropping a collection, delete **Configuration**, **Dictionary**, and **Test Data** (where present).

**Auth:** **AWS Cognito** is the IdP. Login / password / MFA / Hosted UI are Cognito — do **not** file SPA or API tickets for custom login or signup screens. Customer SPA already redirects via `VITE_IDP_LOGIN_URI` / `redirectToIdpLogin`.

**Onboarding:** **Primary user** self-registers via Cognito Hosted UI → Customer API creates a **new Customer** org and **new Profile** (owner) with JWT claims. **Additional members** join only via **invitation** from an authenticated primary user — Profile under the inviter’s `customer_id`, Cognito `AdminCreateUser` invite. See `Research/cognito.md`.

---

## Locked decisions (file issues when ready)

**Product & Subscription shape (locked — Mike):** See [Product & Subscription data shape](#product--subscription-data-shape-locked) below.

**Discount / free encounters (locked — Mike):** See [Discount codes & free encounters](#discount-codes--free-encounters-locked).

**Stripe webhooks:** Event list, JSON shapes, and Payment dictionary fields — research during **F-D22** and **F-CA06** / **F-CA09** implementation; use [Stripe API docs](https://docs.stripe.com/api).

**Stripe API implementation:** **F-CA06** (E2 subscribe + discount codes), **F-CA09** (E5–E7 Portal, renewals, cancel, access gate).

**Cognito infra:** Requirements in `Research/cognito.md`. Implementation **F-S01** in `mentorhub_cloudformation`.

**Local dev mocks (locked — 2026-07-28):** `Research/local_dev_mocks.md` — **F-W10** (`login.html` tabs + stripe-mock in compose); **F-CA05** dev routes (`REGISTRATION_DEV_MODE`); **`COGNITO_ENABLED=false`** locally (no Cognito container); webhook fixtures with **`STRIPE_WEBHOOK_VERIFY=false`**. cognito-local explicitly deferred.

**Task automation (bootstrap before E0):** **F-CA-L001** and **F-CS-L001** — planning agents in each repo create journey `tasks/` files from this document. `_PLANNING.md` / `_ORCHESTRATE.md` are maintained separately; do not edit sibling repos from `mentorhub`.

**Schema rule:** Product, Subscription, and Discount business fields are locked below. Payment dictionary shape is derived in F-D22 from webhook event payloads (see that issue’s Stripe references). Fetch definitive schemas from the running configurator per `tasks/_PLANNING.md` (not YAML as write source of truth).

---

## Product & Subscription data shape (locked)

**Product** dictionary — catalog / plan picker (`GET /plans`):

| Field | Role |
| --- | --- |
| `minimum_members` | Floor for cart `quantity`; invite/seat validation |
| `subscription` | Plan identifier (key/name for the offering) |
| `unit_price` | Display and checkout unit price (server snapshots to `unit_cost` on purchase) |

**Customer `subscriptions[]`** — embedded purchase / entitlement (not the dropped top-level Subscription collection):

| Field | Role |
| --- | --- |
| `mentee_count` | Entitled mentee seats (typically set from cart `quantity` at purchase) |
| `encounters_mo` | Encounters-per-month entitlement (copied from Product or plan rules at purchase) |
| `subscription` | Plan identifier — matches Product.`subscription` |
| `quantity` | Purchased seat quantity (Stripe `line_items.quantity`) |
| `unit_cost` | Unit price at purchase time (snapshot of Product.`unit_price`) |
| `total_cost` | `quantity × unit_cost` (computed at purchase; webhooks refresh if Stripe amount differs) |
| `discount_code` | Redeemed Discount.`code` (empty string if none) |
| `free_encounters_granted` | Copy of Discount.`free_encounters` at checkout (0 if no code) |
| `free_encounters_remaining` | Starts equal to `free_encounters_granted`; decremented as encounters are consumed |

**Integration fields (F-D22 — still required for Stripe sync, not business cart fields):**

| Location | Fields |
| --- | --- |
| **Customer** | `stripe_customer_id` |
| **Customer.subscriptions[]** | `status` (active / past_due / canceled), `stripe_subscription_id`, `stripe_price_id`, `current_period_end` |
| **Product** | `stripe_price_id` — maps catalog row to Stripe Checkout `line_items[].price` |

**Checkout contract (locked):** SPA sends `{ "subscription": "<plan id>", "quantity": N }` or `{ "product_id": "...", "quantity": N }`, optional `"discount_code": "<code>"`; API validates `quantity >= Product.minimum_members`, resolves `stripe_price_id`, applies Discount if present, computes `unit_cost` / `total_cost` and copies free-encounter grant onto `subscriptions[]` on webhook success.

---

## Discount codes & free encounters (locked)

Free trials and sponsored/partner entitlements use **MentorHub discount codes** that grant a fixed number of **free encounters** on the subscription — not Stripe billing coupons. A “2 week trial” for retail customers is ops-defined as a code whose `free_encounters` matches policy (e.g. proportional to `encounters_mo`); partner orgs may use codes in the hundreds.

**Discount** dictionary — redeemable codes (Configuration + Dictionary + Test Data — **F-D22**):

| Field | Type / values | Role |
| --- | --- | --- |
| `code` | string, unique | Redeemable code (API normalizes: trim + uppercase on lookup) |
| `free_encounters` | integer ≥ 0 | Encounters granted when code is applied at checkout |
| `status` | `active` \| `inactive` | Default `active`; inactive codes reject at checkout |
| `description` | string | Ops label (e.g. “Retail 2-week trial”, “Partner ACME 2026”) — not shown on Stripe Checkout |
| `expires_at` | ISO datetime, optional | Reject checkout if now > `expires_at` |
| `max_redemptions` | integer, optional | Global cap; reject when redemption count ≥ cap (null = unlimited) |

**Redemption tracking:** increment a counter on the Discount document (or derive from `subscriptions[].discount_code` counts) on successful subscribe webhook — implement in **F-CA06**. One redemption per `customer_id` per code (default).

**Customer `subscriptions[]`** — discount fields are part of the locked embedded shape (see [Product & Subscription data shape](#product--subscription-data-shape-locked) above). Set on subscribe webhook when a valid code was in checkout metadata; otherwise `discount_code` = `""`, `free_encounters_granted` = 0, `free_encounters_remaining` = 0.

**Checkout:** optional `discount_code` in MentorHub cart → API validates active Discount → pass code in Checkout Session **`metadata`** only (Stripe line-item price unchanged) → on successful subscribe webhook, set grant fields on the new `subscriptions[]` entry.

**Encounter consumption:** decrement `free_encounters_remaining` when an Encounter is created or completed under the customer’s entitlement — implement in Encounter/Mentor API (follow-on ticket; Customer API exposes remaining count on Customer GET).

---

## Stripe Checkout — what we send vs what the user edits (locked)

MentorHub owns the **cart** (plan, quantity, discount code). Stripe Checkout owns **payment** (card entry). User briefly leaves the SPA; success/cancel URLs are UX only — **webhooks** activate entitlement.

### MentorHub SPA → Customer API

```json
{
  "product_id": "<Product._id>",
  "quantity": 5,
  "discount_code": "TRIAL2026"
}
```

(or `"subscription": "<Product.subscription>"` instead of `product_id`). API validates `quantity >= Product.minimum_members` and Discount rules (**F-CA06**).

### Customer API → Stripe (`POST /v1/checkout/sessions`)

| Field | Value | Notes |
| --- | --- | --- |
| `mode` | `subscription` | Recurring billing |
| `line_items[]` | `{ "price": "<Product.stripe_price_id>", "quantity": N }` | Price comes from Stripe Dashboard Price — **not** a client-supplied amount |
| `customer` | existing `Customer.stripe_customer_id` | Or create/link Stripe Customer on first checkout using Profile email |
| `success_url` / `cancel_url` | SPA routes | e.g. `{CUSTOMER_SPA_BASE_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}` |
| `metadata` | `mentorhub_customer_id`, `product_id`, `quantity`, optional `discount_code` | Webhook reconciliation + discount grant |
| `subscription_data.metadata` | same keys as needed | Propagates to Subscription object |

**Not sent to Stripe (MVP):** MentorHub `free_encounters` amount, Stripe `discounts` / `allow_promotion_codes`, custom `unit_price` amounts, trial period overrides (unless added later).

### What the user can edit on Stripe’s hosted Checkout page

| Editable on Stripe | Fixed (set by our Session) |
| --- | --- |
| **Payment method** (card) | **Plan / product** (Price ID) |
| **Email** (if not pre-filled via `customer`) | **Quantity** (no `adjustable_quantity` in MVP) |
| Billing name / address **only if** we enable collection flags later | **Unit price** (defined on Stripe Price) |
| | **MentorHub discount code** (already validated in SPA/API before redirect) |
| | **Stripe promotion codes** (`allow_promotion_codes: false` in MVP) |

**Recommendation (locked):** do **not** enable `line_items[].adjustable_quantity` or `allow_promotion_codes` for v1 — keeps cart authority in MentorHub and avoids Stripe-side price changes that bypass Discount validation.

**After payment:** Stripe webhooks update `Customer.subscriptions[]` (business fields + sync fields + discount grant fields). SPA refetches Customer; do not treat success URL as proof of payment.

---

## Naming (CONTRIBUTING.md)

Format: **`Type-UserLayerNumber: short title`** — **User (journey) then Layer**, then a colon and title (matches existing GitHub issues such as `F-CA03: …`, `F-D16: …`).

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-CA##` | Customer **A**pi | `mentorhub_customer_api` |
| `F-CS##` | Customer **S**pa | `mentorhub_customer_spa` |
| `F-D##` | **D**ata | `mentorhub_mongodb_api` |
| `F-W##` | **W**elcome / mentorhub platform | `mentorhub` |
| `F-S##` | **S**RE (when used) | platform / cloudformation as applicable |

Examples from CONTRIBUTING: `F-RS05` = 5th Mentor SPA; `F-EA04` = 4th Mentee API → therefore **`F-CA05` = 5th Customer API**, **`F-CS05` = 5th Customer SPA**.

### Next numbers (fetched 2026-07-22, open + closed)

| Prefix | Highest seen | Next to assign | Notes |
| --- | --- | --- | --- |
| `F-CA` | `F-CA03` ([customer_api#4](https://github.com/mentor-forge/mentorhub_customer_api/issues/4)) | **F-CA04** | Also open: F-CA01, F-CA02 |
| `F-CS` | `F-CS01` ([customer_spa#3](https://github.com/mentor-forge/mentorhub_customer_spa/issues/3)) | **F-CS02** | |
| `F-D` | `F-D20` | **F-D21** for net-new | Repurpose open #35–#37 as **F-D-E0** (combined drop) |
| `F-W` | `F-W09` | **F-W10** | F-W09 = E0 Coordinator removal; F-W10 = local dev mocks |
| `F-S` | — | **F-S01** | `mentorhub_cloudformation` — Cognito pool |

Provisional numbers below assume filing in the order listed; adjust if issues land out of order.

### Current schema snapshot (dictionaries — refine tickets against these)

| Dictionary | Path | Properties today (summary) |
| --- | --- | --- |
| **Customer** | `configurator/dictionaries/Customer.0.1.0.yaml` | `_id`, `name`, `description`, `created`, `saved`, `status` — add `stripe_customer_id`, `subscriptions[]` per [locked shape](#product--subscription-data-shape-locked) |
| **Product** | *(new — F-D22)* | `minimum_members`, `subscription`, `unit_price`, `stripe_price_id` (+ standard dictionary metadata) |
| **Discount** | *(new — F-D22)* | `code`, `free_encounters`, `status`, `description`, `expires_at`, `max_redemptions` |
| **Profile** | `configurator/dictionaries/Profile.0.1.0.yaml` | `_id`, `name` (IdP username), `status` (`profile_status`), `description`, `full_name`, `email`, `email_verified`, `mentor_id`, `goals`, `interests`, `experience[]`, `created`, `saved`, `customer_id`, `roles` (`user_roles`: mentor/mentee/customer/coordinator/admin) |
| **Encounter** | `configurator/dictionaries/Encounter.0.1.0.yaml` | `_id`, `mentor_id`, `mentee_id`, `date`, `plan_id`, `agenda[]`, `status`, **`transcript`**, **`summary`**, **`tldr`**, `created`, `saved` |
| **Subscription** | `configurator/dictionaries/Subscription.0.1.0.yaml` | Stub: `_id`, `name`, `description`, `created`, `saved`, `status` — **drop** (embed on Customer) |
| **Card** | `configurator/dictionaries/Card.0.1.0.yaml` | Includes **`number`** (PAN), `expiry`, `billing_zip`, … — **drop** (Stripe only) |
| **Dashboard** | `configurator/dictionaries/Dashboard.0.1.0.yaml` | `_id`, `name`, `description`, `created`, `saved`, `status`, `customer_id` — **drop** (no custom dashboards) |

Also drop matching `configurator/configurations/{Card,Subscription,Dashboard}.yaml` and any `configurator/test_data/*` for those collections (Card has `Card.0.1.0.0.json`; Subscription/Dashboard currently have no test_data files).

**GDPR:** Applies to **person PII** on **Profile** (and possibly **Encounter** transcript/summary/tldr). Does **not** apply to Customer org/billing documents. **No** `gdpr_request` (or similar) data property — SPA button + API action only.

---

## Already exists — do **not** file as new work

Reviewed `mentorhub_customer_spa` and `mentorhub_customer_api` (template microservices).

| Capability | Where | Ticket guidance |
| --- | --- | --- |
| AWS Cognito / IdP JWT redirect + guards | SPA: `initAuth.ts`, router `beforeEach` → `redirectToIdpLogin`, `VITE_IDP_LOGIN_URI`; 401 → re-login; Logout → IdP | **Sufficient** — no login/signup screen tickets |
| Bearer JWT on API | `api_utils` token helper; claims include `profile_id` (required), `customer_id`, `mentor_id`, `roles` | **Sufficient** plumbing; still need **provisioning** that *sets* those claims (E1) |
| Generic Customer GET list/by-id | API + SPA scaffolding | Keep as base; rewrite for JWT `customer_id` + future `subscriptions[]` |
| Generic Profile GET | API + SPA scaffolding | Keep as base; add **primary self-registration** callback endpoint for Cognito trigger (E1) |
| Stripe Checkout / Portal / webhooks | **None** | Net-new tickets |
| Shopping cart / fixed Customer home / invites / GDPR UI button | **None** | Net-new tickets |

Legacy **CRUD scaffolding to remove** (not extend): Card, Dashboard, standalone Subscription list/new/edit; likely Event/Journey/Rating/Note template pages unless a journey screen needs them. Default SPA home today is `/subscriptions` — change after cleanup.

---

## Design principles

| Assumption | Prefer |
| --- | --- |
| Custom SPA/API login or signup screens | **AWS Cognito** Hosted UI / existing SPA IdP redirect only |
| Cognito Hosted UI self-signup alone sets MentorHub claims | **Post Confirmation trigger → Customer API** creates **new Customer + Profile**, then sets Cognito custom attributes (`profile_id`, `customer_id`, `mentor_id`, `roles`). See `Research/cognito.md` Path A |
| Additional org members self-register publicly | **Invitation only** — authenticated primary user invites; **AdminCreateUser** under inviter’s `customer_id`. See `Research/cognito.md` Path B |
| MentorHub card forms | **Stripe Checkout** only; drop `Card` |
| Customer API charges renewals | **Stripe Billing**; MentorHub receives **webhooks** only |
| Success URL = paid | Webhooks update `Customer.subscriptions[]`; SPA **refetches** |
| Cancel primarily via MentorHub→Stripe API | Prefer **Customer Portal** + webhooks; direct Stripe cancel for **GDPR** offboard |
| Configurable Dashboard collection | **Fixed** Customer home (SPA aggregation); **drop Dashboard** |
| Standalone Subscription collection | Embed **`subscriptions[]` on Customer**; drop top-level Subscription |
| GDPR request field on Customer/Profile | **No data property** — Privacy UI button + API redact action only |
| Keep Coordinator microservice | **Remove** Coordinator API + SPA (Mike) |

---

## Serialized journey (refined)

```text
0. Cleanup first: strip legacy SPA nav/pages + API endpoints; drop Card / Subscription / Dashboard
   (Configuration + Dictionary + Test Data); remove Coordinator API+SPA from platform

1. Primary user (prospect) self-registers on Cognito Hosted UI (sign-up + confirm)
2. Post Confirmation trigger → Customer API: create new Customer org + new Profile (owner)
   with roles ["customer"], mentor_id ""; set Cognito custom attributes — idempotent on sub/email
3. Primary user opens Customer SPA → existing auth guards → Cognito login → JWT has claims
4. Builds shopping cart (offering + capacity + optional discount code for free encounters)
5. Checkout → POST /billing/checkout-session (optional discount_code) → Stripe Checkout
6. Stripe → POST /webhooks/stripe → Payment doc + Customer.subscriptions[] (+ free_encounters_* if discount applied)
7. Return URL → SPA refetches Customer (do not invent paid from URL)
8. Fixed Customer home (roster/activity); CTA Choose a plan if unsubscribed
9. Primary user invites additional members (name + email) → Profile under own customer_id;
   Cognito AdminCreateUser invite — invitees do NOT use public self-sign-up
10. Manages billing / capacity via Portal and/or Checkout; webhooks sync
11. Stripe renews (Stripe internals) → same webhook endpoint (invoice.paid | payment_failed)
12. Cancels in Customer Portal → webhook → canceled
13. GDPR forget → SPA Privacy button → API cancels Stripe if needed → redact Profile/Encounter PII
    (no GDPR data property on Customer or Profile)
```

---

## Experience map (cleanup first)

| # | Experience | Intent | Suggested IDs (start) |
| --- | --- | --- | --- |
| **E0** | **Cleanup first** | Remove legacy nav/endpoints/collections + Coordinator microservice | F-CS02, F-CA04, F-D-E0, F-W09 |
| E1 | Primary self-registration (Hosted UI → new Customer + Profile → JWT claims) | First org owner via Cognito sign-up + API callback | F-D21, F-CA05, F-CS03, F-S01 |
| E2 | First subscription (cart → Checkout → webhook) | First paid entitlement; optional discount code | F-D22, F-CA06, F-CS04 |
| E3 | View fixed Customer home | Roster/activity gated on subscription | … |
| E4 | Invite members (primary user → AdminCreateUser under own customer_id) | Additional org members; no public self-sign-up for invitees | F-D24, F-CA08, F-CS06 |
| E5 | Change subscription | Capacity + Portal | F-D-E5E7, F-CA09, F-CS07 |
| E6 | Recurring charge | Renewal webhooks + past_due banner | *(in F-CA09 / F-CS07)* |
| E7 | Cancel subscription | Portal + webhook sync | *(in F-CA09 / F-CS07)* |
| E8 | GDPR forget | SPA button + API redact Profile/Encounter PII (no data property) | F-CA12, F-CS10 only |

---

## Framework bootstrap (before E0)

Planning agents in Customer API and Customer SPA repos create journey task files from this document. **`_PLANNING.md` and `_ORCHESTRATE.md` already exist** in each repo (separate bootstrap ticket) — do not redefine them here.

### Issue text — API (`F-CA-L001`)

```text
Title: F-CA-L001: Customer API — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
First planning pass for Customer API journey work (E0 onward). Read issue text in
mentorhub/Workshops/customer_journey_issues.md and create appropriately scoped task files
under tasks/ — Cursor decides task breakdown.

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo (separate ticket).
Blocks: F-CA04 and later F-CA* feature issues.
```

### Issue text — SPA (`F-CS-L001`)

```text
Title: F-CS-L001: Customer SPA — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
First planning pass for Customer SPA journey work (E0 onward). Read issue text in
mentorhub/Workshops/customer_journey_issues.md and create appropriately scoped task files
under tasks/ — Cursor decides task breakdown.

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo (separate ticket).
Blocks: F-CS02 and later F-CS* feature issues.
```

---

## E0 — Cleanup first (do before most feature tickets)

### Actions

1. **SPA:** Remove legacy nav and pages (Subscriptions CRUD, Dashboards CRUD, Cards CRUD; trim Event/Journey/Rating/Note template noise unless retained on purpose). Keep AWS Cognito IdP redirect guards, Admin (role-gated), Logout. Set a temporary home route until E3.
2. **API:** Remove OpenAPI/routes/services/tests for `/api/card`, `/api/dashboard`, `/api/subscription` (standalone CRUD). Keep `/api/customer` and `/api/profile` reads as starting points.
3. **Data:** For each dropped collection — delete **Configuration**, **Dictionary**, and **Test Data** (where present).
4. **Platform:** Remove **Coordinator API + SPA**.

### Issue text — SPA (`F-CS02`)

```text
Title: F-CS02: E0 Customer SPA cleanup — remove legacy template CRUD

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Remove template CRUD that conflicts with the Customer billing journey. Keep Cognito IdP
redirect guards; do not build login/signup screens.

Goals:
- Remove Cards, Dashboards, standalone Subscriptions CRUD (routes, pages, nav, API clients, Cypress).
- Trim or hide Event/Journey/Rating/Note template scaffolding unless retained deliberately.
- Keep Admin (admin role), Logout, existing initAuth / VITE_IDP_LOGIN_URI flow.
- Placeholder home until E3 (F-CS05).

Depends on: F-CS-L001 planning pass optional if tasks/ empty.
Context: Workshops/customer_journey_issues.md E0
```

### Issue text — API (`F-CA04`)

```text
Title: F-CA04: E0 Customer API cleanup — remove doomed collection endpoints

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Delete Card, Dashboard, and standalone Subscription API surface before Stripe/billing work.

Goals:
- Remove /api/card, /api/dashboard, /api/subscription (OpenAPI, routes, services, tests).
- Keep /api/customer and /api/profile GET as bases for later journeys.
- No Stripe, no custom auth endpoints.

Depends on: F-CA-L001 planning pass optional if tasks/ empty.
Context: Workshops/customer_journey_issues.md E0
```

### Issue text — Data (`F-D-E0`)

```text
Title: F-D-E0: E0 Drop Card, Dashboard, and top-level Subscription collections

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Remove legacy collections superseded by Stripe (Card) or SPA aggregation (Dashboard) or
Customer.subscriptions[] (Subscription). Repurpose / close GitHub issues #35–#37 if open.

Goals:
- Delete Configuration, Dictionary, and Test Data for Card, Dashboard, Subscription.
- Prefer delete+create over rename; confirm via running configurator.
- Coordinate with F-D21/F-D22 so environments stay usable when subscriptions[] is added later.

Context: Workshops/customer_journey_issues.md E0; Research/stripe_research.md
```

### Issue text — Welcome / platform (`F-W09`)

```text
Title: F-W09: E0 Remove Coordinator microservice (API + SPA)

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub

Description:
Remove Coordinator API and SPA from Developer Edition and platform docs.

Goals:
- Strip welcome page, docker-compose, and workspace references to coordinator_api/spa.
- Confirm GitHub disposition of coordinator repos with Mike.
- Customer SPA/API remain; Cognito stays IdP for Customer.

Context: Workshops/customer_journey_issues.md E0
```

---

## E1 — Primary self-registration (Hosted UI → new Customer + Profile → JWT claims)

### Actions

1. **Prospect** self-registers on **Cognito Hosted UI** (sign-up + email confirm). No SPA registration UI.
2. **Post Confirmation** Lambda (service credential) calls Customer API to create a **new Customer** org and **new Profile** (owner): `roles: ["customer"]`, `mentor_id: ""`, then sets Cognito `custom:*` attributes.
3. **Pre Token Generation** Lambda maps attributes → JWT claims (`profile_id`, `customer_id`, `mentor_id`, `roles`).
4. Primary user opens Customer SPA; **existing** IdP redirect → login → JWT has claims.

**Prerequisites (infra — one-time per environment):** User pool with custom attribute schema, Hosted UI sign-up enabled, Post Confirmation + Pre Token Generation Lambdas, IAM, service credential. See `Research/cognito.md` P1–P9 and **F-S01**.

### Issue text — CloudFormation / SRE (`F-S01`)

```text
Title: F-S01: E1 AWS Cognito user pool for Customer onboarding

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_cloudformation

Description:
Deploy Cognito for E1 primary self-registration and E4 member invites. Requirements:
mentorhub/Research/cognito.md P1–P9. Replaces templates/dev/cognito.yaml placeholder.

Goals:
- User pool with custom attributes (profile_id, customer_id, mentor_id, roles).
- Hosted UI sign-up for primary users; app client URLs match Customer SPA.
- Pre Token Generation + Post Confirmation Lambdas (Post Confirmation calls Customer API F-CA05).
- IAM for Customer API Admin API on this pool; stack outputs for SPA/API env.

Depends on: dev compute platform (ECS roles).
Context: Research/cognito.md; Workshops/customer_journey_issues.md E1 / E4
```

### Issue text — Data (`F-D21`)

```text
Title: F-D21: E1 Customer and Profile schema for primary self-registration

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Schema and test data for Cognito Hosted UI primary registration — new Customer org + owner
Profile per sign-up. No Card; no GDPR request fields on Customer.

Goals:
- Extend Customer / confirm Profile for sign-up + Cognito custom attributes (F-S01).
- Seed primary-owner Customer + Profile pair for integration tests.
- Definitive schemas from running configurator only.

Depends on: F-D-E0 coordinated if subscriptions[] added in same window.
Context: Workshops/customer_journey_issues.md E1; Research/cognito.md Path A
```

### Issue text — API (`F-CA05`)

```text
Title: F-CA05: E1 Primary registration — Post Confirmation callback and local dev provisioning

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Provision new Customer + Profile on primary self-registration. Production: Post Confirmation
Lambda → service-authenticated callback. Local dev: dev routes when REGISTRATION_DEV_MODE
(see Research/local_dev_mocks.md). Shared registration logic for E4 invites.

Goals:
- Create Customer + Profile (owner); sync Cognito custom attributes when COGNITO_ENABLED.
- Idempotent on Cognito sub/email; no login/password/MFA APIs.
- Dev provisioning paths for Developer Edition (F-W10 login.html).

Depends on: F-D21; F-S01 for production Cognito.
Context: Research/cognito.md; Research/local_dev_mocks.md; Workshops/customer_journey_issues.md E1
```

### Issue text — SPA (`F-CS03`)

```text
Title: F-CS03: E1 Post-auth landing for self-registered primary users

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
After Cognito login (or local dev register tab), load Customer/Profile from JWT claims.
No SPA registration UI.

Goals:
- Post-IdP landing with empty-subscription CTA toward E2 cart.
- Handle provisioning lag (missing claims) with retry — do not invent signup.
- Keep existing Cognito auth guards unchanged.

Depends on: E0 cleanup; F-CA05.
Context: Workshops/customer_journey_issues.md E1; Research/cognito.md
```

---

## E2 — First subscription (cart → Checkout → webhook)

### Actions

1. Builds **shopping cart** — offering, capacity/quantity, optional **discount code** (free encounters).
2. Checkout → Customer API validates discount, creates Stripe Checkout Session → browser to Stripe.
3. Stripe → `POST /webhooks/stripe` → persist Payment + update `Customer.subscriptions[]` (including `free_encounters_granted` / `free_encounters_remaining` when code applied).
4. Return success/cancel URL → SPA refetches (never invent Active from URL).

### Issue text — Data (`F-D22`)

```text
Title: F-D22: E2 Catalog, Payment, Discount, and Customer.subscriptions[] for Checkout

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Data layer for first subscribe: Product catalog, Payment webhooks, Discount codes, embedded
subscriptions[] on Customer. Locked shapes in customer_journey_issues.md.

Goals:
- Customer: stripe_customer_id, subscriptions[] (business + Stripe sync + discount fields).
- Product dictionary; Discount dictionary (code, free_encounters, status, description,
  expires_at, max_redemptions); Payment dictionary (derive fields from Stripe webhook payloads).
- Seed Products, Discounts, unsubscribed and active Customers.
- Use running configurator; prefer delete+create over rename.

Depends on: F-D-E0.
Context: Workshops/customer_journey_issues.md E2 — Product, Discount, and Subscription shapes
```

### Issue text — API (`F-CA06`)

```text
Title: F-CA06: E2 Stripe subscribe — Checkout, webhooks, and discount codes

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
First paid subscription via Stripe Checkout. Includes MentorHub discount codes (free encounters,
not Stripe coupons). See locked Checkout contract and Stripe Checkout section in journey doc.

Goals:
- GET /plans; POST /billing/checkout-session; POST /webhooks/stripe (subscribe events).
- Validate discount codes; grant free_encounters on subscriptions[] via webhook metadata.
- Persist Payment; sync Customer.subscriptions[]; never trust success URL as paid.
- Local dev: stripe-mock + STRIPE_WEBHOOK_VERIFY=false per Research/local_dev_mocks.md.

Depends on: F-D22.
Context: Workshops/customer_journey_issues.md E2; Research/stripe_research.md (background)
```

### Issue text — SPA (`F-CS04`)

```text
Title: F-CS04: E2 Plans, cart, Checkout redirect, success/cancel

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Shopping cart and Stripe redirect — not auth UI.

Goals:
- Plan picker, quantity, optional discount code, Checkout CTA.
- Redirect to Stripe; success/cancel flows refetch Customer (webhooks activate entitlement).
- No card forms or Stripe secrets in SPA.

Depends on: F-CA06; E0 cleanup.
Context: Workshops/customer_journey_issues.md E2
```

---

## E3 — View fixed Customer home

### Actions

1. Lands on fixed Customer home (not Dashboard collection — dropped in F-D-E0).
2. Unsubscribed → Choose a plan (E2). Subscribed → mentee roster/activity via `Profile.customer_id`.
3. Gate premium views on API subscription status.

### Issue text — Data (`F-D23`)

```text
Title: F-D23: E3 Test data for fixed Customer home

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Seed data for Customer home roster/activity using Profile.customer_id — no Dashboard collection.

Goals:
- Customer → Profiles → enough Encounter/Event activity for list and empty states.

Context: Workshops/customer_journey_issues.md E3
```

### Issue text — API (`F-CA07`)

```text
Title: F-CA07: E3 Customer home aggregates and subscription gate

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Read APIs for fixed Customer home; gate premium routes on subscription status.

Goals:
- subscriptions[] on Customer GET for CTA vs roster.
- Mentee activity aggregate for JWT customer_id; 403 when active sub required.

Context: Workshops/customer_journey_issues.md E3
```

### Issue text — SPA (`F-CS05`)

```text
Title: F-CS05: E3 Fixed Customer home and mentee activity

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Default home after E0 — Choose a plan vs roster gated on API subscription state.

Goals:
- Home page wired to F-CA07; no Dashboard CRUD.

Depends on: F-CA07; E0 cleanup.
Context: Workshops/customer_journey_issues.md E3
```

---

## E4 — Invite members (primary user → members under same customer_id)

### Actions

1. **Authenticated primary user** (JWT `customer_id` set) opens Invite Members page.
2. Submits **name + email**; API creates Profile under **inviter’s `customer_id`**, `roles: ["customer"]`, `mentor_id: ""`, then **AdminCreateUser** with Cognito invite email.
3. Invitee completes password on Hosted UI — **must not** use public self-sign-up (would create a new Customer via E1).
4. Lists pending/accepted/revoked invites; optional seat check against `Customer.subscriptions[]`.

### Issue text — Data (`F-D24`)

```text
Title: F-D24: E4 Member invite persistence

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Persist invites from authenticated primary user before invitee accepts (embed on Customer or
small Invite collection).

Goals:
- pending / accepted / revoked invites tied to inviter customer_id.
- No GDPR request property.

Depends on: F-D21.
Context: Workshops/customer_journey_issues.md E4; Research/cognito.md Path B
```

### Issue text — API (`F-CA08`)

```text
Title: F-CA08: E4 Invite members — Cognito AdminCreateUser under inviter customer_id

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Primary user invites org members by name + email. Profile under inviter customer_id;
AdminCreateUser in prod; dev path per local_dev_mocks.md when COGNITO_ENABLED=false.

Goals:
- POST invite, GET list, optional revoke; idempotent re-invite.
- Reject emails already bound to another customer; optional seat/capacity check.

Depends on: F-D24; F-CA05; F-S01.
Context: Workshops/customer_journey_issues.md E4; Research/cognito.md Path B
```

### Issue text — SPA (`F-CS06`)

```text
Title: F-CS06: E4 Invite Members page

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
UI for primary user to invite members; invitee onboarding via Cognito email only.

Goals:
- Invite form, pending list, capacity errors from API.
- Gate on customer_id claim; no public self-sign-up for invitees.

Depends on: F-CA08.
Context: Workshops/customer_journey_issues.md E4
```

---

## E5–E7 — Billing lifecycle (change, renew, cancel)

### Actions

**E5 — Change subscription:** Subscription / Billing → capacity via Checkout and/or Portal → webhooks sync.

**E6 — Recurring charge:** Stripe renews; same webhook endpoint (`invoice.paid` / `invoice.payment_failed`) → past_due banner.

**E7 — Cancel:** Customer Portal cancel → webhook → canceled; Resubscribe CTA; API 403 on gated routes.

### Issue text — Data (`F-D-E5E7`)

```text
Title: F-D-E5E7: E5–E7 Billing lifecycle test data

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Test data for capacity changes, renewals (invoice.paid / payment_failed), and canceled subscriptions.

Goals:
- Customers with varied subscriptions[] quantity, status (active, past_due, canceled).
- Payment fixtures supporting invoice webhook shapes.

Depends on: F-D22.
Context: Workshops/customer_journey_issues.md E5 / E6 / E7
```

### Issue text — API (`F-CA09`)

```text
Title: F-CA09: E5–E7 Stripe billing lifecycle — Portal, renewals, cancel, access gate

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Post-subscribe billing: Customer Portal, capacity checkout, renewal webhooks, cancel sync,
and subscription gate on premium routes. Extends F-CA06 webhook router.

Goals:
- Portal session; capacity-change checkout.
- invoice.paid / invoice.payment_failed → past_due; subscription updated/deleted → canceled.
- require_active_subscription on gated routes; honor cancel_at_period_end.

Depends on: F-CA06.
Context: Workshops/customer_journey_issues.md E5–E7; Research/stripe_research.md
```

### Issue text — SPA (`F-CS07`)

```text
Title: F-CS07: E5–E7 Subscription, billing, payment-failed, and cancel UX

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Billing management UI: plan/capacity, Portal redirect, past_due banner, cancel/resubscribe CTA.

Goals:
- Subscription / Billing pages; payment-failed banner from API state.
- Portal entry for manage billing and cancel; refetch after return.

Depends on: F-CA09.
Context: Workshops/customer_journey_issues.md E5–E7
```

---

## E8 — GDPR forget

### Actions

1. **SPA:** Account / Privacy — button to request PII removal (confirm destructive intent).
2. **API:** Cancel remaining Stripe subscriptions for `stripe_customer_id` if needed; **redact/anonymize person PII** on **Profile** and possibly **Encounter**.
3. **Data:** **No new property** (no `gdpr_request` on Customer or Profile). GDPR does **not** apply to Customer org/billing documents; Payment history may retain non-PII financial records per policy.

**Profile PII candidates (Profile.0.1.0.yaml):** `name`, `full_name`, `email`, `email_verified`, `description`, `goals`, `interests`, `experience[]` (company, titles, markdown), breadcrumbs as applicable.

**Encounter PII candidates (Encounter.0.1.0.yaml):** `transcript`, `summary`, `tldr` (and related narrative fields).

### Issue text — Data

**None.** Do not file an F-D ticket to add a GDPR request flag or status field. Redaction targets existing Profile / Encounter properties only.

### Issue text — API (`F-CA12`)

```text
Title: F-CA12: E8 Privacy action — cancel Stripe and redact Profile/Encounter PII

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Forget flow for authenticated Customer: cancel Stripe if needed; redact person PII on Profile
and Encounter. No gdpr_* data property.

Goals:
- Privacy API action callable from SPA; optional Cognito AdminDeleteUser.
- Document Payment retention vs person PII.

Context: Workshops/customer_journey_issues.md E8
```

### Issue text — SPA (`F-CS10`)

```text
Title: F-CS10: E8 Account Privacy — PII removal button

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Destructive confirm → call F-CA12 → show outcome. Not a Customer commerce editor.

Depends on: F-CA12.
Context: Workshops/customer_journey_issues.md E8
```

---

## Suggested implementation order

1. **Framework** — **F-CA-L001** + **F-CS-L001** (planning pass in each repo).
2. **E0** — F-CS02, F-CA04, F-D-E0, F-W09.
3. **E1** — F-D21, F-CA05, F-W10, F-CS03; F-S01 in parallel for prod Cognito.
4. **E2** — F-D22, F-CA06, F-CS04.
5. **E3** — F-D23, F-CA07, F-CS05.
6. **E4** — F-D24, F-CA08, F-CS06.
7. **E5–E7** — F-D-E5E7, F-CA09, F-CS07.
8. **E8** — F-CA12, F-CS10.

Each issue instructs a planning agent to create `tasks/` files via `_PLANNING.md` — do not pre-specify task filenames in GitHub issues.

---

## F-W10 — Local dev: Cognito & Stripe mocks (locked)

### Actions

1. **stripe-mock** in `DeveloperEdition/docker-compose.yaml` — done; env vars documented (L7–L8).
2. **Keep** `login.html` persona picker for returning users.
3. **Add tabs** on welcome dev IdP: Register organization, Join as invited member, Update profile claims.
4. **Coordinate F-CA05** — dev routes call same `registration_service`; welcome page mints JWT after API response.
5. **No cognito-local** for MVP (deferred per `Research/local_dev_mocks.md`).

### Issue text — Welcome / platform (`F-W10`)

```text
Title: F-W10: Local dev — Stripe mock and login.html register, invite, update

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub

Description:
Developer Edition without AWS/Stripe credentials. Locked design: Research/local_dev_mocks.md.

Goals:
- stripe-mock in compose; customer_api dev env vars (see local_dev_mocks.md).
- login.html tabs: register org, join invite, update claims (mint JWT after Customer API).
- No cognito-local or Hosted UI locally.

Depends on: F-CA05 dev provisioning (customer_api repo).
Context: Research/local_dev_mocks.md; E1, E4, E2
```

---

## Explicitly out of scope

- SPA/API tickets for login, signup, password reset, or MFA screens (**AWS Cognito** Hosted UI owns auth UI — including primary self-sign-up)
- New SPA ticket to rewire IdP/JWT redirect guards (already implemented)
- Cognito Hosted UI self-sign-up **without** Post Confirmation → Customer API callback (claims would be missing)
- Public self-sign-up for **invited** members (E4 uses AdminCreateUser invite only)
- Squarespace / Google Sheet / external form registration pipelines
- Any **GDPR / privacy request data property** on Customer, Profile, or elsewhere
- Treating **Customer** org/billing documents as GDPR person-PII erase targets (Profile ± Encounter only)
- Keeping Coordinator API/SPA
- Configurable Dashboard collection / custom dashboards
- Storing card PANs; MentorHub-initiated recurring charges
- Stripe Coupon/Promotion codes for price discounts (MVP uses MentorHub Discount for free encounters only)
- Mentee “pick up studies” and non-Customer tooling
- Live Stripe round-trip on every home page paint
- Requiring real AWS Cognito or Stripe credentials for Developer Edition (F-W10 mocks; cognito-local out of scope for MVP)
