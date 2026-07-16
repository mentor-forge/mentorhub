# Customer UI — Implementation Issues

Source: Customer Workshop 2 (`Workshops/customer_workshop_2.md`).  
Scope: Customer SPA, Customer API, and MongoDB (`configurator/dictionaries`).  
Naming: `Type-LayerUser##` per [CONTRIBUTING.md](../CONTRIBUTING.md) (e.g. `F-UC` Customer SPA, `F-AC` Customer API, `F-D` Data). **Mary assigns `##` from existing repo issues.**  
Auth: **AWS Cognito** is the IdP — do not build custom password/2FA backends.  
Existing workshop follow-ups: [#36](https://github.com/mentor-forge/mentorhub/issues/36) trial · [#38](https://github.com/mentor-forge/mentorhub/issues/38) SPA · [#39](https://github.com/mentor-forge/mentorhub/issues/39) API · [#40](https://github.com/mentor-forge/mentorhub/issues/40) data.

---

## Cross-cutting

| Name (Mary numbers) | Issue | Notes |
|---------------------|--------|--------|
| F-W02 / #36 | Define free trial rules | Blocks Plans/Trial |
| — | Agree Customer ↔ Profile ↔ seat model | `Profile.customer_id` already links people to a Customer |
| — | Stripe Checkout + Portal + webhooks (F-W03) | Shared by API + data; prefer Stripe over `Card` collection for payment methods |

---

## Database (`mentorhub_mongodb_api`)

Schemas reviewed under `configurator/dictionaries/` (Customer, Subscription, Profile, Mentee, Note, Rating, Encounter, Event, Journey, Dashboard, Card).

| Name (Mary numbers) | Issue | Schema-aware notes |
|---------------------|--------|-------------------|
| F-D## / #40 | Extend **Customer** (`Customer.0.1.0`) for payer/org fields | Today: `_id`, `name`, `description`, `status`, breadcrumbs only. Add org/company display and Stripe customer id as needed. **Do not** add a GDPR-request property on Customer (see Privacy). |
| F-D## | Extend **Subscription** (`Subscription.0.1.0`) for lifecycle | Today: stub (`_id`, `name`, `description`, `status`/`default_status`, breadcrumbs). Add `customer_id`, capacity/seats/schedule, trial/active/hold/cancel (new enums if needed), discount/token refs, Stripe subscription id, failure/delay flags synced from webhooks. |
| F-D## | Coordinator invite persistence | No Invite collection today. New dictionary **or** embed on Customer; fields: name, email, status. |
| F-D## | Confirm mentee roster via existing **Profile.customer_id** | Already on `Profile.0.1.0`. Prefer this over a new link table unless seats need their own membership docs. |
| F-D## | Customer → mentor focus notes | `Mentee.0.1.0` has mentor `notes` / `focus`; `Note.0.1.0` is **resource-scoped** (`resource_id`). Decide: extend Mentee (e.g. customer-authored focus) vs new shape — do not overload resource Notes. |
| F-D## | Mentor (person) rating for mentee detail | `Rating.0.1.0` is **resource-scoped** (`resource_id`). Workshop “rating of the mentor” needs a new model or agreed reuse — not the resource Rating as-is. |
| F-D## | Discount / donated-capacity tokens | No Token collection. Fields on Subscription and/or small Token dictionary; redemptions tied to Customer/Subscription. |
| F-D## | Extend **Dashboard** (`Dashboard.0.1.0`) for ROI / weekly summary (optional) | Already has `customer_id`. Extend only if Team Progress / Program ROI / weekly email need a read model vs live aggregates from Encounter/Event/Journey. |
| F-D## | Customer subscription test data | Seed Customer + Subscription (+ Profiles with `customer_id`) for trial, active, hold, failed-payment scenarios. Align with existing Profile/Mentee/Encounter test data. |
| — | **Privacy / GDPR (data)** | GDPR applies to **person PII** on **Profile** (and possibly **Encounter** transcript/summary), not to Customer org/billing documents. Prefer deletion/anonymization **process** over a long-lived “GDPR request” field on Customer. Track request state only if ops need it (e.g. on Profile or an audit/Event), not as Customer commerce data. |

---

## Customer API (`F-AC` — Layer Api, User Customer)

| Name (Mary numbers) | Issue | Supports |
|---------------------|--------|----------|
| F-AC## / #39 | Customer API from Workshop 2 (umbrella) | epic |
| F-AC## | Post-Cognito Customer + Profile provisioning | After Cognito signup/login JWT: ensure Profile (claims: `name`, email, `email_verified`) and Customer org linkage (`Profile.customer_id`) |
| F-AC## | Subscription / Billing API | Checkout, Billing, Subscription, Cancel, Promos |
| F-AC## | Stripe Checkout session + return handling | Subscribe / Checkout |
| F-AC## | Stripe Customer Portal session | Billing / payment method (not custom card APIs; avoid `Card` PCI store) |
| F-AC## | Stripe webhooks (idempotent; no double-charge) | Sync Subscription (+ failure flags) |
| F-AC## | Trial start / eligibility (after #36) | Plans / Trial |
| F-AC## | Capacity change, hold, delay payment, cancel | Subscription / Billing / Cancel |
| F-AC## | Apply discount / donated-capacity codes | Checkout |
| F-AC## | Coordinator invite create/list; self-mark coordinator role | Invite Coordinator (`Profile.roles`) |
| F-AC## | Available mentors + match-by-needs | Find Mentor |
| F-AC## | Team progress + mentee activity (aggregate) | Dashboard, Team Progress |
| F-AC## | Mentee detail aggregate (Encounter `tldr`/`summary`, Mentee notes, Events, ratings) | Mentee Detail |
| F-AC## | Post customer note for mentor | Mentee Detail |
| F-AC## | Program ROI / status summary | Program ROI |
| F-AC## | Privacy: request PII removal (Profile / Encounter) | Account / Privacy — action + workflow, not Customer field |
| F-AC## | Payment-failed signal for notify | Notifications |
| F-AC## | Weekly progress summary payload (email job) | Weekly Progress Email |

**Out of API scope (Cognito owns):** password reset, MFA/2FA challenge, credential storage, custom login session APIs.

---

## Customer SPA (`F-UC` — Layer UiUx, User Customer)

| Name (Mary numbers) | Issue | Page / surface |
|---------------------|--------|----------------|
| F-UC## / #38 | Customer SPA from Workshop 2 UI checklist (umbrella) | epic |
| F-UC## | Cognito sign-in / sign-up integration (Hosted UI or Amplify) | Replace custom Login / Reset / 2FA screens; Cognito handles password reset and MFA |
| F-UC## | Post-auth Customer onboarding (company / org fields) | Collect company name etc. after Cognito identity exists; wire to Customer + Profile |
| F-UC## | Plans / Trial page | blocked on #36 |
| F-UC## | Subscribe / Checkout + Stripe return URLs | capacity, codes, pay |
| F-UC## | Invite Coordinator page | name + email only |
| F-UC## | Find Mentor / Available Mentors | choose by needs |
| F-UC## | Dashboard / Mentee Activity | roster + activity |
| F-UC## | Team Progress page | Dave persona |
| F-UC## | Program ROI / Status page | Stacey / board |
| F-UC## | Mentee Detail page | drill-down + leave mentor note |
| F-UC## | Billing page | delay pay, failures; Portal for payment method |
| F-UC## | Subscription page | seats, hold |
| F-UC## | Promos page | long-tenure promos |
| F-UC## | Cancel flow | |
| F-UC## | Account / Privacy — request PII removal | UI button calling privacy API (Profile/Encounter), not a Customer data editor |
| F-UC## | Payment-failed notification UI (and/or email copy) | |
| F-UC## | Weekly Progress Email template (no-login) | may be API/email only |

---

## Suggested build order

1. Data: extend Customer + Subscription; confirm Profile.customer_id roster  
2. API: Cognito JWT → Profile/Customer provisioning + Subscription/Billing + Stripe  
3. SPA: Cognito auth integration → Checkout → Billing/Subscription  
4. Data/API: Invites, mentor match  
5. API/SPA: Dashboard, Mentee Detail, notes, ROI  
6. Trial (#36), Promos, Privacy (Profile/Encounter), notifications/email  

---

## Out of Customer UI scope (workshop)

- Mentee Journey / “pick up studies” — Mentee product (`Journey` collection)  
- Dan’s mentee organize list — Coordinator / Mentor tooling  
- Custom auth servers or login/2FA/password-reset APIs — **AWS Cognito**  
- Storing payment cards in Mongo `Card` — use Stripe  
- GDPR request flag on **Customer** documents — PII lives on **Profile** / **Encounter**  
