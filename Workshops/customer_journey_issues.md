# Customer Journey Issues

Sources:

- `Workshops/customer_workshop_2.md` (User Journey Reflect — experiences, pages, data)
- `Research/stripe_research.md` (Checkout + Customer Portal + webhooks; anti-patterns)
- `Workshops/2026-07-21 Mary-Anderson (2).md` (embed subscriptions on Customer; drop Card / Dashboard; Payment webhooks)
- `Workshops/exercise_templates/journey_mapping.md` (Make → Data / API / UI tickets per step group)
- `tasks/_PLANNING.md` (task file layout for each repo)

**Actor:** Cat the Customer (paying sponsor).  
**Naming:** `Type-UserLayer##` per [CONTRIBUTING.md](../CONTRIBUTING.md) — `F-UC` Customer SPA, `F-AC` Customer API, `F-D` Data, `F-W` / `F-S` Welcome/platform. **Mary assigns `##` when filing.**

**How to use:** Each Experience has paste-ready **Issue text** blocks intended for that repo’s local `tasks/_PLANNING.md` (or for creating `PENDING.*.md` tasks from it). Do **not** change MongoDB schemas until research tickets are ready (Mike, 2026-07-21).

---

## Design principles (draft steps corrected)

| Draft assumption | Prefer |
| --- | --- |
| MentorHub collects card data on a form | **Stripe Checkout** only — no MentorHub card form; drop `Card` |
| Customer API charges the monthly fee | **Stripe Billing** runs renewals; MentorHub only receives **webhooks** |
| Success URL = paid | Success URL is UX only; **webhooks** (or server Session retrieve) update `Customer.subscriptions[]`; SPA **refetches** |
| Cancel by Customer API calling Stripe first | Prefer **Stripe Customer Portal** for cancel / payment-method update; webhooks sync MentorHub. Direct Stripe cancel is still needed for **GDPR offboard** if a subscription may still be active |
| First checkout and renewal use different webhook URLs | Same endpoint: `POST /webhooks/stripe` — different **event types** / payloads |
| Client-supplied unit price is the charge amount | Server maps cart line → configured Stripe **Price ID**; quantity = capacity / seats |
| Configurable Dashboard collection for MVP | **Fixed** Customer dashboard (SPA aggregation); drop `Dashboard` collection |
| Standalone `Subscription` collection | Embed **`subscriptions[]` on Customer**; drop top-level Subscription |

---

## Serialized journey (refined)

```text
1. Opens https://mentorhub.agile-learning.institute → Customer SPA loads
2. SPA security guards validate JWT; if invalid → Cognito Hosted UI → return with valid token
   (roles includes customer; claim customer_id when linked)
3. First-time: Cognito signup (email / username) → post-auth onboarding collects company/org basics
4. Builds shopping cart (offering + capacity/quantity + optional discount/donation code)
5. Checkout → Customer API creates Stripe Checkout Session → browser to stripe.com
6. Stripe → POST /webhooks/stripe (e.g. checkout.session.completed, subscription.*, invoice.paid)
   → persist Payment doc + update Customer.subscriptions[]
7. Return to success/cancel URL → SPA refetches Customer (do not invent paid from URL)
8. Views fixed Dashboard (roster / activity gated on active subscription)
9. Time passes → Stripe renews subscription (Stripe internals, not Customer API)
10. Stripe → same webhook endpoint (invoice.paid | invoice.payment_failed) → persist + sync status
11. Manages billing / changes capacity via Portal and/or new Checkout for seat changes
12. Cancels in Stripe Customer Portal → webhook → subscriptions[] canceled
13. Requests GDPR forget → API cancels any remaining Stripe subscription → redact Profile/Encounter PII
```

---

## Experience map

