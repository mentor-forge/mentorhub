# Customer Journey Issues

Sources (Mike PR #31 review prompts + research):

- `Workshops/customer_workshop_2.md` (User Journey Reflect — experiences, pages, data)
- `Research/stripe_research.md` (Checkout + Customer Portal + webhooks; anti-patterns)
- `Research/cognito.md` (AWS Cognito — primary self-registration + invitation onboarding; JWT claims)
- `Workshops/2026-07-21 Mary-Anderson (2).md` (embed subscriptions on Customer; drop Card / Dashboard; Payment webhooks)
- `Workshops/exercise_templates/journey_mapping.md` (Make → Data / API / UI tickets per step group)
- `tasks/_PLANNING.md` (task file layout for each repo)
- Existing code: `mentorhub_customer_api`, `mentorhub_customer_spa` (template CRUD + working AWS Cognito / IdP redirect)
- Schemas (provisional files; runtime configurator is definitive): `mentorhub_mongodb_api/configurator/dictionaries/*.yaml`

**Actor:** Cat the Customer (paying sponsor).

**How to use:** Each Experience has paste-ready **Issue text** for that repo’s local `tasks/_PLANNING.md`. Complete **Do This First** before filing GitHub issues. Prefer delete+create over rename in the configurator. When dropping a collection, delete **Configuration**, **Dictionary**, and **Test Data** (where present).

**Auth:** **AWS Cognito** is the IdP. Login / password / MFA / Hosted UI are Cognito — do **not** file SPA or API tickets for custom login or signup screens. Customer SPA already redirects via `VITE_IDP_LOGIN_URI` / `redirectToIdpLogin`.

**Onboarding:** **Primary user** self-registers via Cognito Hosted UI → Customer API creates a **new Customer** org and **new Profile** (owner) with JWT claims. **Additional members** join only via **invitation** from an authenticated primary user — Profile under the inviter’s `customer_id`, Cognito `AdminCreateUser` invite. See `Research/cognito.md`.

---

## Do This First

Complete these before finalizing ticket text and creating GitHub issues. Research lives in `mentorhub/Research/`.

| # | Research / decision | Why it blocks filing | Owner / notes |
| --- | --- | --- | --- |
| R1 | **Stripe webhook event list + JSON shapes** — at least checkout completed, subscription lifecycle, `invoice.paid` / `invoice.payment_failed` | Blocks Payment collection schema + webhook test fixtures | F-CA06/F-CA10 handlers; F-D22 Payment dictionary |
| R2 | **Misnamed umbrella issues** — mentorhub [#38](https://github.com/mentor-forge/mentorhub/issues/38) `F-UC` and [#39](https://github.com/mentor-forge/mentorhub/issues/39) `F-AC` reverse journey/layer | Rename or close/supersede when filing real `F-CS*` / `F-CA*` issues | CONTRIBUTING: `F-CA` = Customer API, `F-CS` = Customer SPA |

**Product & Subscription shape (locked — Mike):** See [Product & Subscription data shape](#product--subscription-data-shape-locked) below.

**Discount / free encounters (locked — Mike):** See [Discount codes & free encounters](#discount-codes--free-encounters-locked). Replaces Do This First free-trial rules ([#36](https://github.com/mentor-forge/mentorhub/issues/36) — encounter-grant model supersedes time-only trial research).

**Stripe API implementation:** `mentorhub_customer_api/tasks/PENDING.F-CA06` (foundation), `F-CA09`, `F-CA10`, `F-CA11`.

**Cognito infra (was Do This First):** Requirements are in `Research/cognito.md`. Implementation is **F-S01** in `mentorhub_cloudformation` — task `tasks/PENDING.R071.dev_cognito_customer_onboarding.md`. File that issue before E1 API/SPA work; E1 tickets depend on F-S01, not open research.

**Schema rule:** Product and Subscription business fields are locked below. Payment dictionary still follows R1 webhook research. Fetch definitive schemas from the running configurator per `tasks/_PLANNING.md` (not YAML as write source of truth).

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
| `discount_code` | Redeemed Discount.`code` (empty if none) |
| `free_encounters_granted` | Copy of Discount.`free_encounters` at checkout |
| `free_encounters_remaining` | Countdown as encounters are consumed under this subscription |

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

**Discount** dictionary — redeemable codes (Configuration + Dictionary + Test Data — **F-D28**):

| Field | Role |
| --- | --- |
| `code` | Unique redeemable string (case-normalize on lookup) |
| `free_encounters` | Number of encounters granted when code is applied at checkout |

**Optional fields (decide in F-D28 / F-CA13 — defaults in issue text):** `status`, `description`, `expires_at`, `max_redemptions`.

**Customer `subscriptions[]`** — add when a discount is applied at checkout:

| Field | Role |
| --- | --- |
| `discount_code` | Code redeemed (empty if none) |
| `free_encounters_granted` | Copy of Discount.`free_encounters` at redemption |
| `free_encounters_remaining` | Decremented when a billable encounter is consumed under this subscription |

**Checkout:** optional `discount_code` in cart → API validates active Discount → on successful subscribe webhook, set grant fields on the new `subscriptions[]` entry. **Stripe price is unchanged** unless a separate Stripe coupon is added later; this model grants encounter entitlement only.

**Encounter consumption:** decrement `free_encounters_remaining` when an Encounter is created or completed under the customer’s entitlement — implement in Encounter/Mentor API (follow-on ticket; Customer API exposes remaining count on Customer GET).

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
| `F-D` | `F-D20` | **F-D21** for net-new | Open after F-W02: [F-D14 Subscription](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/35), [F-D15 Dashboard](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/36), [F-D16 Card](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/37) — **repurpose these for cleanup drops**, do not invent parallel drop tickets |
| `F-W` | `F-W08` | **F-W09** | |
| `F-S` | — | **F-S01** | `mentorhub_cloudformation` — Cognito pool (R071) |

Provisional numbers below assume filing in the order listed; adjust if issues land out of order.

### Current schema snapshot (dictionaries — refine tickets against these)

| Dictionary | Path | Properties today (summary) |
| --- | --- | --- |
| **Customer** | `configurator/dictionaries/Customer.0.1.0.yaml` | `_id`, `name`, `description`, `created`, `saved`, `status` — add `stripe_customer_id`, `subscriptions[]` per [locked shape](#product--subscription-data-shape-locked) |
| **Product** | *(new — F-D22)* | `minimum_members`, `subscription`, `unit_price`, `stripe_price_id` (+ standard dictionary metadata) |
| **Discount** | *(new — F-D28)* | `code`, `free_encounters` (+ optional status, expires_at, max_redemptions) |
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
| **E0** | **Cleanup first** | Remove legacy nav/endpoints/collections + Coordinator microservice | F-CS02, F-CA04, F-D14–16, F-W09 |
| E1 | Primary self-registration (Hosted UI → new Customer + Profile → JWT claims) | First org owner via Cognito sign-up + API callback | F-D21+, F-CA05+, F-CS03+, F-S01+ |
| E2 | First subscription (cart → Checkout → webhook) | First paid entitlement; optional discount code | F-D22+, F-D28+, F-CA06+, F-CA13+, F-CS04+ |
| E3 | View fixed Customer home | Roster/activity gated on subscription | … |
| E4 | Invite members (primary user → AdminCreateUser under own customer_id) | Additional org members; no public self-sign-up for invitees | F-D24+, F-CA08+, F-CS06+ |
| E5 | Change subscription | Capacity + Portal | … |
| E6 | Recurring charge | Renewal webhooks + past_due banner | … |
| E7 | Cancel subscription | Portal + webhook sync | … |
| E8 | GDPR forget | SPA button + API redact Profile/Encounter PII (no data property) | F-CA12, F-CS10 only |

---

## E0 — Cleanup first (do before most feature tickets)

### Actions

1. **SPA:** Remove legacy nav and pages (Subscriptions CRUD, Dashboards CRUD, Cards CRUD; trim Event/Journey/Rating/Note template noise unless retained on purpose). Keep AWS Cognito IdP redirect guards, Admin (role-gated), Logout. Set a temporary home route until E3.
2. **API:** Remove OpenAPI/routes/services/tests for `/api/card`, `/api/dashboard`, `/api/subscription` (standalone CRUD). Keep `/api/customer` and `/api/profile` reads as starting points.
3. **Data:** For each dropped collection — delete **Configuration**, **Dictionary**, and **Test Data** (where present).
4. **Platform:** Remove **Coordinator API + SPA**.

### Issue text — SPA (`F-CS02`)

```text
Title: F-CS02: E0 Customer SPA nav and legacy page cleanup

Description:
Remove template CRUD that conflicts with the Customer billing journey before building new pages.

Goals:
- Remove routes/pages/nav/client methods/Cypress for Cards, Dashboards, and standalone
  Subscriptions list/new/edit (default home must leave /subscriptions).
- Remove or hide Event/Journey/Rating/Note scaffolding unless a later experience needs them.
- Keep existing AWS Cognito IdP auth guards (initAuth, router redirectToIdpLogin,
  VITE_IDP_LOGIN_URI) — do not build or rework login/signup screens.
- Keep Admin (admin role) and Logout.
- Leave a minimal shell / placeholder home until E3 fixed Customer home ships.

Context: Workshops/customer_journey_issues.md E0; mentorhub_customer_spa App.vue + router
```

### Issue text — API (`F-CA04`)

```text
Title: F-CA04: E0 Remove Card, Dashboard, and standalone Subscription API surface

Description:
Delete doomed collection endpoints before Stripe/billing work.

Goals:
- Remove OpenAPI, routes, services, and tests for /api/card, /api/dashboard, /api/subscription.
- Keep /api/customer and /api/profile GET as bases for later journey work.
- Do not add Stripe yet in this ticket (E2+).
- Do not add custom auth/login endpoints — AWS Cognito remains the IdP.

Context: Workshops/customer_journey_issues.md E0; mentorhub_customer_api docs/openapi.yaml
```

### Issue text — Data (repurpose open issues)

```text
Title: F-D16: E0 Drop Card — Configuration, Dictionary, and Test Data
(update existing https://github.com/mentor-forge/mentorhub_mongodb_api/issues/37)

Description:
Remove Card entirely (PCI — cards live only in Stripe).

Current schema (configurator/dictionaries/Card.0.1.0.yaml): stores card number (PAN),
expiry, billing_zip, name, status, breadcrumbs — must not remain in MentorHub.

Goals:
- Delete Card Configuration (configurations/Card.yaml), Dictionary (dictionaries/Card.*.yaml),
  and Test Data (test_data/Card.0.1.0.0.json).
- Prefer delete + create over rename for any replacement collections later.
- Confirm via running configurator after delete.

Context: Workshops/customer_journey_issues.md E0; Research/stripe_research.md
```

```text
Title: F-D15: E0 Drop Dashboard — Configuration, Dictionary, and Test Data
(update existing https://github.com/mentor-forge/mentorhub_mongodb_api/issues/36)

Description:
No custom dashboards; fixed Customer home is SPA aggregation only.

Current schema (configurator/dictionaries/Dashboard.0.1.0.yaml): _id, name, description,
created, saved, status, customer_id — configurable dashboard collection not used for MVP.

Goals:
- Delete Dashboard Configuration (configurations/Dashboard.yaml) and Dictionary
  (dictionaries/Dashboard.0.1.0.yaml). Remove test_data if any is added before drop.
- Do not replace with a new Dashboard dictionary.

Context: Workshops/customer_journey_issues.md E0
```

```text
Title: F-D14: E0 Drop top-level Subscription — Configuration, Dictionary, and Test Data
(update existing https://github.com/mentor-forge/mentorhub_mongodb_api/issues/35)

Description:
Subscriptions move onto Customer.subscriptions[] (E1/E2 Data). Remove standalone collection.

Current schema (configurator/dictionaries/Subscription.0.1.0.yaml): stub only —
_id, name, description, created, saved, status (default_status). No customer_id, seats,
or Stripe ids today.

Goals:
- Delete Subscription Configuration (configurations/Subscription.yaml) and Dictionary
  (dictionaries/Subscription.0.1.0.yaml). Remove test_data if present.
- Coordinate timing with F-D21/F-D22 Customer.subscriptions[] so environments stay usable.
- Do not leave a renamed empty Subscription dictionary.

Context: Workshops/customer_journey_issues.md E0 / E1
```

### Issue text — Welcome / platform (`F-W09`)

```text
Title: F-W09: E0 Remove Coordinator microservice (API + SPA) from MentorHub

Description:
Mike decided Coordinator API and SPA are removed. Strip platform references and retire the services.

Goals:
- Remove welcome/index.html links, welcome-auth.js coordinator personas,
  DeveloperEdition/docker-compose.yaml coordinator_api/spa services and depends_on,
  workspace/docs pointers to those images/repos.
- Archive or delete mentorhub_coordinator_api and mentorhub_coordinator_spa remotes
  (confirm with Mike for exact GitHub disposition).
- Customer SPA/API remain; only Customer role owns subscriptions.
- Do not replace with custom auth screens — AWS Cognito remains IdP for Customer SPA.

Context: Workshops/customer_journey_issues.md E0
```

---

## E1 — Primary self-registration (Hosted UI → new Customer + Profile → JWT claims)

### Actions

1. **Prospect** self-registers on **Cognito Hosted UI** (sign-up + email confirm). No SPA registration UI.
2. **Post Confirmation** Lambda (service credential) calls Customer API to create a **new Customer** org and **new Profile** (owner): `roles: ["customer"]`, `mentor_id: ""`, then sets Cognito `custom:*` attributes.
3. **Pre Token Generation** Lambda maps attributes → JWT claims (`profile_id`, `customer_id`, `mentor_id`, `roles`).
4. Primary user opens Customer SPA; **existing** IdP redirect → login → JWT has claims.

**Prerequisites (infra — one-time per environment):** User pool with custom attribute schema, Hosted UI sign-up enabled, Post Confirmation + Pre Token Generation Lambdas, IAM, service credential. See `Research/cognito.md` P1–P9 and **F-S01** (`mentorhub_cloudformation` task R071).

**Not in this experience:** SPA login/signup screens; public self-sign-up for **invited** members (E4).

### Issue text — CloudFormation / SRE (`F-S01`) — repo `mentorhub_cloudformation`

```text
Title: F-S01: E1 AWS Cognito user pool — custom attributes, Hosted UI, JWT claim Lambdas

Repository: mentor-forge/mentorhub_cloudformation
Task file: tasks/PENDING.R071.dev_cognito_customer_onboarding.md

Description:
One-time per-environment Cognito CloudFormation for Customer onboarding (E1 primary self-reg,
E4 member invites). Replaces templates/dev/cognito.yaml placeholder. Requirements:
mentorhub/Research/cognito.md P1–P9.

Goals:
- User pool with immutable custom attributes: custom:profile_id, custom:customer_id,
  custom:mentor_id, custom:roles.
- App client + Hosted UI: sign-up enabled for primary users; callback/logout URLs match
  Customer SPA (VITE_IDP_LOGIN_URI).
- Cognito domain for Hosted UI.
- Pre Token Generation Lambda (V2 if access token carries claims): maps custom:* → JWT claims.
- Post Confirmation Lambda: service-authenticated call to Customer API F-CA05 callback;
  pass Cognito sub, email, and standard attributes.
- IAM: Customer API ECS task role — AdminCreateUser, AdminUpdateUserAttributes,
  AdminDisableUser, AdminDeleteUser on this pool.
- Service credential in Secrets Manager for trigger → API; document rotation.
- Stack outputs: pool id, client id, Hosted UI URL — for SPA/API env config.

Prerequisites / decisions (lock in PR):
- Email-as-username (default).
- Which token SPA reads for claims — align with customer_spa initAuth; use Pre Token Gen V2
  if access token must carry claims.

Depends on: R060 dev compute platform (ECS roles). Coordinates with F-CA05 callback URL.

Blocks: F-D21, F-CA05, F-CS03 (E1); F-CA08 (E4 invites).

Context: Research/cognito.md; Workshops/customer_journey_issues.md E1 / E4
```

### Issue text — Data (`F-D21`)

```text
Title: F-D21: E1 Extend Customer and Profile for primary self-registration

Description:
Schema + test data for Cognito Hosted UI primary self-registration: new Customer org + new
Profile owner per sign-up (no cards; no GDPR request fields).

Current Customer (Customer.0.1.0.yaml): _id, name, description, created, saved, status only.
Current Profile (Profile.0.1.0.yaml): already has name (IdP username), full_name, email,
email_verified, mentor_id, customer_id, roles (user_roles), plus goals/interests/experience.

Goals:
- Extend Customer only as needed (e.g. stripe_customer_id placeholder; org name from Hosted UI
  or API default). Do not add person-PII or gdpr_* on Customer.
- Confirm Profile covers Hosted UI sign-up fields (email, full_name/name) + Cognito custom
  attributes from F-S01; add only missing attributes.
- Seed at least one primary-owner pair: new Customer + Profile with roles ["customer"],
  customer_id linked, mentor_id empty — for callback + JWT integration tests.
- Definitive schemas from running configurator only.

Prerequisites / decisions:
- Org owner roles default: ["customer"] only (no coordinator on self-reg).
- mentor_id reserved but empty on primary create.
- Customer.name sourced from Hosted UI display name or email local-part if absent.

Depends on: F-S01 pool attribute names must match before production seed.

Coordinate with F-D14 if subscriptions[] lands in same change set.

Context: Workshops/customer_journey_issues.md E1; Research/cognito.md Path A;
configurator/dictionaries/Customer.0.1.0.yaml; Profile.0.1.0.yaml
```

### Issue text — API (`F-CA05`)

```text
Title: F-CA05: E1 Primary self-registration — Cognito Post Confirmation callback

Description:
Service-authenticated endpoint invoked by Post Confirmation Lambda after Hosted UI sign-up.
Creates a new Customer org and new Profile (owner); sets Cognito custom attributes so JWTs
include profile_id, customer_id, mentor_id (empty), roles. Not an end-user or SPA endpoint.

Goals:
- POST primary registration callback (service credential): input Cognito sub, email, name attrs;
  atomically create Customer + Profile; AdminUpdateUserAttributes for custom:profile_id,
  custom:customer_id, custom:mentor_id (""), custom:roles (["customer"]).
- Idempotent on Cognito sub and/or email — Lambda retries must not duplicate org/user.
- On MongoDB failure after Cognito user exists: return 5xx for retry; do not leave user with
  usable API access without profile_id claim.
- Do not implement password reset, MFA, or login APIs — Cognito owns those.
- Document request/response contract for F-S01 Post Confirmation Lambda.

Prerequisites / decisions:
- Requires F-S01 pool + Lambdas deployed in target environment.
- Trigger: Post Confirmation (not Post Authentication) unless load testing proves otherwise.
- customer_id on Profile must equal newly created Customer._id.
- Invited members use F-CA08 (AdminCreateUser) — this endpoint must reject or no-op emails
  that already have a Profile under a different customer (invite path).

Depends on: F-S01; F-D21.

Context: Workshops/customer_journey_issues.md E1; Research/cognito.md Path A;
api_utils JWT claim expectations
```

### Issue text — SPA (`F-CS03`)

```text
Title: F-CS03: E1 Post-auth landing for self-registered primary users

Description:
After Cognito Hosted UI login, SPA loads Customer/Profile for JWT claims. Account is created
by Post Confirmation → F-CA05 during sign-up — no SPA registration flow.

Goals:
- After IdP return (existing redirectToIdpLogin / VITE_IDP_LOGIN_URI), load Customer/Profile
  for JWT claims; empty-subscription CTA toward E2 cart.
- Handle first-login edge case: if claims missing (provisioning lag), show retry/error — do not
  invent local signup.
- Do NOT build registration, login, password-reset, or MFA screens in the SPA.
- Do NOT rework existing AWS Cognito auth guardrail.

Prerequisites:
- F-S01 + F-CA05 working in dev so JWT carries profile_id and customer_id after sign-up.

Depends on: E0 SPA cleanup; F-CA05.

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
Title: F-D22: E2 Product + Payment + Customer.subscriptions[] for Checkout

Description:
Data for first subscribe without storing cards. Product and Subscription business fields are
locked (see customer_journey_issues.md Product & Subscription data shape).

Goals:
- Extend Customer with stripe_customer_id and subscriptions[] embedded objects:
    mentee_count, encounters_mo, subscription, quantity, unit_cost, total_cost
    plus Stripe sync: status, stripe_subscription_id, stripe_price_id, current_period_end.
- Add Product dictionary (Configuration + Dictionary + Test Data):
    minimum_members, subscription, unit_price, stripe_price_id.
- Add Payment dictionary for webhook payloads (Configuration + Dictionary + Test Data).
- Seed unsubscribed vs active Customers with sample subscriptions[] using locked fields;
  seed Products with minimum_members / unit_price; do not reintroduce Card fields.
- Fetch/update via running configurator; prefer delete+create over rename.

Depends on: F-D14 drop complete or same coordinated PR. Payment shape still follows Do This First R1.

Context: Workshops/customer_journey_issues.md E2 / Product & Subscription data shape;
Research/stripe_research.md; configurator/dictionaries/Customer.0.1.0.yaml
```

### Issue text — Data (`F-D28`)

```text
Title: F-D28: E2 Discount dictionary — codes and free encounter grants

Description:
Discount codes for free trials and sponsored customers. Grants a fixed number of free
encounters on subscribe — not Stripe billing coupons. See customer_journey_issues.md
Discount codes & free encounters (locked).

Goals:
- Add Discount dictionary (Configuration + Dictionary + Test Data):
    code (unique), free_encounters (required).
- Optional fields (defaults unless Mike overrides): status (active/inactive), description,
  expires_at, max_redemptions — document chosen shape in dictionary.
- Extend Customer.subscriptions[] embedded shape with:
    discount_code, free_encounters_granted, free_encounters_remaining (see journey doc).
- Seed examples: retail trial code (small free_encounters), partner/sponsored code (large
  free_encounters e.g. hundreds).
- Fetch/update via running configurator; prefer delete+create over rename.

Depends on: F-D22 subscriptions[] shape (same PR or immediately after).

Context: Workshops/customer_journey_issues.md — Discount codes & free encounters (locked)
```

### Issue text — API (`F-CA06`) — repo `mentorhub_customer_api`

```text
Title: F-CA06: E2 Checkout Session + subscribe webhooks

Repository: mentor-forge/mentorhub_customer_api
Task file: tasks/PENDING.F-CA06.stripe_checkout_and_subscribe_webhooks.md

Description:
First paid subscription via Stripe Checkout. Implements GET /plans, POST /billing/checkout-session,
POST /webhooks/stripe (subscribe events), Payment persistence, Customer.subscriptions[] sync.

Goals:
- Stripe SDK + env config (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET).
- GET /api/plans — Product fields: minimum_members, subscription, unit_price (+ product_id).
- POST /api/billing/checkout-session — body { subscription or product_id, quantity };
  validate quantity >= Product.minimum_members; resolve stripe_price_id; snapshot unit_cost/total_cost
  onto Customer.subscriptions[] on webhook success.
- POST /api/webhooks/stripe — signature verify; idempotent on event.id; persist Payment;
  handle checkout.session.completed, customer.subscription.created/updated, invoice.paid.
- Extend Customer GET for JWT owner with subscriptions[] (locked business + sync fields).
- No PANs; never trust success_url as paid.

Decisions still open (detail in task file):
- Success/cancel URL base (CUSTOMER_SPA_BASE_URL).
- Payment collection name (default: Payment).
- Stripe Customer creation on first checkout (default: first checkout).
- encounters_mo source at purchase (copy from Product extension vs plan config — default: Product field when added).

Depends on: F-D22; Do This First R1 for Payment webhook schema only.

Context: Workshops/customer_journey_issues.md E2; Product & Subscription data shape (locked)
```

### Issue text — API (`F-CA13`) — repo `mentorhub_customer_api`

```text
Title: F-CA13: E2 Discount codes — validate at checkout, grant free encounters on subscribe

Repository: mentor-forge/mentorhub_customer_api
Task file: tasks/PENDING.F-CA13.discount_codes_free_encounters.md

Description:
Apply Discount codes at checkout. Codes grant free_encounters on Customer.subscriptions[]
after successful subscribe webhook — Stripe price unchanged (encounter entitlement only).

Goals:
- Accept optional discount_code on POST /billing/checkout-session (with F-CA06).
- GET /api/discounts/validate?code= — optional pre-check for SPA (or validate inline on checkout).
- Validate: code exists, active, not expired, under max_redemptions if set.
- Store pending discount on checkout metadata or session-scoped hold until webhook succeeds.
- On subscribe webhook: set discount_code, free_encounters_granted, free_encounters_remaining
  on subscriptions[] entry; increment redemption count on Discount doc.
- Return free_encounters_remaining on Customer GET for SPA display.
- Do not implement encounter decrement here — follow-on Mentor/Encounter API ticket.

Decisions required (defaults in task file):
- Case sensitivity for code lookup (default: uppercase normalize).
- Single-use per Customer vs global max_redemptions.
- Invalid code: reject checkout (400) vs warn-only (default: reject).

Depends on: F-D28; F-CA06 checkout + webhook path.

Context: Workshops/customer_journey_issues.md — Discount codes & free encounters (locked)
```

### Issue text — SPA (`F-CS04`)

```text
Title: F-CS04: E2 Plans / cart, Checkout redirect, success/cancel

Description:
Cart and Stripe redirect UI (not auth UI).

Goals:
- Plans/cart: pick Product (subscription, unit_price, minimum_members); set quantity >= minimum_members;
  optional discount code field; validate via API if pre-check exists; show computed total;
  show free_encounters grant when code valid; Checkout CTA.
- POST checkout with { subscription or product_id, quantity, discount_code? } — no unit_price from client.
- Redirect to Stripe; success “Confirming…” then refetch; show free_encounters_remaining when present.
- Cancel messaging; no card form; no Stripe secrets in SPA; no login screens.

Depends on: F-CA06; F-CA13; E0 cleanup.

Context: Workshops/customer_journey_issues.md E2
```

---

## E3 — View fixed Customer home

### Actions

1. Lands on fixed Customer home (not Dashboard collection — F-D15).
2. Unsubscribed → Choose a plan (E2). Subscribed → mentee roster/activity via `Profile.customer_id`.
3. Gate premium views on API subscription status.

### Issue text — Data (`F-D23`)

```text
Title: F-D23: E3 Test data for fixed Customer home (reuse Profile.customer_id)

Description:
No Dashboard dictionary. Roster uses existing Profile.customer_id (Profile.0.1.0.yaml) and
related Mentee/Encounter/Event data.

Goals:
- Seed Customer → Profiles (customer_id set, roles) → activity enough for list + empty states.
- Extend existing test_data/Profile.0.1.0.0.json and Customer.0.1.0.0.json; do not revive Dashboard.
- Confirm F-D15 Dashboard Configuration + Dictionary remain deleted.

Context: Workshops/customer_journey_issues.md E3; configurator/dictionaries/Profile.0.1.0.yaml
```

### Issue text — API (`F-CA07`)

```text
Title: F-CA07: E3 Customer home aggregates + subscription gate

Description:
Read APIs for fixed home; no live Stripe per page load.

Goals:
- Return subscriptions[] for CTA vs roster.
- Aggregate mentee activity for JWT customer_id (Profiles where customer_id matches);
  403 when product rules require active sub.

Context: Workshops/customer_journey_issues.md E3
```

### Issue text — SPA (`F-CS05`)

```text
Title: F-CS05: E3 Fixed Customer home / mentee activity

Description:
Default home after E0 cleanup and AWS Cognito login return.

Goals:
- Home: Choose a plan vs roster/activity from API.
- Gate premium UI on API subscription state only.
- No custom Dashboard CRUD pages (removed in F-CS02 / F-D15).

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

Description:
Store invites created by an authenticated primary user (name, email, status) before invitee
accepts. Profile.0.1.0.yaml links accepted members via customer_id + roles; invites are the
pre-accept record.

Goals:
- Schema + test data for pending/accepted/revoked invites tied to inviter customer_id.
- Prefer embed on Customer document OR small Invite dictionary — do not overload Profile fields.
- If new collection: Configuration + Dictionary + Test Data.
- No GDPR request property on invite or Customer.

Prerequisites / decisions (defaults for MVP unless Mike overrides):
- Invitee roles: ["customer"] only — not coordinator, not admin.
- Invitee mentor_id: "" on create.
- customer_id on invite and resulting Profile: always inviter’s JWT customer_id (never from body).
- Persistence shape: embed invites[] on Customer unless query patterns need separate collection.

Depends on: E1 primary registration working (F-CA05); F-D21 Profile.customer_id.

Context: Workshops/customer_journey_issues.md E4; Research/cognito.md Path B;
Workshops/customer_workshop_2.md Activate
```

### Issue text — API (`F-CA08`)

```text
Title: F-CA08: E4 Invite members — AdminCreateUser under inviter customer_id

Description:
Authenticated primary user invites additional org members by name + email. Creates Profile
under inviter’s customer_id and Cognito user via AdminCreateUser invite — invitees must NOT
use public Hosted UI self-sign-up.

Goals:
- POST invite: require JWT customer_id; accept name + email only; create Profile with
  customer_id = inviter’s, roles ["customer"], mentor_id "".
- AdminCreateUser + invite message; set custom:profile_id, custom:customer_id, custom:mentor_id,
  custom:roles before or at first token (same attribute names as F-S01).
- GET list invites; PATCH revoke if supported.
- Idempotent re-invite same email under same customer: resend message, no duplicate Profile/Cognito user.
- Reject invite if email already has Profile under another customer_id (direct to support/E1 conflict message).
- Optional seat/capacity: compare active+pending invites to subscriptions[].quantity and
  Product.minimum_members — hard block when at capacity (soft warning is a product override).

Prerequisites:
- F-S01 Cognito pool + Pre Token Generation (same as E1).
- Inviter must have completed E1 self-registration (valid customer_id on JWT).

Depends on: F-D24; F-S01; F-CA05 patterns.

Context: Workshops/customer_journey_issues.md E4; Research/cognito.md Path B
```

### Issue text — SPA (`F-CS06`)

```text
Title: F-CS06: E4 Invite Members page

Description:
UI for primary user (Cat) to invite org members by name and email. Invitee onboarding is
Cognito invite email only — no SPA signup for invitees.

Goals:
- Invite form (name, email); list pending/accepted; revoke if API supports.
- Surface capacity errors from API (at-capacity hard block by default).
- Do not link to or embed Hosted UI self-sign-up for invitees.
- Gate page on authenticated session with customer_id claim present.

Depends on: F-CA08.

Context: Workshops/customer_journey_issues.md E4; Research/cognito.md Path B
```

---

## E5 — Change subscription

### Actions

1. Opens Subscription / Billing.
2. Changes capacity via cart → Checkout and/or Portal.
3. Manage billing → `POST /billing/portal-session` → Stripe Portal; return + refetch; webhooks sync.

### Issue text — Data (`F-D25`)

```text
Title: F-D25: E5 Capacity / mid-lifecycle subscription test data

Description:
Seed Customers with subscriptions[] quantity and status after Portal/Checkout updates
(depends on F-D22 Customer shape — not Subscription.0.1.0.yaml stub).

Goals:
- Test data covering active with N seats and post-change states on Customer documents.

Context: Workshops/customer_journey_issues.md E5; configurator/dictionaries/Customer.0.1.0.yaml (extended)
```

### Issue text — API (`F-CA09`) — repo `mentorhub_customer_api`

```text
Title: F-CA09: E5 Portal session + capacity-change Checkout

Repository: mentor-forge/mentorhub_customer_api
Task file: tasks/PENDING.F-CA09.stripe_portal_and_capacity_checkout.md

Description:
Manage billing via Stripe Customer Portal; change seat capacity via Checkout (extends F-CA06).

Goals:
- POST /api/billing/portal-session → { portal_url }; return_url to SPA billing page.
- Extend checkout-session for capacity change (quantity validation).
- Document Stripe Dashboard Portal configuration requirements.
- Never store PANs.

Decisions required (detail in task file):
- Portal allowed actions (default: cancel + update payment method).
- Capacity change via Checkout vs Subscription API (default: Checkout).
- Seat decrease vs active invites (blocked on F-CA08 for full validation).

Depends on: F-CA06; F-D25 test data optional.

Context: Workshops/customer_journey_issues.md E5; Research/stripe_research.md
```

### Issue text — SPA (`F-CS07`)

```text
Title: F-CS07: E5 Subscription + Billing pages

Description:
Capacity change UI and Manage billing → Stripe Customer Portal.

Goals:
- Show plan/capacity/status from API; Portal redirect + refetch.
- Payment-failed deep link shared with E6.
- No MentorHub card or login forms.

Context: Workshops/customer_journey_issues.md E5
```

---

## E6 — Recurring charge

### Actions

1. Stripe renews (Stripe internals — **not** Customer API).
2. Same `POST /webhooks/stripe`: `invoice.paid` or `invoice.payment_failed`.
3. SPA shows past_due banner → Manage billing (E5).

### Issue text — Data (`F-D26`)

```text
Title: F-D26: E6 Payment fixtures for invoice.paid and invoice.payment_failed

Description:
Renewal success/failure documents + past_due on Customer.subscriptions[] (F-D22 Payment + Customer).

Goals:
- Payment schema supports Invoice webhook shapes; link by customer_id / stripe ids.
- Seed past_due Customer + failed/successful Payment docs.
- No Card collection; no GDPR fields.

Context: Workshops/customer_journey_issues.md E6
```

### Issue text — API (`F-CA10`) — repo `mentorhub_customer_api`

```text
Title: F-CA10: E6 Renewal webhooks + past_due signal (no charge API)

Repository: mentor-forge/mentorhub_customer_api
Task file: tasks/PENDING.F-CA10.stripe_renewal_webhooks_and_past_due.md

Description:
Stripe-driven renewals only — extend webhook router from F-CA06.

Goals:
- invoice.paid / invoice.payment_failed handlers; persist Payment; sync subscriptions[].
- Set past_due on payment failure for SPA banner (F-CS08).
- Idempotent; no MentorHub charge API.

Decisions required (detail in task file):
- past_due as subscriptions[].status (default).
- Invoice fields stored on Payment doc (follow F-D26).

Depends on: F-CA06; F-D26 fixtures.

Context: Workshops/customer_journey_issues.md E6
```

### Issue text — SPA (`F-CS08`)

```text
Title: F-CS08: E6 Payment-failed banner

Description:
In-app past_due banner → Manage billing.

Goals:
- Drive only from API state; optional email copy hook later.

Context: Workshops/customer_journey_issues.md E6
```

---

## E7 — Cancel subscription

### Actions

1. Cancel via **Customer Portal** (preferred).
2. Webhook subscription updated/deleted → `subscriptions[]` canceled.
3. SPA Resubscribe CTA; API 403 on gated resources.

### Issue text — Data (`F-D27`)

```text
Title: F-D27: E7 Canceled subscription test data

Description:
Seed canceled Customer.subscriptions[] for Resubscribe UI and 403 tests (Customer document,
not Subscription.0.1.0.yaml).

Context: Workshops/customer_journey_issues.md E7
```

### Issue text — API (`F-CA11`) — repo `mentorhub_customer_api`

```text
Title: F-CA11: E7 Cancel sync via Portal webhooks

Repository: mentor-forge/mentorhub_customer_api
Task file: tasks/PENDING.F-CA11.stripe_cancel_webhook_and_access_gate.md

Description:
Primary cancel path is Portal + webhooks; enforce inactive access on premium routes.

Goals:
- customer.subscription.updated / deleted → update subscriptions[]; persist event.
- require_active_subscription gate — 403 on premium routes when no active sub.
- Honor cancel_at_period_end grace (default in task file).

Decisions required (detail in task file):
- Which routes are gated (coordinate with F-CA07, F-CA08).
- MVP single subscription per Customer (default).

Depends on: F-CA06, F-CA09; F-D27 test data.

Context: Workshops/customer_journey_issues.md E7
```

### Issue text — SPA (`F-CS09`)

```text
Title: F-CS09: E7 Cancel flow + unsubscribed CTA

Description:
Entry to Portal cancel; after refetch show Resubscribe / Choose a plan.

Context: Workshops/customer_journey_issues.md E7
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
Title: F-CA12: E8 Privacy action — cancel Stripe + redact Profile/Encounter PII

Description:
Orchestrate forget for the authenticated Customer’s people. SPA button calls this action.
No persistence of a “GDPR request” field on Customer or Profile.

Goals:
- Cancel Stripe subscriptions for stripe_customer_id when still active.
- Redact/anonymize Profile person fields (full_name, email, experience, etc.) and Encounter
  transcript/summary/tldr as policy requires.
- Do not add or require a gdpr_* schema property; do not treat Customer org/billing docs as
  person PII subject to the same erase rules.
- Document Payment retention (financial, non-PII) vs person PII.
- Do not implement Cognito login UI; may disable/delete Cognito user via Admin API as part of
  the action (F-S01 pool must grant Customer API AdminDeleteUser).

Context: Workshops/customer_journey_issues.md E8; configurator/dictionaries/Profile.0.1.0.yaml;
configurator/dictionaries/Encounter.0.1.0.yaml
```

### Issue text — SPA (`F-CS10`)

```text
Title: F-CS10: E8 Account / Privacy — request PII removal button

Description:
UI button + confirm → call privacy API → show outcome. Not a data editor for Customer commerce.

Goals:
- Account / Privacy surface with destructive confirm; call F-CA12 action; show success/failure.
- No form field bound to a GDPR data property (there is none).
- No custom auth screens; session aftermath per product rules after redact.

Context: Workshops/customer_journey_issues.md E8
```

---

## Suggested implementation order

1. **Do This First** R1–R2 (Stripe webhook Payment schema + rename umbrellas).
2. **E0 Cleanup** — SPA nav/pages → API endpoint removal → Data drops (F-D14/15/16) → F-W09 Coordinator removal.
3. **E1** Cognito CloudFormation **F-S01** (`mentorhub_cloudformation` R071) → Data (F-D21) → API callback (F-CA05) → SPA post-auth (F-CS03).
4. **E2** Subscribe — F-D22 + **F-D28** → F-CA06 + **F-CA13** → F-CS04.
5. **E3** Fixed home.
6. **E4** Invites (F-D24 → F-CA08 → F-CS06) — after E1 provisioning works.
7. **E5–E7** Billing change / renew / cancel.
8. **E8** GDPR — **F-CA12 + F-CS10 only** (no F-D property ticket).

When creating tasks in a repo, copy Issue text into that repo’s `_PLANNING.md` workflow → `PENDING.*.md` per local planning layout.

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
