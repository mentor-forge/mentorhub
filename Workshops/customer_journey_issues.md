# Customer Journey Issues

Sources (Mike PR #31 review prompts + research):

- `Workshops/customer_workshop_2.md` (User Journey Reflect — experiences, pages, data)
- `Research/stripe_research.md` (Checkout + Customer Portal + webhooks; anti-patterns)
- `Research/cognito_forms/cognito_forms_research.md` (optional alternate form tooling; distinct from **AWS Cognito** IdP — primary onboarding is **Squarespace → Google Sheet → script → POST Profile**)
- `Workshops/2026-07-21 Mary-Anderson (2).md` (embed subscriptions on Customer; drop Card / Dashboard; Payment webhooks)
- `Workshops/exercise_templates/journey_mapping.md` (Make → Data / API / UI tickets per step group)
- `tasks/_PLANNING.md` (task file layout for each repo)
- Existing code: `mentorhub_customer_api`, `mentorhub_customer_spa` (template CRUD + working AWS Cognito / IdP redirect)
- Schemas (provisional files; runtime configurator is definitive): `mentorhub_mongodb_api/configurator/dictionaries/*.yaml`

**Actor:** Cat the Customer (paying sponsor).

**How to use:** Each Experience has paste-ready **Issue text** for that repo’s local `tasks/_PLANNING.md`. Complete **Do This First** before filing GitHub issues. Prefer delete+create over rename in the configurator. When dropping a collection, delete **Configuration**, **Dictionary**, and **Test Data** (where present).

**Auth:** **AWS Cognito** is the IdP. Login / password / MFA / Hosted UI are Cognito — do **not** file SPA or API tickets for custom login or signup screens. Customer SPA already redirects via `VITE_IDP_LOGIN_URI` / `redirectToIdpLogin`.

---

## Do This First

Complete these before finalizing ticket text and creating GitHub issues. Research lives in `mentorhub/Research/`.

| # | Research / decision | Why it blocks filing | Owner / notes |
| --- | --- | --- | --- |
| R1 | **AWS Cognito Admin create/update** — exact attributes + how to set **custom claims** (`profile_id`, `customer_id`, `mentor_id`, `roles`) when creating users via Admin API (not Hosted UI self-signup) | Registration → `POST Profile` depends on AdminCreateUser supporting custom claims; Hosted UI self-onboarding does **not** | Open: [F-W04 Cognito Research](https://github.com/mentor-forge/mentorhub/issues/33); document in `Research/` |
| R2 | **Squarespace registration → Google Sheet → script → special POST Profile** — lock form fields, Sheet columns, script auth (service token / shared secret), idempotency (email / row key), failure handling. Optional alternate: Cognito Forms webhook (see `Research/cognito_forms/`) | Defines Profile create contract; Hosted UI self-signup does **not** set MentorHub custom claims | Mike’s planned path; pairs with R1; Cognito Forms research is optional tooling |
| R3 | **Stripe Checkout Session create payload** — Price/Product IDs, quantity, metadata / `client_reference_id`, success/cancel URLs | Blocks Customer.subscriptions[] cart shape + `POST /billing/checkout-session` | Largely in `Research/stripe_research.md`; lock sample payloads |
| R4 | **Stripe webhook event list + JSON shapes** — at least checkout completed, subscription lifecycle, `invoice.paid` / `invoice.payment_failed` | Blocks Payment collection name/schema + test fixtures | Same research file; capture CLI fixtures |
| R5 | **Product / Price catalog** — partner / third-party / individual ↔ Stripe Product+Price IDs | Blocks `GET /plans` and Product dictionary | Stripe Dashboard config + research |
| R6 | **Invite model** — stick with Customer-invited members (name+email)? What roles (`customer` members vs former coordinator)? Seat/capacity coupling? | Blocks invite Data/API/SPA tickets (E4) | Workshop assumed invite; confirm with Mike |
| R7 | **Free trial rules** | Blocks Plans/Trial UI if trial ships in MVP | [#36](https://github.com/mentor-forge/mentorhub/issues/36) |
| R8 | **Misnamed umbrella issues** — mentorhub [#38](https://github.com/mentor-forge/mentorhub/issues/38) `F-UC` and [#39](https://github.com/mentor-forge/mentorhub/issues/39) `F-AC` reverse journey/layer | Rename or close/supersede when filing real `F-CS*` / `F-CA*` issues | CONTRIBUTING: `F-CA` = Customer API, `F-CS` = Customer SPA |

**Schema rule:** Do not change MongoDB dictionaries until R1–R5 findings are recorded and Mike is ready for schema tickets. Fetch definitive schemas from the running configurator per `tasks/_PLANNING.md` (not YAML as write source of truth).

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

Provisional numbers below assume filing in the order listed; adjust if issues land out of order.

### Current schema snapshot (dictionaries — refine tickets against these)

| Dictionary | Path | Properties today (summary) |
| --- | --- | --- |
| **Customer** | `configurator/dictionaries/Customer.0.1.0.yaml` | `_id`, `name`, `description`, `created`, `saved`, `status` (`default_status`) — **no** `subscriptions[]`, **no** `stripe_customer_id` |
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
| Generic Profile GET | API + SPA scaffolding | Keep as base; add special **POST Profile** for registration pipeline (E1) |
| Stripe Checkout / Portal / webhooks | **None** | Net-new tickets |
| Shopping cart / fixed Customer home / invites / GDPR UI button | **None** | Net-new tickets |

Legacy **CRUD scaffolding to remove** (not extend): Card, Dashboard, standalone Subscription list/new/edit; likely Event/Journey/Rating/Note template pages unless a journey screen needs them. Default SPA home today is `/subscriptions` — change after cleanup.

---

## Design principles

| Assumption | Prefer |
| --- | --- |
| Custom SPA/API login or signup screens | **AWS Cognito** Hosted UI / existing SPA IdP redirect only |
| Cognito Hosted UI self-signup sets MentorHub custom claims | **Squarespace form → Google Sheet → script → special POST Profile** + **AWS Cognito Admin API** with custom claims (`profile_id`, `customer_id`, `mentor_id`, `roles`). Optional: Cognito Forms instead of/in addition to Squarespace (research alternate) |
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

1. New Customer fills registration form on the public Squarespace site
2. Form writes a Google Sheet row; configured script calls special POST Profile
   (optional alternate after R2: Cognito Forms JSON webhook — Research/cognito_forms/)
3. Customer API creates Profile (+ Customer org as needed) and AWS Cognito user via Admin API
   with custom claims: profile_id, customer_id, mentor_id, roles (e.g. customer)
   — idempotent on email / Sheet row key (and Entry Id if using Forms webhook)
4. Customer opens Customer SPA → existing auth guards → AWS Cognito login → JWT already has claims
5. Builds shopping cart (offering + capacity + optional discount/donation code)
6. Checkout → POST /billing/checkout-session → Stripe Checkout
7. Stripe → POST /webhooks/stripe → Payment doc + Customer.subscriptions[]
8. Return URL → SPA refetches Customer (do not invent paid from URL)
9. Fixed Customer home (roster/activity); CTA Choose a plan if unsubscribed
10. Invites members (name + email) under invite model (pending R6)
11. Manages billing / capacity via Portal and/or Checkout; webhooks sync
12. Stripe renews (Stripe internals) → same webhook endpoint (invoice.paid | payment_failed)
13. Cancels in Customer Portal → webhook → canceled
14. GDPR forget → SPA Privacy button → API cancels Stripe if needed → redact Profile/Encounter PII
    (no GDPR data property on Customer or Profile)
```

---

## Experience map (cleanup first)

| # | Experience | Intent | Suggested IDs (start) |
| --- | --- | --- | --- |
| **E0** | **Cleanup first** | Remove legacy nav/endpoints/collections + Coordinator microservice | F-CS02, F-CA04, F-D14–16, F-W09 |
| E1 | Register + account (Squarespace → Sheet → Profile → AWS Cognito claims) | Provision Profile/Customer + IdP user with custom claims | F-D21+, F-CA05+, F-CS03+ |
| E2 | First subscription (cart → Checkout → webhook) | First paid entitlement | continues CA/CS/D |
| E3 | View fixed Customer home | Roster/activity gated on subscription | … |
| E4 | Invite members | Customer invites people (name+email) | … |
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

## E1 — Register + account (Squarespace → Sheet → Profile → AWS Cognito claims)

### Actions

1. Prospect fills **registration form on the public Squarespace site**. Fields TBD by R2; align with Profile (`full_name`, `email`, …) and Customer org (`name` / description).
2. Squarespace form is configured to update a **Google Sheet**. A Sheet-bound **script** calls Customer API **special POST Profile** (service auth — not end-user JWT).
3. API creates **Profile** (+ **Customer** as needed), then **AWS Cognito AdminCreateUser** with custom claims: `profile_id`, `customer_id`, `mentor_id`, `roles` (e.g. `["customer"]`). Idempotent on email / Sheet row key.
4. Customer later opens SPA; **existing** guards → **AWS Cognito** login; JWT already has claims.

**Why not Cognito Hosted UI self-signup alone:** it does not support configuring the MentorHub custom claims all APIs require.

**Optional alternate (not primary):** Cognito Forms JSON webhook → same `POST Profile` — see `Research/cognito_forms/cognito_forms_research.md` if tooling changes later.

**Not in this experience:** SPA login/signup screens; Hosted UI self-signup as the way to set custom claims.

### Issue text — Data (`F-D21`)

```text
Title: F-D21: E1 Extend Customer and Profile for Squarespace / Sheet registration provisioning

Description:
Schema + test data for Squarespace → Google Sheet → POST Profile pipeline (no cards; no GDPR
request fields).

Current Customer (Customer.0.1.0.yaml): _id, name, description, created, saved, status only.
Current Profile (Profile.0.1.0.yaml): already has name (IdP username), full_name, email,
email_verified, mentor_id, customer_id, roles (user_roles), plus goals/interests/experience.

Goals:
- Extend Customer only as research requires (e.g. stripe_customer_id placeholder; org display
  may reuse name/description). Do not add person-PII or gdpr_* properties on Customer.
- Confirm Profile covers Squarespace intake fields + AWS Cognito Admin create attributes from
  R1/R2; add only missing attributes. Keep customer_id + roles as the sponsorship link.
- Seed Profiles/Customers for Sheet→POST Profile happy path (roles includes customer;
  customer_id set). Base on test_data/Customer.0.1.0.0.json and Profile.0.1.0.0.json.
- Definitive schemas from running configurator only.

Depends on: Do This First R1–R2.
Coordinate with F-D14 if subscriptions[] lands in same change set.

Context: Workshops/customer_journey_issues.md E1; configurator/dictionaries/Customer.0.1.0.yaml;
configurator/dictionaries/Profile.0.1.0.yaml
```

### Issue text — API (`F-CA05`)

```text
Title: F-CA05: E1 Special POST Profile — Sheet script + AWS Cognito custom claims

Description:
Endpoint for the Google Sheet script after Squarespace registration. Not an end-user signup UI.
Cognito Hosted UI self-onboarding does not set MentorHub custom claims (profile_id, customer_id,
mentor_id, roles) required by all APIs.

Goals:
- Authenticated special POST Profile (service credential): create Profile (+ Customer as designed);
  AWS Cognito AdminCreateUser with custom claims profile_id, customer_id, mentor_id, roles.
- Idempotent on email / Sheet row key; clear error contract for the script.
- Do not implement password reset, MFA, or login APIs — AWS Cognito owns those.
- Document required Squarespace form fields and Sheet columns / payload (R2).
- Optional later: accept the same contract from a Cognito Forms webhook if tooling changes.

Depends on: R1–R2; F-D21.

Context: Workshops/customer_journey_issues.md E1; api_utils JWT claim expectations
```

### Issue text — SPA (`F-CS03`)

```text
Title: F-CS03: E1 Post-auth landing for provisioned accounts

Description:
SPA assumes account already exists via Squarespace → Sheet → POST Profile pipeline.
AWS Cognito handles login UI; existing SPA IdP redirect is sufficient.

Goals:
- After IdP return (existing redirectToIdpLogin / VITE_IDP_LOGIN_URI), load Customer/Profile
  for JWT claims; empty-subscription CTA toward E2 cart.
- Do NOT build Squarespace/registration, login, password-reset, or MFA screens in the SPA.
- Do NOT rework the existing AWS Cognito auth guardrail.

Depends on: E0 SPA cleanup; F-CA05 provisioning in test/dev.

Context: Workshops/customer_journey_issues.md E1
```

---

## E2 — First subscription (cart → Checkout → webhook)

### Actions

1. Builds **shopping cart** — offering, capacity/quantity, optional discount/donation code.
2. Checkout → Customer API creates Stripe Checkout Session → browser to Stripe.
3. Stripe → `POST /webhooks/stripe` → persist Payment + update `Customer.subscriptions[]`.
4. Return success/cancel URL → SPA refetches (never invent Active from URL).

### Issue text — Data (`F-D22`)

```text
Title: F-D22: E2 Product + Payment + Customer.subscriptions[] for Checkout

Description:
Data for first subscribe without storing cards. Builds on Customer.0.1.0.yaml (today has no
subscriptions[] or stripe_customer_id).

Goals:
- Extend Customer with stripe_customer_id and subscriptions[] (status, stripe subscription id,
  price/product refs, quantity/capacity, period end) — not a new top-level Subscription doc
  (F-D14 drops Subscription.0.1.0.yaml stub).
- Add Product dictionary: offerings → Stripe Product/Price IDs (Configuration + Dictionary + Test Data).
- Add Payment dictionary for webhook payloads (name after R4; Configuration + Dictionary + Test Data).
- Seed unsubscribed vs active Customers; do not reintroduce Card fields.
- Fetch/update via running configurator; prefer delete+create over rename.

Depends on: R3–R5; F-D14 drop complete or same coordinated PR.

Context: Workshops/customer_journey_issues.md E2; Research/stripe_research.md;
configurator/dictionaries/Customer.0.1.0.yaml
```

### Issue text — API (`F-CA06`)

```text
Title: F-CA06: E2 Checkout Session + subscribe webhooks

Description:
First paid subscription via Stripe Checkout.

Goals:
- GET /plans (or Product read) for cart.
- POST /billing/checkout-session → { checkout_url } (server-side Price IDs; mode subscription).
- POST /webhooks/stripe: verify signature; idempotent; persist Payment; update subscriptions[].
- GET Customer for JWT owner including subscriptions[].
- No PANs; no trusting success_url as paid.

Depends on: F-D22; R3–R4.

Context: Workshops/customer_journey_issues.md E2
```

### Issue text — SPA (`F-CS04`)

```text
Title: F-CS04: E2 Plans / cart, Checkout redirect, success/cancel

Description:
Cart and Stripe redirect UI (not auth UI).

Goals:
- Plans/cart: offering, capacity, optional code; Checkout CTA.
- Redirect to Stripe; success “Confirming…” then refetch; cancel messaging.
- No card form; no Stripe secrets in SPA; no login screens.

Depends on: F-CA06; E0 cleanup.

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

## E4 — Invite members

Pending **R6**. Workshop: invite with **name + email only**.

### Actions

1. Opens Invite Members page.
2. Submits name + email; API creates invite + (when accepted) Profile linkage under `customer_id` with `roles` via AWS Cognito Admin pattern from E1 where applicable.
3. Lists pending/accepted invites; capacity rules per R6.

### Issue text — Data (`F-D24`)

```text
Title: F-D24: E4 Member invite persistence

Description:
Store Customer-created invites (name, email, status). Prefer embed on Customer or a small
Invite dictionary (R6) — do not overload Profile.experience or Card.

Profile.0.1.0.yaml already links people via customer_id + roles; invites are the
pre-accept record before a Profile exists.

Goals:
- Schema + test data for pending/accepted/revoked invites tied to customer_id.
- If new collection: Configuration + Dictionary + Test Data.
- No GDPR request property on invite or Customer.

Depends on: R6.

Context: Workshops/customer_journey_issues.md E4; Workshops/customer_workshop_2.md Activate
```

### Issue text — API (`F-CA08`)

```text
Title: F-CA08: E4 Invite members API

Description:
Customer-authenticated create/list/revoke invites; provision members per R6 (may reuse AWS
Cognito Admin claim pattern from F-CA05).

Goals:
- POST/GET/(PATCH) invites for JWT customer_id; name + email only on create.
- Enforce seat/capacity rules when R6 defines them.
- No Coordinator microservice; no custom login APIs.

Depends on: F-D24; R6; ideally F-CA05 patterns.

Context: Workshops/customer_journey_issues.md E4
```

### Issue text — SPA (`F-CS06`)

```text
Title: F-CS06: E4 Invite Members page

Description:
UI for Cat to invite members by name and email.

Goals:
- Invite form (name, email); list pending/accepted; revoke if supported.
- Surface capacity errors from API.

Depends on: F-CA08; R6.

Context: Workshops/customer_journey_issues.md E4
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

### Issue text — API (`F-CA09`)

```text
Title: F-CA09: E5 Portal session + capacity-change Checkout

Description:
Manage billing and seat changes.

Goals:
- POST /billing/portal-session → { portal_url }.
- Capacity change via Checkout or Portal config; webhook subscription.updated sync.
- Never store PANs; never collect cards in MentorHub.

Context: Workshops/customer_journey_issues.md E5
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

### Issue text — API (`F-CA10`)

```text
Title: F-CA10: E6 Renewal webhooks + past_due signal (no charge API)

Description:
Handle Stripe-driven renewals only.

Goals:
- invoice.paid / invoice.payment_failed → persist + sync subscriptions[]; expose past_due.
- Idempotent; do not add MentorHub “charge card” API.

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

### Issue text — API (`F-CA11`)

```text
Title: F-CA11: E7 Cancel sync via Portal webhooks

Description:
Primary cancel path is Portal + webhooks; forced Stripe cancel for GDPR is E8.

Goals:
- Update subscriptions[] on subscription.updated/deleted; enforce inactive access.

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
  the action if R1 defines that step.

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

1. **Do This First** R1–R8 (research + rename/close misnamed F-UC / F-AC umbrellas).
2. **E0 Cleanup** — SPA nav/pages → API endpoint removal → Data drops (F-D14/15/16: Configuration + Dictionary + Test Data) → F-W09 Coordinator removal.
3. **E1** Provisioning (Data → API → SPA post-auth landing).
4. **E2** Subscribe (Data → API → SPA).
5. **E3** Fixed home.
6. **E4** Invites (after R6).
7. **E5–E7** Billing change / renew / cancel.
8. **E8** GDPR — **F-CA12 + F-CS10 only** (no F-D property ticket).

When creating tasks in a repo, copy Issue text into that repo’s `_PLANNING.md` workflow → `PENDING.*.md` per local planning layout.

---

## Explicitly out of scope

- SPA/API tickets for login, signup, password reset, or MFA screens (**AWS Cognito** owns auth UI)
- New SPA ticket to rewire IdP/JWT redirect guards (already implemented)
- Cognito Hosted UI self-signup as the source of `profile_id` / `customer_id` / `roles` claims
- Any **GDPR / privacy request data property** on Customer, Profile, or elsewhere
- Treating **Customer** org/billing documents as GDPR person-PII erase targets (Profile ± Encounter only)
- Keeping Coordinator API/SPA
- Configurable Dashboard collection / custom dashboards
- Storing card PANs; MentorHub-initiated recurring charges
- Free-trial product rules until [#36](https://github.com/mentor-forge/mentorhub/issues/36)
- Mentee “pick up studies” and non-Customer tooling
- Live Stripe round-trip on every home page paint