| # | Experience | Intent |
| --- | --- | --- |
| E1 | Sign up, account, first subscription | Cognito identity + Customer linkage + first paid entitlement |
| E2 | View Dashboard | Fixed home / mentee activity after login |
| E3 | Change subscription | Capacity / plan changes + manage payment method |
| E4 | Recurring charge | Renewal success/failure without Customer-initiated charge |
| E5 | Cancel subscription | Self-serve offboard via Portal + webhook sync |
| E6 | GDPR forget | Cancel Stripe + remove person PII |
| E7 | Cleanup — Coordinator & legacy data | Remove coordinator surfaces; drop Card / top-level Subscription / Dashboard |

---

## E1 — Sign up, new account, new subscription

### Actions

1. Opens Customer SPA (`https://mentorhub.agile-learning.institute`).
2. Security guards validate JWT; redirects to Cognito if invalid; returns with token (`roles: customer`).
3. Completes Cognito signup / login (email, username; password + MFA owned by Cognito).
4. Fills out **post-auth Customer onboarding** — company/org name (and any Profile fields Cognito create/update require).
5. Chooses a plan / builds a **shopping cart** — offering (partner / third-party / individual), **capacity** (mentee seats / quantity), optional discount or donated-capacity code.
6. Clicks **Checkout** — SPA calls Customer API; browser redirects to Stripe Checkout (card collected only on Stripe).
7. Completes or abandons Checkout; returns to success or cancel URL.
8. Stripe asynchronously notifies Customer API; SPA **refetches** Customer until `subscriptions[]` shows Active (or cancelled cart state).

**Data answers (from workshop + research):**

| Question | Answer |
| --- | --- |
| Basic information? | Cognito: email, username (+ MFA/password in Cognito). Post-auth: **company/org name**; Profile holds Cognito attributes research identifies. Shipping address TBD — not required for MVP Checkout. |
| New subscription cart data? | Product/offering id → Stripe **Price ID** (server-side), **quantity** (capacity), optional promo/donation token, `client_reference_id` / metadata = MentorHub Customer `_id`. |
| Async method / data? | `POST /webhooks/stripe` — at least `checkout.session.completed`, `customer.subscription.created`/`updated`, `invoice.paid`; verify signature; persist payload; upsert `Customer.subscriptions[]` + `stripe_customer_id`. |

### Issue text — Data (`mentorhub_mongodb_api` / `F-D`)

```text
Title: F-D## E1 Customer + Product + Payment for first subscribe

Description:
Support first-time Customer signup and first subscription without storing cards.

Goals:
- Extend Customer for org/payer fields, stripe_customer_id, and embedded subscriptions[]
  (status, stripe subscription id, price/product refs, quantity/capacity, current_period_end).
- Add Product dictionary mapping partner / third-party / individual offerings → Stripe Product/Price IDs.
- Add Payment (name TBD after webhook research) dictionary for Stripe webhook payloads.
- Ensure Profile can store Cognito create/update attributes and customer_id linkage.
- Seed test data: unsubscribed Customer; active after checkout; matching Profile.

Do not edit schemas until Stripe/Cognito research findings are recorded. Fetch definitive
schemas from the running configurator per tasks/_PLANNING.md. Prefer delete+create over rename
when replacing Card/Subscription/Dashboard later (see E7).

Context: Workshops/customer_journey_issues.md E1; Research/stripe_research.md; Workshops/customer_workshop_2.md
```

### Issue text — API (`mentorhub_customer_api` / `F-AC`)

```text
Title: F-AC## E1 Post-Cognito provisioning + Checkout Session + subscribe webhooks

Description:
Enable Cat to become a Customer and purchase a first subscription via Stripe Checkout.

Goals:
- After Cognito JWT: provision/link Profile + Customer (company/org); require customer role.
- GET /plans (or Product read) for cart UI — map offerings to Stripe Price IDs from config/DB.
- POST /billing/checkout-session: accept cart (price mapping + quantity + optional code);
  ensure Stripe Customer; create Checkout Session (mode: subscription); return { checkout_url }.
- POST /webhooks/stripe: verify signature; idempotent; persist Payment; update Customer.subscriptions[].
- GET Customer for JWT owner including subscriptions[] (SPA refetch after return).
- Never accept card PANs; never trust success_url as paid; secret keys only on API.

Context: Workshops/customer_journey_issues.md E1; Research/stripe_research.md
```

