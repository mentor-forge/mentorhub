# Customer UI — Implementation Issues

**Canonical tickets:** [`customer_journey_issues.md`](./customer_journey_issues.md) (E0–E8 issue text for `_PLANNING.md`).  
This file keeps a schema-aware checklist for SPA / API / Data, updated for Mike’s PR #31 prompts.

Source workshop: `Workshops/customer_workshop_2.md`.  
Research: `Research/stripe_research.md`, `Research/cognito_forms/cognito_forms_research.md`.  
Schemas: `mentorhub_mongodb_api/configurator/dictionaries/` (runtime configurator is definitive).

**Naming (CONTRIBUTING.md):** `Type-UserLayerNumber: title` — **User then Layer**.

| Prefix | Repo | Next number (2026-07-22) |
| --- | --- | --- |
| `F-CS##` | `mentorhub_customer_spa` | F-CS02 |
| `F-CA##` | `mentorhub_customer_api` | F-CA04 |
| `F-D##` | `mentorhub_mongodb_api` | F-D21 (repurpose F-D14/15/16 for drops) |
| `F-W##` | `mentorhub` | F-W09 |

Wrong: `F-UC`, `F-AC`, or `Type-LayerUser##`. Supersede mentorhub [#38](https://github.com/mentor-forge/mentorhub/issues/38) / [#39](https://github.com/mentor-forge/mentorhub/issues/39) when filing.

**Auth:** AWS Cognito. SPA already has IdP redirect (`VITE_IDP_LOGIN_URI`) — **do not** file login/signup/reset/2FA screen tickets.

**Registration:** Cognito Forms (public) → webhook and/or Google Sheet script → special `POST Profile` → AWS Cognito AdminCreateUser with custom claims. Not Hosted UI self-signup for claims.

**GDPR:** UI button + API action. **No** data property. Redact **Profile** (± **Encounter** `transcript`/`summary`/`tldr`). Not Customer org/billing docs.

---

## Cross-cutting

| Name | Issue | Notes |
| --- | --- | --- |
| F-W02 / #36 | Free trial rules | Blocks Plans/Trial if in MVP |
| F-W03 | Stripe research | Checkout + Portal + webhooks |
| F-W04 | AWS Cognito Admin claims research | Required for F-CA05 |
| — | Cognito Forms handoff (R2) | `Research/cognito_forms/` — webhook vs Sheet |
| — | `Profile.customer_id` roster | Already on `Profile.0.1.0.yaml` |

---

## Database (`F-D`) — schema-aware

| Name | Issue | Schema notes |
| --- | --- | --- |
| F-D16 | Drop **Card** | `Card.0.1.0.yaml` has PAN `number` — delete Configuration + Dictionary + `test_data/Card.0.1.0.0.json` |
| F-D15 | Drop **Dashboard** | `Dashboard.0.1.0.yaml` (`customer_id`, stub fields) — no custom dashboards; delete Config + Dictionary |
| F-D14 | Drop top-level **Subscription** | `Subscription.0.1.0.yaml` stub only — embed `subscriptions[]` on Customer later; delete Config + Dictionary |
| F-D21 | Extend **Customer** + confirm **Profile** | Customer today: `_id`, `name`, `description`, `created`, `saved`, `status`. Profile already: `full_name`, `email`, `email_verified`, `customer_id`, `roles`, … — add only gaps from Cognito Forms / Admin research; **no** `gdpr_*` |
| F-D22 | **Product** + **Payment** + `Customer.subscriptions[]` | After Stripe research; Config + Dictionary + Test Data for new collections |
| F-D23+ | Seeds for home / capacity / renew / cancel | Use `Profile.customer_id`; no Dashboard collection |
| F-D24 | Invite persistence (R6) | name, email, status — embed or Invite dictionary |
| — | **GDPR** | **No F-D property ticket** — process redacts existing Profile/Encounter fields |

**Do not:** extend standalone Subscription for lifecycle; extend Dashboard for ROI; add GDPR request field on Customer.

---

## Customer API (`F-CA`)

| Name | Issue | Supports |
| --- | --- | --- |
| F-CA04 | Remove Card / Dashboard / Subscription API surface | E0 cleanup first |
| F-CA05 | Special POST Profile + AWS Cognito Admin claims | Cognito Forms webhook / Sheet script |
| F-CA06 | Checkout Session + subscribe webhooks | E2 |
| F-CA07 | Customer home aggregates + sub gate | E3 |
| F-CA08 | Invite members | E4 (R6) |
| F-CA09 | Portal session + capacity Checkout | E5 |
| F-CA10 | Renewal webhooks + past_due | E6 |
| F-CA11 | Cancel sync via Portal webhooks | E7 |
| F-CA12 | Privacy action — Stripe cancel + redact Profile/Encounter | E8 — no gdpr_* field |

**Out of API scope:** password reset, MFA, custom login sessions (AWS Cognito).

---

## Customer SPA (`F-CS`)

| Name | Issue | Surface |
| --- | --- | --- |
| F-CS02 | Nav + legacy page cleanup | E0 — first |
| F-CS03 | Post-auth landing for provisioned Customer | E1 — **not** signup/login UI |
| F-CS04 | Plans / cart / Checkout return | E2 |
| F-CS05 | Fixed Customer home / mentee activity | E3 |
| F-CS06 | Invite Members (name + email) | E4 |
| F-CS07 | Subscription + Billing (Portal) | E5 |
| F-CS08 | Payment-failed banner | E6 |
| F-CS09 | Cancel + unsubscribed CTA | E7 |
| F-CS10 | Privacy — PII removal **button** | E8 |

**Do not file:** “Cognito sign-in / sign-up integration” replacing login screens (redirect exists); “post-auth company onboarding” that duplicates Cognito Forms registration.

Optional later workshop pages (Find Mentor, Team Progress, ROI, Promos, weekly email) — only after E0–E8 MVP path; name as later `F-CS##` when prioritized.

---

## Suggested build order

1. Do This First research (claims, Cognito Forms handoff, Stripe)  
2. E0 cleanup (SPA → API → Data drops → F-W09 Coordinator removal)  
3. E1 Cognito Forms provisioning  
4. E2 Subscribe → E3 home → E4 invites → E5–E7 billing → E8 privacy  

---

## Out of Customer UI scope

- Mentee “pick up studies”; Dev-Lead organize list  
- Custom auth servers / login / 2FA / password-reset UIs — **AWS Cognito**  
- Card PANs in Mongo; configurable Dashboard collection  
- GDPR request **data property** on Customer or Profile  
- Keeping Coordinator API/SPA  
