# Customer Workshop Follow-up Issues

**Canonical detailed tickets:** [`customer_journey_issues.md`](./customer_journey_issues.md) (Experiences E0–E8, paste-ready issue text, Do This First).  
This file is a short index aligned with Mike’s PR #31 review prompts and research.

Sources:

- `Workshops/customer_journey_issues.md` (primary)
- `Research/stripe_research.md`
- `Research/cognito_forms/cognito_forms_research.md` (Cognito Forms registration — not AWS Cognito IdP)
- `configurator/dictionaries/*.yaml` in `mentorhub_mongodb_api` (schema-aware F-D work)

**Naming (CONTRIBUTING.md):** `Type-UserLayerNumber: title` — journey then layer.

| Prefix | Meaning | Next (as of 2026-07-22) |
| --- | --- | --- |
| `F-CS##` | Customer SPA | **F-CS02** (after F-CS01) |
| `F-CA##` | Customer API | **F-CA04** (after F-CA03) |
| `F-D##` | Data | **F-D21** net-new; repurpose open **F-D14/15/16** for Subscription/Dashboard/Card drops |
| `F-W##` | Welcome / mentorhub | **F-W09** (Coordinator removal) |

Do **not** use `F-UC` / `F-AC` (reversed). Rename/close mentorhub [#38](https://github.com/mentor-forge/mentorhub/issues/38) / [#39](https://github.com/mentor-forge/mentorhub/issues/39) when filing real issues.

**Auth:** AWS Cognito IdP. Existing SPA `VITE_IDP_LOGIN_URI` / `redirectToIdpLogin` is sufficient — **no** login/signup screen tickets.

**GDPR:** SPA button + API action only. **No** GDPR data property. Person PII on **Profile** (± **Encounter** transcript/summary/tldr), not Customer org/billing.

**Configurator drops:** delete **Configuration**, **Dictionary**, and **Test Data**.

---

## Do This First (before filing GitHub issues)

See full table in `customer_journey_issues.md`. At minimum:

1. AWS Cognito Admin custom claims research (F-W04)
2. Cognito Forms handoff choice (webhook vs Sheet+script) — `Research/cognito_forms/`
3. Stripe Checkout / webhook / Product-Price research — `Research/stripe_research.md`
4. Confirm invite model (R6); free trial (#36)

---

## Filing order (cleanup first)

1. **E0** — `F-CS02` SPA nav/page cleanup → `F-CA04` remove Card/Dashboard/Subscription APIs → `F-D14/15/16` drop those collections (Config+Dict+Test Data) → `F-W09` remove Coordinator API+SPA  
2. **E1** — Cognito Forms → `F-CA05` special POST Profile + AWS Cognito Admin claims → `F-D21` Customer/Profile → `F-CS03` post-auth landing (no signup UI)  
3. **E2+** — Subscribe / home / invites / billing / renew / cancel / GDPR per `customer_journey_issues.md`

---

## Customer SPA (`F-CS`) — index

| ID | Title | Notes |
| --- | --- | --- |
| F-CS02 | E0 nav and legacy page cleanup | Remove Subscriptions/Dashboards/Cards CRUD; keep AWS Cognito redirect |
| F-CS03 | E1 post-auth landing | No Cognito Forms / login / signup screens |
| F-CS04 | E2 Plans/cart + Checkout redirect | Stripe only |
| F-CS05 | E3 Fixed Customer home | Not Dashboard collection |
| F-CS06 | E4 Invite Members | name + email (R6) |
| F-CS07–09 | E5–E7 Billing / past_due / cancel | Portal preferred |
| F-CS10 | E8 Privacy button | Calls API; no GDPR field |

**Do not file:** Cognito Hosted UI signup integration; post-login company onboarding forms that duplicate Cognito Forms registration.

---

## Customer API (`F-CA`) — index

| ID | Title | Notes |
| --- | --- | --- |
| F-CA04 | E0 remove Card/Dashboard/Subscription APIs | |
| F-CA05 | E1 special POST Profile | Cognito Forms webhook and/or Sheet script; AdminCreateUser claims |
| F-CA06–11 | E2–E7 Checkout, Portal, webhooks, cancel | See journey doc |
| F-CA12 | E8 Privacy action | Redact Profile/Encounter; cancel Stripe; **no** gdpr_* property |

**Do not file:** custom login/password/MFA APIs.

---

## Data (`F-D`) — index (schema-aware)

| ID | Title | Current schema basis |
| --- | --- | --- |
| F-D16 | Drop Card Config+Dict+Test Data | `Card.0.1.0` stores PAN `number` — PCI |
| F-D15 | Drop Dashboard Config+Dict(+Test Data) | `Dashboard.0.1.0` — no custom dashboards |
| F-D14 | Drop Subscription Config+Dict(+Test Data) | `Subscription.0.1.0` stub → embed on Customer |
| F-D21 | Extend Customer + Profile for registration | Customer: `_id,name,description,status,breadcrumbs` only today; Profile already has `email`, `full_name`, `customer_id`, `roles` |
| F-D22+ | Product, Payment, `Customer.subscriptions[]`, seeds | After Stripe research |

**No F-D for GDPR request property.**

---

## Welcome (`F-W09`)

Remove Coordinator microservice (API + SPA) from compose, welcome links, personas, docs; archive remotes per Mike.

---

## Out of scope

- Login/signup/MFA screens (AWS Cognito)
- GDPR data property on Customer/Profile
- Keeping Coordinator API/SPA; configurable Dashboard collection
- Card PANs in MongoDB