### Issue text — SPA (`mentorhub_customer_spa` / `F-UC`)

```text
Title: F-UC## E1 Auth return, onboarding, cart, Checkout redirect, success/cancel

Description:
Customer SPA surfaces for first login through first paid subscription.

Goals:
- Load SPA; JWT guards → Cognito Hosted UI / Amplify when invalid; land with customer role.
- Post-auth onboarding form: company/org (and required Profile fields) — not custom password/2FA pages.
- Plans / shopping cart page: offering, capacity, discount/donation code; Checkout CTA.
- POST checkout-session → redirect to Stripe; handle success (“Confirming…” then refetch) and cancel.
- Do not invent Active from URL alone; display only Customer API subscription state.
- No card form; no Stripe secret key in SPA.

Context: Workshops/customer_journey_issues.md E1; Research/stripe_research.md UI phase tables
```

---

## E2 — View Dashboard

### Actions

1. Lands on fixed **Customer home / Dashboard** after login (configurable `Dashboard` collection is out for MVP).
2. If no active subscription → CTA **Choose a plan** (links to E1 cart).
3. If subscribed → views mentee roster / activity summary (resources completed, notes, encounters) appropriate to Customer role.
4. May drill into mentee detail later (workshop pages); MVP gate: premium views require active `subscriptions[]`.

### Issue text — Data (`F-D`)

```text
Title: F-D## E2 Dashboard read-model via existing collections (no Dashboard dictionary)

Description:
Support a fixed Customer dashboard without a configurable Dashboard collection.

Goals:
- Confirm mentee roster via Profile.customer_id (and related Mentee/Encounter/Event/Note shapes).
- Seed test data linking Customer → Profiles → mentee activity enough for Dashboard list + empty states.
- Do not revive Dashboard.0.1.0 for MVP; drop is tracked in E7.

Context: Workshops/customer_journey_issues.md E2; Workshops/customer_workshop_2.md Monitor needs
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E2 Customer dashboard aggregates + subscription gate

Description:
APIs the fixed Customer Dashboard needs after login.

Goals:
- Return Customer.subscriptions[] so SPA can show subscribed vs Choose-a-plan.
- Aggregate mentee activity for JWT Customer (resources completed, notes, encounters) — 403 if not active where product rules require it.
- No live Stripe round-trip per page load; read MongoDB state only.

Context: Workshops/customer_journey_issues.md E2
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E2 Fixed Customer Dashboard / Mentee Activity home

Description:
Default home after login for Cat the Customer.

Goals:
- Shell + home: if no active subscription, CTA Choose a plan; else mentee roster/activity.
- Gate premium UI on API-returned subscription status.
- Align nav with Customer journey destinations only (see E7 SPA cleanup).

Context: Workshops/customer_journey_issues.md E2; Workshops/customer_workshop_2.md UI checklist
```

---

## E3 — Change subscription

### Actions

1. Opens **Subscription** / **Billing** surfaces from Dashboard.
2. Changes capacity (add/remove mentee seats) — MentorHub cart describes the change; Checkout Session or Portal flow per Stripe config.
3. Opens **Manage billing** → Customer API creates **Billing Portal** session → Stripe Portal for payment method (and plan changes Portal allows).
4. Returns to SPA; SPA refetches Customer; webhooks keep `subscriptions[]` accurate.
5. Optional later: hold / delay payment / promos (workshop) — defer until product rules exist; do not invent Stripe APIs prematurely.

### Issue text — Data (`F-D`)

