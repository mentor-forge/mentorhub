# Customer Journey Issues

Sources (Mike PR #31 review prompts + research):

- `Workshops/customer_workshop_2.md` (User Journey Reflect — experiences, pages, data)
- `Research/stripe_research.md` (Checkout + Customer Portal + webhooks; anti-patterns)
- `Research/cognito.md` (AWS Cognito — primary self-registration + invitation onboarding; JWT claims)
- `Research/local_dev_mocks.md` (Developer Edition — Cognito & Stripe mocks; extend `login.html`)
- `Workshops/2026-07-21 Mary-Anderson (2).md` (embed subscriptions on Customer; drop Card / Dashboard; Payment webhooks)
- `Workshops/exercise_templates/journey_mapping.md` (Make → Data / API / UI tickets per step group)
- `tasks/_PLANNING.md` (task file layout for each repo)
- [`admin_journey_issues.md`](./admin_journey_issues.md) — Admin ingress (F-AA##, F-AS##)
- [`discovery_journey_issues.md`](./discovery_journey_issues.md) — Discovery landing (F-DA##, F-DS##)
- [F-US09 Cross-repo linking](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26), [F-UA08 Config constants](https://github.com/mentor-forge/mentorhub_api_utils/issues/17), [F-UA12 RBAC pattern](https://github.com/mentor-forge/mentorhub_api_utils/issues/25)
- Existing code: `mentorhub_customer_api`, `mentorhub_customer_spa` (template CRUD + working AWS Cognito / IdP redirect)
- Schemas (provisional files; runtime configurator is definitive): `mentorhub_mongodb_api/configurator/dictionaries/*.yaml`

**Actor:** Cat the Customer (paying sponsor).

**How to use:** Each Experience has paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md` (assume `_PLANNING.md` / `_ORCHESTRATE.md` already exist from a separate bootstrap ticket). **Do not** reference specific task filenames here; Cursor breaks work into appropriately sized tasks. Locked Product, Subscription, and Discount shapes are below. Prefer delete+create over rename in the configurator. When dropping a collection, delete **Configuration**, **Dictionary**, and **Test Data** (where present).

**Auth:** **AWS Cognito** is the IdP. Login / password / MFA / Hosted UI are Cognito — do **not** file SPA or API tickets for custom login or signup screens. Customer SPA already redirects via `VITE_IDP_LOGIN_URI` / `redirectToIdpLogin`.

**Onboarding:** **Primary user** self-registers via Cognito Hosted UI → **Admin ingress** ([F-AA01](./admin_journey_issues.md#issue-text--admin-api-f-aa01)) provisions minimal **Customer (Organization)** + **Profile** (owner) → **Customer API** ([F-CA05](#issue-text--api-f-ca05)) enriches and syncs Cognito JWT claims. **Additional members** join only via **invitation** — Profile under inviter’s `customer_id`, Cognito `AdminCreateUser` invite. See `Research/cognito.md`.

**Post-login landing:** **Discovery SPA** ([F-DS01](./discovery_journey_issues.md#issue-text--discovery-spa-f-ds01)) — not Customer SPA. Customer SPA is org/commerce management reached via universal nav ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)).

---

## Locked decisions (file issues when ready)

**Product & Subscription shape (locked — Mike):** See [Product & Subscription data shape](#product--subscription-data-shape-locked) below.

**Discount / free encounters (locked — Mike):** See [Discount codes & free encounters](#discount-codes--free-encounters-locked).

**Stripe webhooks:** Received by **Admin ingress** ([F-AA01](./admin_journey_issues.md#issue-text--admin-api-f-aa01)); Customer API **consumes** normalized events — no public webhook routes on Customer API in production. Event list, JSON shapes, and Payment dictionary fields — research during **F-D22**, **F-D29**, and **F-CA06** / **F-CA09** implementation; use [Stripe API docs](https://docs.stripe.com/api).

**Stripe API implementation:** **F-CA06** (E2 subscribe + discount codes), **F-CA09** (E5–E7 Portal, renewals, cancel, access gate). Checkout and Portal session endpoints remain on Customer API.

**Cognito infra:** Requirements in `Research/cognito.md`. Post Confirmation Lambda → **Admin ingress** (not Customer API directly). Implementation **F-S01** in `mentorhub_cloudformation`.

**Local dev mocks (locked — 2026-07-28):** `Research/local_dev_mocks.md` — **F-W10** (`login.html` tabs + stripe-mock in compose); **F-CA05** dev routes (`REGISTRATION_DEV_MODE`); **`COGNITO_ENABLED=false`** locally (no Cognito container); webhook fixtures with **`STRIPE_WEBHOOK_VERIFY=false`** → **Admin ingress** URL. cognito-local explicitly deferred.

**Task automation (bootstrap before E0):** **F-CA-L001** and **F-CS-L001** — planning agents in each repo create journey `tasks/` files from this document. `_PLANNING.md` / `_ORCHESTRATE.md` are maintained separately; do not edit sibling repos from `mentorhub`.

**Platform plumbing (Phase 0 — before E0):** [F-UA08](https://github.com/mentor-forge/mentorhub_api_utils/issues/17) Config constants → [F-UA12](https://github.com/mentor-forge/mentorhub_api_utils/issues/25) RBAC pattern → [F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26) cross-repo linking → [F-W18](https://github.com/mentor-forge/mentorhub/issues/52) Admin/Discovery bootstrap, [F-D29](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/61) event schemas ([F-W13](https://github.com/mentor-forge/mentorhub/issues/36), [F-W14](https://github.com/mentor-forge/mentorhub/issues/38)).

**Admin & Discovery domains (locked — 2026-07-29):** External webhooks and identity provisioning live in **Admin**; universal landing, notifications UX, and cross-SPA discovery live in **Discovery**. Issue text: [`admin_journey_issues.md`](./admin_journey_issues.md), [`discovery_journey_issues.md`](./discovery_journey_issues.md). Adjustments: `Workshops/customer_journey_issues_adjustments.md`.

**Customer vs Organization naming:** [F-W13](https://github.com/mentor-forge/mentorhub/issues/36) uses **Organization**; dictionaries and APIs still say **Customer**. Until renamed, use **Customer (Organization)** in issue text. Admin ingress provisions minimal aggregate roots in `provisioned` state; Customer domain enriches (name, subscriptions[], billing).

**Notifications:** Producer domains (Customer API, Admin SPA) **write** Notification documents; Discovery API owns **dismiss** mutation; Discovery SPA renders cards. Not the primary surface of Customer home ([F-CS05](#issue-text--spa-f-cs05)).

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

**After payment:** Admin ingress records Stripe event → Customer API consumer updates `Customer.subscriptions[]` (business fields + sync fields + discount grant fields). SPA refetches Customer; do not treat success URL as proof of payment.

---

## Naming (CONTRIBUTING.md)

Format: **`Type-UserLayerNumber: short title`** — **User (journey) then Layer**, then a colon and title (matches existing GitHub issues such as `F-CA03: …`, `F-D16: …`).

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-CA##` | Customer **A**pi | `mentorhub_customer_api` |
| `F-CS##` | Customer **S**pa | `mentorhub_customer_spa` |
| `F-D##` | **D**ata (mongodb configurator — no layer letter) | `mentorhub_mongodb_api` |
| `F-W##` | **W**elcome / mentorhub platform | `mentorhub` |
| `F-S##` | **S**RE (when used) | platform / cloudformation as applicable |
| `F-AA##` | **A**dmin **A**pi | `mentorhub_admin_api` |
| `F-AS##` | **A**dmin **S**pa | `mentorhub_admin_spa` |
| `F-DA##` | **D**iscovery **A**pi | `mentorhub_discovery_api` |
| `F-DS##` | **D**iscovery **S**pa | `mentorhub_discovery_spa` |

Admin and Discovery journey issue text: [`admin_journey_issues.md`](./admin_journey_issues.md), [`discovery_journey_issues.md`](./discovery_journey_issues.md).

Examples from CONTRIBUTING: `F-RS05` = 5th Mentor SPA; `F-EA04` = 4th Mentee API → therefore **`F-CA05` = 5th Customer API**, **`F-CS05` = 5th Customer SPA**.

### Next numbers (fetched 2026-07-22, open + closed)

| Prefix | Highest seen | Next to assign | Notes |
| --- | --- | --- | --- |
| `F-CA` | `F-CA03` ([customer_api#4](https://github.com/mentor-forge/mentorhub_customer_api/issues/4)) | **F-CA04** | Also open: F-CA01, F-CA02 |
| `F-CS` | `F-CS01` ([customer_spa#3](https://github.com/mentor-forge/mentorhub_customer_spa/issues/3)) | **F-CS02** | |
| `F-D` | `F-D20` | **F-D21** for net-new | Repurpose open #35–#37 as **F-D-E0** (combined drop) |
| `F-W` | `F-W17` | **F-W18** ([#52](https://github.com/mentor-forge/mentorhub/issues/52)) | F-W15 = make install; F-W09 = E0 Coordinator removal; F-W10 = local dev mocks; F-W13/F-W14 = domain design |
| `F-S` | — | **F-S01** | `mentorhub_cloudformation` — Cognito pool |
| `F-AA` | — | **F-AA01** | Admin API ingress — see admin_journey_issues.md |
| `F-DA` | — | **F-DA01** | Discovery API — see discovery_journey_issues.md |
| `F-DS` | — | **F-DS01** | Discovery SPA — see discovery_journey_issues.md |
| `F-D` (cross-domain) | `F-D28` | **F-D29** ([#61](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/61)) | F-D29 = event types + ExternalEvent + Notification schemas (not E5 test data F-D25) |

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
| **ExternalEvent** | *(new — F-D29)* | Append-only ingress record: source (`stripe` \| `cognito`), external id, payload hash, normalized body reference, `created` |
| **Notification** | *(new — F-D29)* | Scope (`all` \| `customer` \| `mentor` \| `profile`), target ids, message, link metadata, dismiss state |
| **Event** | `configurator/dictionaries/Event.0.1.0.yaml` | Extend `event_types` enum in F-D29 for ingress, subscription, invite, notification, GDPR events |

Also drop matching `configurator/configurations/{Card,Subscription,Dashboard}.yaml` and any `configurator/test_data/*` for those collections (Card has `Card.0.1.0.0.json`; Subscription/Dashboard currently have no test_data files). **Do not drop Event** — required for ingress and cross-domain async communication.

**GDPR:** Applies to **person PII** on **Profile** (and possibly **Encounter** transcript/summary/tldr). Does **not** apply to Customer org/billing documents. **No** `gdpr_request` (or similar) data property — SPA button + API action only.

---

## Already exists — do **not** file as new work

Reviewed `mentorhub_customer_spa` and `mentorhub_customer_api` (template microservices).

| Capability | Where | Ticket guidance |
| --- | --- | --- |
| AWS Cognito / IdP JWT redirect + guards | SPA: `initAuth.ts`, router `beforeEach` → `redirectToIdpLogin`, `VITE_IDP_LOGIN_URI`; 401 → re-login; Logout → IdP | **Sufficient** — no login/signup screen tickets |
| Bearer JWT on API | `api_utils` token helper; claims include `profile_id` (required), `customer_id`, `mentor_id`, `roles` | **Sufficient** plumbing; still need **provisioning** that *sets* those claims (E1) |
| Generic Customer GET list/by-id | API + SPA scaffolding | Keep as base; rewrite for JWT `customer_id` + future `subscriptions[]` |
| Generic Profile GET | API + SPA scaffolding | Keep as base; ingress provisions Profile; **F-CA05** enriches after Admin ingress (E1) |
| Shopping cart / Customer org home / invites / GDPR UI | **None** | Net-new tickets; default platform home is **Discovery** ([F-DS01](./discovery_journey_issues.md)) |
| Stripe Checkout / Portal / webhooks | **None** on Customer API | Checkout/Portal on Customer API; webhooks on **Admin ingress** ([F-AA01](./admin_journey_issues.md)); Customer API event consumer |

Legacy **CRUD scaffolding to remove** (not extend): Card, Dashboard, standalone Subscription list/new/edit; **admin-only pages** (move to Admin SPA per F-US09); likely Event/Journey/Rating/Note template pages unless retained on purpose. Default SPA home today is `/subscriptions` — replace with universal nav + Discovery landing after cleanup.

---

## Design principles

| Assumption | Prefer |
| --- | --- |
| Custom SPA/API login or signup screens | **AWS Cognito** Hosted UI / existing SPA IdP redirect only |
| Cognito Hosted UI self-signup alone sets MentorHub claims | **Post Confirmation → Admin ingress** provisions minimal Customer (Organization) + Profile → **Customer API** enriches + sets Cognito custom attributes. See `Research/cognito.md` Path A |
| External webhooks on Customer API | **Admin ingress** verifies, normalizes, provisions identities, records ExternalEvent/Event; Customer API consumes events for business logic |
| Default post-login landing | **Discovery SPA** ([F-DS01](./discovery_journey_issues.md)); Customer SPA is org/commerce via universal nav ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)) |
| Additional org members self-register publicly | **Invitation only** — authenticated primary user invites; **AdminCreateUser** under inviter’s `customer_id`. See `Research/cognito.md` Path B |
| MentorHub card forms | **Stripe Checkout** only; drop `Card` |
| Customer API charges renewals | **Stripe Billing**; Admin ingress receives webhooks; Customer API syncs state |
| Success URL = paid | Event consumer updates `Customer.subscriptions[]`; SPA **refetches** |
| Cancel primarily via MentorHub→Stripe API | Prefer **Customer Portal** + Admin ingress webhooks; direct Stripe cancel for **GDPR** offboard |
| Configurable Dashboard collection | **Discovery** dashboard cards + **Customer org home** ([F-CS05](#issue-text--spa-f-cs05)); **drop Dashboard** collection |
| Standalone Subscription collection | Embed **`subscriptions[]` on Customer**; drop top-level Subscription |
| GDPR request field on Customer/Profile | **No data property** — Privacy UI button + API redact action only |
| Keep Coordinator microservice | **Remove** Coordinator API + SPA (Mike); drop coordinator from Discovery MVP card types |
| Per-SPA navigation | **spa_utils** universal frame ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)) |
| List/query RBAC | **api_utils** standard inbound/outbound filters ([F-UA12](https://github.com/mentor-forge/mentorhub_api_utils/issues/25)) |

---

## Serialized journey (refined)

```text
Phase 0 — Platform plumbing: F-UA08, F-UA12, F-US09; Admin/Discovery bootstrap (F-W18, F-AA01, F-DA01, F-DS01); F-D29 event schemas

0. Cleanup first: strip legacy SPA nav/pages + API endpoints; drop Card / Subscription / Dashboard
   (Configuration + Dictionary + Test Data); remove Coordinator API+SPA from platform

1. Primary user (prospect) self-registers on Cognito Hosted UI (sign-up + confirm)
2. Post Confirmation trigger → Admin ingress: provision Customer (Organization) + Profile (owner)
   in provisioned state, record ExternalEvent → Customer API enriches, sets Cognito custom attributes
   — idempotent on sub/email
3. Primary user logs in → JWT has claims → lands on Discovery SPA (universal home)
4. Builds shopping cart in Customer SPA (offering + capacity + optional discount code)
5. Checkout → POST /billing/checkout-session (optional discount_code) → Stripe Checkout
6. Stripe → Admin ingress → ExternalEvent → Customer API consumer: Payment doc + Customer.subscriptions[]
   (+ free_encounters_* if discount applied); optional Notification for Discovery
7. Return URL → SPA refetches Customer (do not invent paid from URL)
8. Customer org home (roster/commerce via universal nav); CTA Choose a plan if unsubscribed
9. Primary user invites additional members → Profile under own customer_id + Notification;
   Cognito AdminCreateUser invite — invitees do NOT use public self-sign-up
10. Manages billing / capacity via Portal and/or Checkout; Admin ingress webhooks → Customer consumer syncs
11. Stripe renews → Admin ingress (invoice.paid | payment_failed) → Customer consumer → past_due Notification
12. Cancels in Customer Portal → Admin ingress → canceled
13. GDPR forget → SPA Privacy button → Customer API cancels Stripe if needed → redact Profile/Encounter PII
    (no GDPR data property; optional Admin API Cognito AdminDeleteUser)
```

---

## Experience map (cleanup first)

| # | Experience | Intent | Suggested IDs (start) |
| --- | --- | --- | --- |
| **P0** | **Platform plumbing** | api_utils RBAC/constants, spa_utils cross-links, Admin/Discovery bootstrap, event schemas | F-UA08, F-UA12, F-US09, F-W18, F-D29, F-AA01, F-DA01, F-DS01 |
| **E0** | **Cleanup first** | Remove legacy nav/endpoints/collections + Coordinator microservice | F-CS02, F-CA04, F-D-E0, F-W09 |
| E1 | Primary self-registration (Hosted UI → ingress → enrich → JWT claims) | First org owner via Cognito sign-up | F-D21, F-CA05, F-CS03, F-S01 |
| E2 | First subscription (cart → Checkout → ingress → consumer) | First paid entitlement; optional discount code | F-D22, F-CA06, F-CS04 |
| E3 | Customer org home (not platform landing) | Roster/commerce gated on subscription | F-D23, F-CA07, F-CS05 |
| E4 | Invite members | Additional org members; Notification to Discovery | F-D24, F-CA08, F-CS06 |
| E5 | Change subscription | Capacity + Portal | F-D-E5E7, F-CA09, F-CS07 |
| E6 | Recurring charge | Renewal events + past_due Notification | *(in F-CA09 / F-CS07)* |
| E7 | Cancel subscription | Portal + ingress consumer sync | *(in F-CA09 / F-CS07)* |
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
mentorhub/Workshops/customer_journey_issues.md and Workshops/customer_journey_issues_adjustments.md.
Create appropriately scoped task files under tasks/ — Cursor decides task breakdown.

Architecture: Admin ingress owns external webhooks and identity provisioning; Customer API
consumes events and owns commerce/invite business logic. Do not plan production webhook routes
on Customer API except dev parity shims calling the same ingress service layer.

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo (separate ticket).
Prerequisites: F-UA08, F-UA12 (api_utils); F-AA01 (Admin ingress) for E1/E2 webhook consumers.
Blocks: F-CA04 and later F-CA* feature issues.
```

### Issue text — SPA (`F-CS-L001`)

```text
Title: F-CS-L001: Customer SPA — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
First planning pass for Customer SPA journey work (E0 onward). Read issue text in
mentorhub/Workshops/customer_journey_issues.md and Workshops/customer_journey_issues_adjustments.md.
Create appropriately scoped task files under tasks/ — Cursor decides task breakdown.

Architecture: Discovery SPA is default post-login landing (F-DS01); Customer SPA is org/commerce
management reached via universal nav (F-US09). Plan commerce/roster UX only — not platform home.

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo (separate ticket).
Prerequisites: F-US09 (spa_utils cross-repo linking + universal nav).
Blocks: F-CS02 and later F-CS* feature issues.
```

---

## E0 — Cleanup first (do before most feature tickets)

### Actions

1. **SPA:** Remove legacy nav and pages (Subscriptions CRUD, Dashboards CRUD, Cards CRUD; trim Event/Journey/Rating/Note template noise unless retained on purpose). Keep AWS Cognito IdP redirect guards and Logout. **Remove local admin-only pages** — admin UI moves to Admin SPA (F-US09). Use universal nav from spa_utils when F-US09 ships; temporary home → redirect stub to Discovery or placeholder until F-DS01.
2. **API:** Remove OpenAPI/routes/services/tests for `/api/card`, `/api/dashboard`, `/api/subscription` (standalone CRUD). Keep `/api/customer` and `/api/profile` reads as starting points. Remove any admin-only Product routes — Products live under Admin API.
3. **Data:** For each dropped collection — delete **Configuration**, **Dictionary**, and **Test Data** (where present). **Do not drop Event** dictionary.
4. **Platform:** Remove **Coordinator API + SPA**; wire Admin + Discovery repos when F-W18 lands.

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
- Remove local admin-only pages (admin UI → Admin SPA per F-US09).
- Keep Logout, existing initAuth / VITE_IDP_LOGIN_URI flow; adopt universal nav when F-US09 ships.
- Placeholder or redirect home until Discovery landing (F-DS01); Customer org home in F-CS05.

Depends on: F-CS-L001 planning pass optional if tasks/ empty; F-US09 for cross-repo nav.
Context: Workshops/customer_journey_issues.md E0; Workshops/customer_journey_issues_adjustments.md
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
- Remove admin-only Product routes if present (Products → Admin API).
- No Stripe, no custom auth endpoints, no production webhook routes (→ Admin ingress F-AA01).

Depends on: F-CA-L001 planning pass optional if tasks/ empty; F-UA08 for Config constants.
Context: Workshops/customer_journey_issues.md E0; Workshops/customer_journey_issues_adjustments.md
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
- Do not delete Event dictionary — required for Admin ingress and cross-domain events.
- Coordinate with F-D21/F-D22/F-D29 so environments stay usable when subscriptions[] is added later.

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
- Wire Admin + Discovery repos into welcome portal when F-W18 lands.
- Remove coordinator from universal nav (F-US09).

Context: Workshops/customer_journey_issues.md E0; Workshops/customer_journey_issues_adjustments.md
```

---

## E1 — Primary self-registration (Hosted UI → new Customer + Profile → JWT claims)

### Actions

1. **Prospect** self-registers on **Cognito Hosted UI** (sign-up + email confirm). No SPA registration UI.
2. **Post Confirmation** Lambda calls **Admin ingress** ([F-AA01](#issue-text--admin-api-f-aa01)) to provision minimal **Customer (Organization)** + **Profile** (owner) in `provisioned` state and record ExternalEvent.
3. **Customer API** ([F-CA05](#issue-text--api-f-ca05)) enriches provisioned identities, sets Cognito `custom:*` attributes when `COGNITO_ENABLED`.
4. **Pre Token Generation** Lambda maps attributes → JWT claims (`profile_id`, `customer_id`, `mentor_id`, `roles`).
5. Primary user lands on **Discovery SPA** after login; Customer SPA reached via universal nav when needed.

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
- Hosted UI sign-up for primary users; app client URLs match Customer SPA and Discovery SPA.
- Pre Token Generation + Post Confirmation Lambdas (Post Confirmation calls Admin ingress F-AA01, not Customer API directly).
- IAM for Admin API (ingress provisioning + Cognito Admin) and Customer API (enrichment + attribute sync); stack outputs for SPA/API env.

Depends on: dev compute platform (ECS roles); F-AA01 (Admin ingress).
Context: Research/cognito.md; Workshops/customer_journey_issues.md E1 / E4
```

### Issue text — Data (`F-D21`)

```text
Title: F-D21: E1 Customer and Profile schema for primary self-registration

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Schema and test data for Cognito Hosted UI primary registration — Admin ingress provisions
Customer (Organization) + owner Profile; Customer API enriches. No Card; no GDPR request fields.

Goals:
- Extend Customer / confirm Profile for sign-up + Cognito custom attributes (F-S01).
- Support provisioned → active lifecycle on ingress-created documents (F-D29).
- Seed provisioned + enriched primary-owner Customer + Profile pairs for integration tests.
- Definitive schemas from running configurator only.

Depends on: F-D-E0 coordinated if subscriptions[] added in same window; F-D29 for provisioned status.
Context: Workshops/customer_journey_issues.md E1; Research/cognito.md Path A
```

### Issue text — API (`F-CA05`)

```text
Title: F-CA05: E1 Enrich provisioned org + profile after Admin ingress

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Enrich Customer (Organization) + Profile after Admin ingress provisioning on primary
self-registration. Production: consume ingress event or idempotent lookup by Cognito sub/email.
Local dev: dev routes when REGISTRATION_DEV_MODE (see Research/local_dev_mocks.md) calling the
same provisioning/enrichment service layer as Admin ingress. Shared logic for E4 invites.

Goals:
- Enrich provisioned Customer + Profile (owner); sync Cognito custom attributes when COGNITO_ENABLED.
- Idempotent on Cognito sub/email; no login/password/MFA APIs; no production webhook endpoints.
- Dev provisioning paths for Developer Edition (F-W10 login.html).

Depends on: F-D21; F-AA01 (Admin ingress); F-S01 for production Cognito.
Context: Research/cognito.md; Research/local_dev_mocks.md; Workshops/customer_journey_issues.md E1
```

### Issue text — SPA (`F-CS03`)

```text
Title: F-CS03: E1 Post-auth handoff — claims verification and Discovery redirect

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
After Cognito login (or local dev register tab), verify JWT claims and Customer/Profile state.
Default redirect to Discovery SPA (F-DS01). No SPA registration UI; not the platform home.

Goals:
- Verify claims loaded; link to Customer SPA cart when subscription CTA needed (E2).
- Handle provisioning lag (missing claims) with retry against Profile GET — do not invent signup.
- Keep existing Cognito auth guards unchanged.

Depends on: E0 cleanup; F-CA05; F-DS01 (Discovery landing); F-US09 (cross-repo links).
Context: Workshops/customer_journey_issues.md E1; Research/cognito.md
```

---

## E2 — First subscription (cart → Checkout → webhook)

### Actions

1. Builds **shopping cart** — offering, capacity/quantity, optional **discount code** (free encounters).
2. Checkout → Customer API validates discount, creates Stripe Checkout Session → browser to Stripe.
3. Stripe → **Admin ingress** ([F-AA01](#issue-text--admin-api-f-aa01)) → ExternalEvent → **Customer API consumer** persists Payment + updates `Customer.subscriptions[]` (including `free_encounters_*` when code applied); optional Notification for Discovery.
4. Return success/cancel URL → SPA refetches (never invent Active from URL); cross-SPA return URLs via F-US09.

### Issue text — Data (`F-D22`)

```text
Title: F-D22: E2 Catalog, Payment, Discount, and Customer.subscriptions[] for Checkout

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Data layer for first subscribe: Product catalog (shared with Admin SPA), Payment records,
Discount codes, embedded subscriptions[] on Customer. Locked shapes in customer_journey_issues.md.

Goals:
- Customer: stripe_customer_id, subscriptions[] (business + Stripe sync + discount fields).
- Product dictionary; Discount dictionary; Payment dictionary (derive fields from Stripe payloads via F-D29 event types).
- Seed Products, Discounts, unsubscribed and active Customers.
- Product catalog CRUD UI → Admin SPA (F-AS01 ProductsListPage per F-US09), not Customer SPA.
- Use running configurator; prefer delete+create over rename.

Depends on: F-D-E0; F-D29 (webhook-related event types).
Context: Workshops/customer_journey_issues.md E2 — Product, Discount, and Subscription shapes
```

### Issue text — API (`F-CA06`)

```text
Title: F-CA06: E2 Stripe subscribe — Checkout, event consumer, and discount codes

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
First paid subscription via Stripe Checkout. Includes MentorHub discount codes (free encounters,
not Stripe coupons). Admin ingress receives Stripe webhooks; this service consumes normalized
events. See locked Checkout contract and Workshops/customer_journey_issues_adjustments.md.

Goals:
- GET /plans; POST /billing/checkout-session; event consumer for subscribe events from Admin ingress.
- Validate discount codes; grant free_encounters on subscriptions[] via checkout metadata.
- Persist Payment; sync Customer.subscriptions[]; write Notification on subscribe when appropriate.
- Never trust success URL as paid; no production POST /webhooks/stripe on Customer API.
- Local dev: stripe-mock → Admin ingress + STRIPE_WEBHOOK_VERIFY=false per Research/local_dev_mocks.md.

Depends on: F-D22; F-AA01; F-UA12 (RBAC).
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
- Redirect to Stripe; success/cancel flows refetch Customer (event consumer activates entitlement).
- Cross-SPA success/cancel return URLs via F-US09; link back to Discovery after checkout.
- No card forms or Stripe secrets in SPA.

Depends on: F-CA06; E0 cleanup; F-US09.
Context: Workshops/customer_journey_issues.md E2
```

---

## E3 — Customer org home (not platform landing)

### Actions

1. User reaches Customer org views via universal nav ([Customer Name], Members — F-US09), not as default post-login home.
2. Unsubscribed → Choose a plan (E2). Subscribed → mentee roster/activity via `Profile.customer_id`.
3. Gate premium views on API subscription status. Platform-wide “what needs attention” → Discovery notifications.

### Issue text — Data (`F-D23`)

```text
Title: F-D23: E3 Test data for fixed Customer home

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Seed data for Customer org roster/commerce views using Profile.customer_id — no Dashboard
collection; not Discovery notification/dashboard cards.

Goals:
- Customer → Profiles → enough Encounter/Event activity for roster list and empty states.

Context: Workshops/customer_journey_issues.md E3
```

### Issue text — API (`F-CA07`)

```text
Title: F-CA07: E3 Customer home aggregates and subscription gate

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Read APIs for Customer org home (roster/commerce); gate premium routes on subscription status.
Use F-UA12 outbound RBAC filters — not a second platform dashboard API.

Goals:
- subscriptions[] on Customer GET for CTA vs roster.
- Mentee activity aggregate for JWT customer_id; 403 when active sub required.

Depends on: F-UA12.
Context: Workshops/customer_journey_issues.md E3
```

### Issue text — SPA (`F-CS05`)

```text
Title: F-CS05: E3 Customer org home and mentee activity

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Customer org management home — Choose a plan vs roster gated on API subscription state.
Entry via universal nav (F-US09). Not the default platform landing (F-DS01).

Goals:
- Org home page wired to F-CA07; no Dashboard CRUD.
- Cross-SPA navigation from Discovery cards/notifications when linked.

Depends on: F-CA07; E0 cleanup; F-DS01; F-US09.
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
- Optional Notification test seed when invite created (for Discovery F-DS01).
- No GDPR request property.

Depends on: F-D21; F-D29 (Notification schema).
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
- Write Notification document on invite (scope: customer or profile) for Discovery.
- Cognito AdminCreateUser remains Customer API (invite business rules); Admin ingress only for external signup provisioning.

Depends on: F-D24; F-CA05; F-S01; F-UA12; F-D29.
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
- Entry via universal nav; cross-SPA link from Discovery notification.

Depends on: F-CA08; F-US09.
Context: Workshops/customer_journey_issues.md E4
```

---

## E5–E7 — Billing lifecycle (change, renew, cancel)

### Actions

**E5 — Change subscription:** Subscription / Billing → capacity via Checkout and/or Portal → webhooks sync.

**E6 — Recurring charge:** Stripe renews; Admin ingress (`invoice.paid` / `invoice.payment_failed`) → Customer consumer → past_due Notification (Discovery).

**E7 — Cancel:** Customer Portal cancel → Admin ingress → Customer consumer → canceled; Resubscribe CTA; API 403 on gated routes.

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
- Notification test fixtures for past_due and cancel (Discovery).

Depends on: F-D22; F-D29.
Context: Workshops/customer_journey_issues.md E5 / E6 / E7
```

### Issue text — API (`F-CA09`)

```text
Title: F-CA09: E5–E7 Stripe billing lifecycle — Portal, renewals, cancel, access gate

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_api

Description:
Post-subscribe billing: Customer Portal, capacity checkout, renewal/cancel event consumers,
and subscription gate on premium routes. Admin ingress receives Stripe webhooks; this service
consumes normalized events (extends F-CA06 consumer).

Goals:
- Portal session; capacity-change checkout.
- Event consumer: invoice.paid / invoice.payment_failed → past_due + Notification; subscription updated/deleted → canceled + Notification.
- require_active_subscription on gated routes; honor cancel_at_period_end.
- No production webhook signature verification on Customer API.

Depends on: F-CA06; F-AA01; F-D29.
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
- Subscription / Billing pages; payment-failed state from API / Discovery notifications.
- Portal entry for manage billing and cancel; cross-SPA return URLs via F-US09; refetch after return.
- Prefer single Notification source on Discovery for past_due; Customer SPA may show org-scoped billing context.

Depends on: F-CA09; F-US09; F-DS01.
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
- Privacy API action callable from SPA; orchestrate Stripe cancel + Profile/Encounter redaction.
- Cognito AdminDeleteUser → Admin API if split from Customer API; document in F-D29 event types.
- Document Payment retention vs person PII.

Depends on: F-D29 (profile_redacted event type).
Context: Workshops/customer_journey_issues.md E8
```

### Issue text — SPA (`F-CS10`)

```text
Title: F-CS10: E8 Account Privacy — PII removal button

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_customer_spa

Description:
Destructive confirm → call F-CA12 → show outcome. Entry via universal nav (Account/Privacy).
Not a Customer commerce editor.

Depends on: F-CA12; F-US09.
Context: Workshops/customer_journey_issues.md E8
```

---

## Suggested implementation order

1. **Phase 0 — Platform plumbing** — F-UA08, F-UA12, F-US09; F-W18; F-D29; F-AA01; F-DA01, F-DS01.
2. **Framework** — **F-CA-L001** + **F-CS-L001** (planning pass in each repo).
3. **E0** — F-CS02, F-CA04, F-D-E0, F-W09.
4. **E1** — F-D21, F-CA05, F-W10, F-CS03; F-S01 in parallel for prod Cognito.
5. **E2** — F-D22, F-CA06, F-CS04 (+ Admin SPA product admin when catalog UI needed).
6. **E3** — F-D23, F-CA07, F-CS05.
7. **E4** — F-D24, F-CA08, F-CS06.
8. **E5–E7** — F-D-E5E7, F-CA09, F-CS07.
9. **E8** — F-CA12, F-CS10.

Each issue instructs a planning agent to create `tasks/` files via `_PLANNING.md` — do not pre-specify task filenames in GitHub issues.

---

## F-W10 — Local dev: Cognito & Stripe mocks (locked)

### Actions

1. **stripe-mock** in `DeveloperEdition/docker-compose.yaml` — done; env vars documented (L7–L8).
2. **Keep** `login.html` persona picker for returning users.
3. **Add tabs** on welcome dev IdP: Register organization, Join as invited member, Update profile claims.
4. **Coordinate F-CA05 / F-AA01** — dev routes and login.html tabs call shared provisioning/enrichment service layer; welcome page mints JWT after API response.
5. **stripe-mock webhooks** → Admin ingress URL (not Customer API).
6. **Default login redirect** → Discovery SPA base URL.
7. **No cognito-local** for MVP (deferred per `Research/local_dev_mocks.md`).

### Issue text — Welcome / platform (`F-W10`)

```text
Title: F-W10: Local dev — Stripe mock and login.html register, invite, update

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub

Description:
Developer Edition without AWS/Stripe credentials. Locked design: Research/local_dev_mocks.md.

Goals:
- stripe-mock in compose; customer_api + admin_api dev env vars (see local_dev_mocks.md).
- login.html tabs: register org, join invite, update claims → Admin ingress dev endpoints or shared service; mint JWT after enrichment.
- Default post-login redirect → Discovery SPA.
- No cognito-local or Hosted UI locally.

Depends on: F-CA05 / F-AA01 dev provisioning; F-W18.
Context: Research/local_dev_mocks.md; E1, E4, E2; Workshops/customer_journey_issues_adjustments.md
```

---

## Explicitly out of scope

- SPA/API tickets for login, signup, password reset, or MFA screens (**AWS Cognito** Hosted UI owns auth UI — including primary self-sign-up)
- New SPA ticket to rewire IdP/JWT redirect guards (already implemented)
- Cognito Hosted UI self-sign-up **without** Post Confirmation → Admin ingress → Customer enrichment (claims would be missing)
- Public self-sign-up for **invited** members (E4 uses AdminCreateUser invite only)
- **Customer SPA as default post-login platform home** (Discovery F-DS01 owns landing)
- **Production Stripe/Cognito webhooks on Customer API** (Admin ingress F-AA01 owns ingress)
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