```text
Title: F-D## E3 Subscription capacity / status fields on Customer.subscriptions[]

Description:
Data needed when Cat changes plan capacity or billing details.

Goals:
- Ensure subscriptions[] can represent quantity/capacity changes, status transitions, and Stripe ids after Portal/Checkout updates.
- Seed Customers with mid-lifecycle states (active with N seats; pending capacity change if needed).
- Product/Price mappings cover upgrade/downgrade offerings used by cart.

Context: Workshops/customer_journey_issues.md E3; Research/stripe_research.md
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E3 Portal session + capacity-change Checkout

Description:
API support for manage-billing and capacity changes.

Goals:
- POST /billing/portal-session → { portal_url } for payment method / Portal-managed changes.
- Support capacity change via Checkout Session (or documented Portal configuration) without client-trusted prices.
- Webhooks: customer.subscription.updated (and related) update Customer.subscriptions[].
- Prefer Portal for card updates; never store PANs.

Context: Workshops/customer_journey_issues.md E3
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E3 Subscription + Billing pages (capacity change, Manage billing)

Description:
UI for changing seats and opening Stripe Customer Portal.

Goals:
- Subscription page: show plan, capacity, status from API; actions to change capacity.
- Billing page: Manage billing → portal-session redirect; return + refetch.
- Payment-failed entry point can deep-link here (shared with E4).

Context: Workshops/customer_journey_issues.md E3
```

---

## E4 — Recurring charge

### Actions

1. A billing period elapses — **Stripe** charges the saved payment method (**Stripe internals**, not Customer API).
2. Stripe calls the **same** `POST /webhooks/stripe` with renewal outcomes:
   - Success: typically `invoice.paid` (+ subscription status remains active).
   - Failure: `invoice.payment_failed` → mark `past_due` (or agreed status); persist attempt.
3. SPA shows **payment failed** banner / notification when status is past_due; CTA to Manage billing (E3 Portal).
4. Customer does not need to be online for the charge; UI only reflects synced state on next visit.

**Same method, similar data?** Same webhook endpoint and verification. Different event types / `data.object` shapes (Invoice vs Checkout Session). Persist both in Payment (or webhook-events) collection for cross-customer reporting.

### Issue text — Data (`F-D`)

```text
Title: F-D## E4 Payment persistence for invoice.paid and invoice.payment_failed

Description:
Store renewal success and failure webhook payloads for reporting and SPA banners.

Goals:
- Payment schema supports Invoice-shaped webhook payloads (paid + failed), linked by customer_id / stripe ids.
- Seed past_due Customer + failed Payment docs; seed successful renewal Payment docs.
- Customer.subscriptions[] status values include past_due (or equivalent).

Context: Workshops/customer_journey_issues.md E4; Research/stripe_research.md webhooks table
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E4 Renewal webhooks + past_due signal (no charge API)

Description:
Handle Stripe-driven renewals without MentorHub initiating charges.

Goals:
- On invoice.paid: persist Payment; confirm active on Customer.subscriptions[].
- On invoice.payment_failed: persist failure; set past_due; expose signal for SPA/email.
- Do not add an API that “charges the card”; Stripe owns recurrence.
- Idempotent webhook handling (no double-apply).

Context: Workshops/customer_journey_issues.md E4
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E4 Payment-failed banner / notification

Description:
Surface renewal failure when Customer returns to the SPA.

Goals:
- In-app banner when subscriptions[] / billing signal is past_due; CTA Manage billing (Portal).
- Optional copy hook for email notification (email job may live outside SPA).
- Never invent failure state client-side.

Context: Workshops/customer_journey_issues.md E4
```

---

## E5 — Cancel subscription

### Actions

1. Chooses cancel from Billing / Cancel flow.
2. Preferred path: **Stripe Customer Portal** (already used in E3) — user cancels there.
3. Stripe → webhook `customer.subscription.updated` / `deleted` → Customer API updates `subscriptions[]` to canceled/ended; persist webhook doc.
4. SPA refetches → Resubscribe CTA; hide premium UI; API enforces 403 on gated resources.
5. **Direct API cancel of Stripe subscription** is optional for in-app cancel without Portal; not required if Portal is the only cancel UX. Required path for forced cancel is E6 GDPR.

### Issue text — Data (`F-D`)

```text
Title: F-D## E5 Canceled subscription states + test data

Description:
Represent post-cancel Customer state for SPA and access control.

Goals:
- subscriptions[] supports canceled/ended (+ period end if useful).
- Seed canceled Customer for Resubscribe UI and 403 tests.

Context: Workshops/customer_journey_issues.md E5
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E5 Cancel via Portal webhooks (+ optional API cancel)

Description:
Keep MentorHub in sync when Cat cancels.

Goals:
- Rely on Portal + webhooks as primary cancel path; update Customer.subscriptions[].
- Optional: server-side Stripe subscription cancel endpoint if product requires in-app cancel without Portal.
- Enforce inactive access (403) on premium resources after cancel.

Context: Workshops/customer_journey_issues.md E5
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E5 Cancel flow + unsubscribed CTA

Description:
Self-serve cancel and return to unsubscribed home.

Goals:
- Cancel entry → Portal (preferred) or confirmed in-app cancel if API supports it.
- After return/refetch: show Resubscribe / Choose a plan; hide premium nav.

Context: Workshops/customer_journey_issues.md E5
```

---

## E6 — GDPR forget

### Actions

1. Opens **Account / Privacy** and requests removal of all person PII (workshop: Stacey GDPR).
2. Customer API **cancels any remaining Stripe subscriptions / recurring charges** for the linked `stripe_customer_id` (needed even if UI cancel was skipped).
3. Customer API (and data process) **redacts/anonymizes Profile and Encounter PII** (and related person-scoped fields). Org billing history in Payment may retain non-PII financial records per policy — do **not** model GDPR as a long-lived flag on the Customer commerce document.
4. SPA shows request submitted / completed status; session ends or loses customer access as designed.

### Issue text — Data (`F-D`)

```text
Title: F-D## E6 GDPR deletion/anonymization of Profile (and Encounter) PII

Description:
Data support for right-to-be-forgotten without PCI card stores.

Goals:
- Define which Profile/Encounter fields are PII and anonymization rules.
- Track request status only if ops need it (Profile or audit/Event) — not a Customer commerce field.
- Seed Profile suitable for forget dry-run tests; ensure Card collection is gone (E7) so no PANs remain.

Context: Workshops/customer_journey_issues.md E6; Workshops/customer_ui_implementation_issues.md Privacy notes
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E6 Privacy request: cancel Stripe + redact PII

Description:
Orchestrate GDPR forget for the authenticated Customer’s people/PII.

Goals:
- Endpoint to request forget: cancel active Stripe subscriptions for stripe_customer_id;
  redact Profile/Encounter PII per data rules; return status.
- Do not require SPA to call Stripe; secrets stay on API.
- Document retention of Payment webhook docs (financial, non-PII) vs person PII.

Context: Workshops/customer_journey_issues.md E6
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E6 Account / Privacy — request PII removal

Description:
UI for GDPR forget request and status.

Goals:
- Account / Privacy page: clear action to request PII removal; show status; no Customer commerce editor.
- Confirm destructive intent; then call privacy API; handle logged-out / restricted aftermath.

Context: Workshops/customer_journey_issues.md E6
```

---

## E7 — Cleanup: Coordinator references & legacy collections

### Actions (platform / data hygiene)

1. Remove **coordinator_api / coordinator_spa** from MentorHub local/dev surfaces (welcome links, compose, personas) — Mike must confirm before deleting remote repos.
2. Clean Customer SPA **navigation** of legacy CRUD (Subscriptions list, Dashboards, Cards, etc.) in favor of journey destinations.
3. Data: **delete** Card, top-level Subscription, Dashboard dictionaries/config/test data; subscriptions live on Customer; payments/webhooks in Payment; cards only in Stripe.
4. Hold off deleting Customer SPA/API repos until Mike finishes Customer ↔ Coordinator UI/API reflection (roles still split: only Customer role subscribes).

### Issue text — Data (`F-D`)

```text
Title: F-D## E7 Drop Card, top-level Subscription, Dashboard; keep Customer.subscriptions[]

Description:
Configurator hygiene after Stripe research direction is accepted.

Goals:
- Delete Card dictionary/config/test data (PCI anti-pattern).
- Delete top-level Subscription after Customer.subscriptions[] is in place.
- Delete Dashboard dictionary for MVP (fixed SPA dashboard).
- Prefer delete + create over rename; fetch schemas from running configurator only.

Context: Workshops/customer_journey_issues.md E7; Research/stripe_research.md; 2026-07-21 encounter
```

### Issue text — API (`F-AC`)

```text
Title: F-AC## E7 Remove Card/Subscription/Dashboard API surface; billing on Customer + Payment

Description:
Stop exposing dropped collections; billing via Customer + Payment only.

Goals:
- Remove OpenAPI/routes/tests for Card, standalone Subscription, Dashboard if present.
- Ensure Checkout/Portal/webhooks hang off Customer + Payment as in E1–E6.
- Do not delete customer API repo pending Mike’s journey-merge decision.

Context: Workshops/customer_journey_issues.md E7
```

### Issue text — SPA (`F-UC`)

```text
Title: F-UC## E7 Customer SPA nav cleanup (drop legacy Coordinator-era CRUD)

Description:
Align drawer/routes with Customer journey only.

Goals:
- Replace legacy nav (Subscriptions/Dashboards/Cards/Events/Profiles CRUD, etc.) with
  Dashboard, Plans/Cart, Billing/Subscription, Mentors/Invites, Account/Privacy.
- Remove coordinator-only entry points if any remain in this SPA.
- Keep Admin (role-gated) and Logout.

Context: Workshops/customer_journey_issues.md E7; Workshops/customer_workshop_followup_issues.md
```

### Issue text — Welcome / platform (`F-W` / `F-S`)

```text
Title: F-W## / F-S## Remove coordinator_api and coordinator_spa references from mentorhub

Description:
Strip local/dev and docs pointers to coordinator services.

Goals:
- Remove welcome/index.html links, welcome-auth.js coordinator personas if obsolete,
  DeveloperEdition/docker-compose.yaml coordinator_api/spa services and depends_on,
  workspace/docs mentions of those images/repos.
- Coordinate with Mike before deleting remote GitHub repos; this ticket is mentorhub
  reference + compose cleanup only.

Context: Workshops/customer_journey_issues.md E7; Workshops/customer_workshop_followup_issues.md
```

---

## Suggested filing / planning order

1. **E7 Data (drops)** only after E1 Customer.subscriptions[] / Payment / Product shapes are agreed — or sequence: research → E1 Data → E7 drops.
2. **E1** Data → API → SPA (auth, cart, Checkout, webhooks).
3. **E2** Dashboard gate + aggregates.
4. **E3** Portal + capacity change.
5. **E4** Renewal webhooks + past_due banner.
6. **E5** Cancel sync.
7. **E6** GDPR.
8. **E7** SPA nav + Welcome coordinator cleanup (SPA nav can start early in parallel with E1).

When creating tasks in a repo, copy the relevant **Issue text** into `tasks/_PLANNING.md` workflow and produce `PENDING.*.md` files per that repo’s `_PLANNING.md` layout (Status, Type, Depends On, Context, Goals, Testing Expectations, Outputs, Execution Notes).

---

## Explicitly out of scope (for these tickets)

- Free-trial product rules — [#36](https://github.com/mentor-forge/mentorhub/issues/36)
- Merging Customer + Coordinator into one UI/API — Mike reflecting; do not delete Customer SPA/API yet
- Custom password / MFA backends — Cognito only
- Storing card PANs in MongoDB
- Configurable Dashboard collection for MVP
- Mentee “pick up studies” and Dev-Lead mentee organize tooling — other personas
- Live Stripe calls on every Dashboard paint
