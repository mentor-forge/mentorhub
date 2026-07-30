# Customer Journey Issues — Adjustments for Admin & Discovery Domains

**Purpose:** Recommended updates to [`customer_journey_issues.md`](./customer_journey_issues.md) and its filed GitHub issues, given new **Admin** ([F-W13](https://github.com/mentor-forge/mentorhub/issues/36)) and **Discovery** ([F-W14](https://github.com/mentor-forge/mentorhub/issues/38)) domains, cross-SPA plumbing ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)), and shared-library prerequisites ([F-UA12](https://github.com/mentor-forge/mentorhub_api_utils/issues/25), [F-UA08](https://github.com/mentor-forge/mentorhub_api_utils/issues/17)).

**Audience:** Planning agents filing or refining journey issues. Apply these as edits to issue bodies in GitHub and to paste-ready text in `customer_journey_issues.md`.

---

## Executive summary

The current customer journey assumes **Customer API owns ingress** (Cognito Post Confirmation, Stripe webhooks) and **Customer SPA owns post-auth landing and home**. Admin and Discovery domains split those responsibilities:

| Concern | Current journey | Target (Admin / Discovery) |
| --- | --- | --- |
| External webhooks (Stripe, Cognito triggers) | `F-CA05`, `F-CA06`, `F-CA09` in Customer API | **Admin API ingress** — verify, normalize, provision identities, append **ExternalEvent** / **Event** |
| Business reactions (subscriptions[], invites, GDPR) | Same Customer API handlers | **Customer API consumers** — read events / call domain services; no webhook signature logic |
| Post-login landing | Customer SPA (`F-CS03`, `F-CS05`) | **Discovery SPA** (`F-DS01`) — universal dashboard / search |
| Notifications (invite, payment reminder, past_due) | Implicit in Customer home / SPA | **Producer:** Customer (and others) write **Notification** docs; **Discovery** owns dismiss UX and card presentation |
| Product catalog admin | Not explicit; catalog in `F-D22` | **Admin SPA** — `ProductsListPage` per F-US09 |
| Per-SPA nav / cross-port links | Each SPA keeps its own nav | **spa_utils** universal frame + cross-repo links (`F-US09`) |
| RBAC list filtering | Ad hoc per service | **api_utils** standard inbound/outbound filters (`F-UA12`) |
| Collection name constants | Per-service init | **api_utils** Config constants pattern (`F-UA08`) |

Several journey tickets are still valid but need **scope moves**, **new dependencies**, or **splitting**. At least one **new Data ticket** must cover **event type enumerators** and cross-domain event schemas.

---

## Prerequisites to add globally

Add to the **Locked decisions** and **Suggested implementation order** sections of `customer_journey_issues.md`:

### Shared libraries (before domain feature work)

| Issue | Repo | Blocks |
| --- | --- | --- |
| [F-UA08](https://github.com/mentor-forge/mentorhub_api_utils/issues/17): Config constants | `mentorhub_api_utils` | All new domain APIs (Admin, Discovery, Customer refactors) |
| [F-UA12](https://github.com/mentor-forge/mentorhub_api_utils/issues/25): RBAC pattern | `mentorhub_api_utils` | Discovery list APIs (`F-DA01`), Customer home aggregates (`F-CA07`), invite/list endpoints (`F-CA08`) |
| [F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26): Cross-repo linking + universal nav | `mentorhub_spa_utils` | All SPAs including Customer (`F-CS02`+), Discovery (`F-DS01`), Admin |

**Recommendation:** Insert a **Phase 0 — Platform plumbing** before E0:

1. F-UA08 → F-UA12 (api_utils; can overlap if constants land first)
2. F-US09 (spa_utils)
3. F-W13 / F-W14 design issues → file concrete Admin + Discovery bootstrap tickets (see [New issues to add](#new-issues-to-add-not-in-customer_journey_issuesmd))

### Terminology: Customer vs Organization

[F-W13](https://github.com/mentor-forge/mentorhub/issues/36) uses **Organization** as the aggregate root provisioned at onboarding. The journey doc and dictionaries still use **Customer**.

**Recommendation:** Pick one name for the bounded domain and dictionary before E1 data work (`F-D21`). Until renamed:

- Issue text should say **Customer (Organization)** where provisioning vs enrichment is discussed.
- Admin ingress provisions **Organization/Customer** + **Profile** in `provisioned` state; Customer API **enriches** (name, subscriptions[], billing fields).

Document the decision in locked decisions; do not split provisioning across two collection names.

---

## New issues to add (not in customer_journey_issues.md)

These should be created from [F-W13](https://github.com/mentor-forge/mentorhub/issues/36) and [F-W14](https://github.com/mentor-forge/mentorhub/issues/38) and cross-linked from the journey doc.

| Proposed ID | Repo | Title (short) | Notes |
| --- | --- | --- | --- |
| **F-W18** | `mentorhub` | Bootstrap Admin + Discovery repos (copy + refactor) | [mentorhub#52](https://github.com/mentor-forge/mentorhub/issues/52) — copy sources in admin_journey_issues.md |
| **F-AA-L001** | `mentorhub_admin_api` | Admin API — planning pass | Per `_PLANNING.md`; ingress routes only for MVP |
| **F-AS-L001** | `mentorhub_admin_spa` | Admin SPA — planning pass | Products, Config, notification create (admin scope) |
| **F-DA-L001** | `mentorhub_discovery_api` *(or `discover_api`)* | Discovery API — planning pass | Align repo name with F-W14 before filing |
| **F-DS-L001** | `mentorhub_discovery_spa` | Discovery SPA — planning pass | Default post-login landing |
| **F-AA01** | `mentorhub_admin_api` | Ingress — Stripe + Cognito webhooks | Signature verify, normalize payload, provision Profile + Org, append ExternalEvent |
| **F-AA02** | `mentorhub_admin_api` | Ingress — immutable event recording | ExternalEvent + Event write paths; no business workflows |
| **F-DA01** | `mentorhub_discovery_api` | Discovery search/list API | Profiles, Customers/Orgs, Notifications; RBAC via F-UA12 |
| **F-DS01** | `mentorhub_discovery_spa` | Discovery landing — polymorphic cards | CardGrid + cross-SPA links via F-US09 |
| **F-SD01** | `mentorhub_mongodb_api` | Notifications + card type schemas | Filed as **F-D29** [mongodb_api#61](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/61) — see [Data — event types & schemas](#f-d-new--event-types--cross-domain-schemas) |

Use naming from F-W14 (`F-DA` / `F-DS`) for Discovery API/SPA repos (`mentorhub_discovery_*`).

---

## Cross-cutting adjustments

### Auth and landing

- **Do not** build Customer SPA as the default post-auth home. After IdP login, route to **Discovery** (`Home → Discovery:Discovery` per F-US09).
- **F-CS03** becomes “post-auth handoff” (ensure JWT claims loaded, redirect to Discovery or deep link), not a standalone home page.
- **F-W10** `login.html`: default `return_to` / success navigation should target Discovery SPA base URL, not Customer SPA.

### Ingress vs domain logic

Apply this split to **E1**, **E2**, **E4**, **E5–E7**, **E8**:

```text
External system → Admin ingress (verify, provision, record event)
                       ↓
              Customer API (or async consumer) applies business rules
                       ↓
              Optional: write Notification for Discovery
```

Customer API **must not** expose public unauthenticated webhook routes in production once Admin ingress exists. Local dev (`stripe-mock`, `REGISTRATION_DEV_MODE`) may keep thin dev proxies that **call the same ingress service layer** for parity.

### Notifications

Add to journey principles:

- **Write:** Customer API (invite sent, subscription activated, past_due, cancel) and Admin SPA (admin-scoped broadcasts) create **Notification** documents.
- **Read / dismiss:** Discovery API owns dismiss mutation; Discovery SPA renders cards.
- Remove any assumption that Customer home lists “activity” as the primary notification surface — **F-CS05** focuses on **org-scoped roster/commerce**, not platform-wide “what needs attention.”

### Coordinator role

**F-W09** removes Coordinator microservice; **F-W14** card schema still lists `Profile (Coordinator)`.

**Recommendation:** Drop coordinator card type and `coordinator` from Discovery MVP scope; keep `user_roles.coordinator` in Profile enum only until a follow-on removes it from data + Cognito claims.

### api_utils gaps the journey missed

| Gap | Where it shows up | Adjustment |
| --- | --- | --- |
| No shared **outbound filter** builder | `F-CA07`, `F-CA08`, `F-DA01` profile/customer lists | Block on **F-UA12**; reference standard filter composition in API issue goals |
| **NotificationService** / **ExternalEventService** | Admin + Discovery | Add harvest tickets to api_utils after F-SD01 schemas stabilize (follow-on to F-UA08) |
| **ProfileService** RBAC is mentor/admin-centric | Customer member lists, Discovery “see own + org” | F-UA12 should define customer-scoped read rules; Customer/Discovery APIs use shared helper, not copy-paste `_check_permission` |
| Config collection names scattered | All APIs | F-UA08 before new Admin/Discovery API bootstrap |

### spa_utils gaps the journey missed

| Gap | Where it shows up | Adjustment |
| --- | --- | --- |
| Cross-port JWT / return URL | Checkout success, Portal return, invite links | **F-US09** prerequisite for **F-CS04**, **F-CS06**, **F-CS07** |
| Universal hamburger replaces per-SPA nav | **F-CS02** “Keep Admin (role-gated)” | Move admin-only pages to **Admin SPA**; Customer E0 removes local admin nav in favor of universal nav |
| **NotificationsNewPage** hosted per SPA | F-US09 table | Customer SPA keeps a **create notification** route for customer role; list/dismiss lives in Discovery |
| Polymorphic **CardGrid** link targets | Discovery cards linking to Customer/Mentor/Admin | Depends on F-US09 `CrossRepoLink` helper |

---

## Per-issue adjustments

### Framework bootstrap

| Issue | Adjustment |
| --- | --- |
| **F-CA-L001** | Add context: F-W13 ingress split, F-UA08/F-UA12, Consumer pattern for Stripe/Cognito events. Tasks must not plan webhook routes on Customer API except dev parity shims. |
| **F-CS-L001** | Add context: F-US09, F-W14. Post-auth landing is Discovery, not Customer. Plan tasks for commerce/roster UX only. |

### E0 — Cleanup

| Issue | Adjustment |
| --- | --- |
| **F-CS02** | Remove “Keep Admin (role-gated)” — admin UI moves to Admin SPA. Remove standalone nav; universal frame from spa_utils. Temporary home → redirect stub to Discovery or `/` placeholder until F-DS01. Trim Event/Journey/Rating/Note only if Discovery replaces those entry points. |
| **F-CA04** | If template CRUD included admin-only Product routes, delete them here; Products live under Admin API later. |
| **F-D-E0** | Unchanged for Card/Dashboard/Subscription drop. Add note: do not delete **Event** dictionary — it becomes more important for ingress. |
| **F-W09** | Add: wire Discovery + Admin repos into welcome portal when F-W15 lands; remove coordinator from universal nav table (F-US09). |

### E1 — Primary self-registration

| Issue | Adjustment |
| --- | --- |
| **F-S01** | Post Confirmation Lambda → **Admin ingress** (`F-AA01`), not `F-CA05` directly. Pre Token Generation unchanged. IAM: Admin API needs Cognito Admin + Mongo write for provisioned identities. |
| **F-D21** | Add **provisioned** status (or enum) for Profile + Customer/Organization on ingress-created docs. Seed provisioned + enriched examples. Depends on F-SD01 event-type review if `arrived` / new types added. |
| **F-CA05** | **Rename scope:** “Enrich provisioned org + profile after ingress” — not create-from-scratch on raw Cognito callback. Production: consume ingress event or idempotent GET-by-sub. Dev: `REGISTRATION_DEV_MODE` may still call shared **provisioning service** used by Admin ingress. Depends on **F-AA01**, F-D21. Still owns Cognito attribute sync when `COGNITO_ENABLED`. |
| **F-CS03** | Change goals: verify claims + subscription CTA via link to Customer SPA **or** Discovery card; default redirect to Discovery. Handle provisioning lag with retry against Profile GET. |

### E2 — First subscription

| Issue | Adjustment |
| --- | --- |
| **F-D22** | **Split concern:** Product + Discount dictionaries shared with **Admin** (catalog CRUD). Customer.subscriptions[] + Payment remain Customer journey. Payment fields still derived from Stripe payloads. Add dependency on F-SD01 for webhook-related event types. Admin SPA owns Product seed/edit UI — not Customer SPA. |
| **F-CA06** | Remove `POST /webhooks/stripe` from Customer API goals. Add: **checkout-session** + **plans** + **event consumer** that updates `subscriptions[]`, Payment, discount redemption on `checkout.session.completed` / subscription events delivered via Admin ingress. Depends on **F-AA01**, F-D22, F-UA12. |
| **F-CS04** | Add depends on **F-US09** (return URLs across SPAs). Success/cancel routes may live on Customer SPA but should link back to Discovery + refetch Customer. |

### E3 — Customer home

| Issue | Adjustment |
| --- | --- |
| **F-D23** | Narrow scope: test data for **Customer SPA roster/commerce views**, not platform dashboard. Encounter/Event activity for mentee list under a Customer org — not Discovery notification cards. |
| **F-CA07** | Scope as **org admin read API** (roster, subscription gate for Customer-scoped routes). Use F-UA12 outbound filters. Discovery may duplicate aggregate read patterns later — avoid building a second dashboard API here. |
| **F-CS05** | Not the default app home. **Customer org management home** (Choose a plan vs roster). Entry via universal nav “[Customer Name]” / Members links (F-US09). Depends on F-DS01 for default landing. |

### E4 — Invite members

| Issue | Adjustment |
| --- | --- |
| **F-D24** | Add optional **Notification** seed when invite created (for Discovery card). |
| **F-CA08** | After invite: write **Notification** (scope: profile or customer). Cognito AdminCreateUser still Customer API (or Admin if centralized — pick one; recommend Customer owns invite business rules, Admin only for ingress provisioning on *external* signup). Depends on F-UA12, F-SD01. |
| **F-CS06** | Entry via universal nav. Cross-SPA link from Discovery notification to this page. Depends on F-US09. |

### E5–E7 — Billing lifecycle

| Issue | Adjustment |
| --- | --- |
| **F-D-E5E7** | Include Notification test fixtures (past_due, cancel). |
| **F-CA09** | Same ingress split as F-CA06: invoice/portal webhooks → Admin; Customer API consumer updates status + emits Notifications. Portal session endpoint stays Customer API. |
| **F-CS07** | Portal return URLs via F-US09. Past_due banner may appear on Discovery **and** Customer SPA — prefer single Notification source rendered on Discovery. |

### E8 — GDPR

| Issue | Adjustment |
| --- | --- |
| **F-CA12** | Cognito `AdminDeleteUser` may move to Admin API (identity operations). If split: Customer API orchestrates redaction; Admin ingress/API executes IdP delete. Document event `profile_redacted` in F-SD01. |
| **F-CS10** | Privacy entry under Customer or Profile edit linked from universal nav; destructive confirm unchanged. |

### F-W10 — Local dev mocks

| Issue | Adjustment |
| --- | --- |
| **F-W10** | Register/join/update tabs call **Admin ingress dev endpoints** (or shared provisioning module) so local path matches prod. stripe-mock webhooks → Admin ingress URL. Default login redirect → Discovery SPA. Coordinate with F-AA01 dev mode. |

---

## Data — event types & cross-domain schemas

### New ticket: **F-D25** (or extend **F-SD01**)

**Title:** Review and extend event types + cross-domain event schemas for Admin & Discovery

**Repo:** `mentorhub_mongodb_api`

**Why:** [Event.0.1.0.yaml](../mentorhub_mongodb_api/configurator/dictionaries/Event.0.1.0.yaml) uses `event_types` enum ([enumerations.0.yaml](../mentorhub_mongodb_api/configurator/enumerators/enumerations.0.yaml)) oriented to mentee/mentor activity (`login`, `completed`, `encounter`, …). Admin ingress and Discovery need explicit types and likely new dictionaries.

**Goals:**

1. **Review `event_types`** — add values such as (names illustrative; finalize in implementation):
   - `external_received` — raw normalized external payload reference
   - `identity_provisioned` — Profile and/or Organization created by ingress
   - `organization_enriched` — Customer domain filled business fields
   - `subscription_changed` — checkout, invoice, cancel, past_due
   - `invite_created` / `invite_accepted`
   - `notification_created` / `notification_dismissed`
   - `payment_recorded`
   - `profile_redacted` (GDPR)

2. **ExternalEvent dictionary** (append-only) — payload hash, source (`stripe` \| `cognito`), external id, normalized body reference, created breadcrumb.

3. **Notification dictionary** (F-W14) — scope enum (`all`, `customer`, `mentor`, `profile`), target ids, dismiss state, message fields, link metadata for Discovery cards.

4. **Card polymorphic schema** — configurator-only (version `-1` / non-persisted) for Discovery UI types listed in F-W14; prevent accidental collection creation.

5. **Profile / Customer status** — support `provisioned` → `active` lifecycle from F-W13.

6. **Test data** — at least one ExternalEvent + Event chain per new type; Notifications for invite and past_due.

**Depends on:** F-D-E0 (avoid conflicting drops). **Blocks:** F-AA01, F-AA02, F-DA01, F-CA05, F-CA06, F-CA09.

**Note:** Merge with F-W14’s **F-SD01** if that issue is filed first — one data ticket should own Notifications + event schema work to avoid duplication.

---

## Suggested revised implementation order

```text
Phase 0 — Platform plumbing
  F-UA08, F-UA12 (api_utils)
  F-US09 (spa_utils)
  F-W13/F-W14 → F-W15, F-AA-L001, F-AS-L001, F-DA-L001, F-DS-L001

Phase 1 — Ingress + data foundation
  F-D-E0 (drops)
  F-D25 / F-SD01 (event types, ExternalEvent, Notification, card schemas)
  F-AA01, F-AA02 (Admin ingress)
  F-W09 (coordinator removal)
  F-CS02, F-CA04 (E0 cleanup — aligned with new nav)

Phase 2 — Discovery shell
  F-DA01, F-DS01 (MVP landing + lists)
  F-S01 (Cognito → Admin ingress)

Phase 3 — Customer journey ( revised )
  E1: F-D21, F-CA05, F-CS03, F-W10
  E2: F-D22, F-CA06, F-CS04 (+ Admin SPA product admin when catalog UI needed)
  E3: F-D23, F-CA07, F-CS05
  E4: F-D24, F-CA08, F-CS06
  E5–E7: F-D-E5E7, F-CA09, F-CS07
  E8: F-CA12, F-CS10
```

---

## Checklist for updating `customer_journey_issues.md`

- [ ] Add Phase 0 prerequisites (F-UA08, F-UA12, F-US09, Admin/Discovery bootstrap).
- [ ] Document Customer vs Organization naming decision.
- [ ] Add ingress vs consumer diagram to design principles.
- [ ] Replace “Customer SPA post-auth home” with Discovery landing + Customer org pages.
- [ ] Split webhook ownership out of F-CA05 / F-CA06 / F-CA09 issue text.
- [ ] Add F-D25 / F-SD01 event schema ticket under Data section.
- [x] Add “New domains” section — moved to `admin_journey_issues.md` and `discovery_journey_issues.md` (F-AA / F-DA / F-DS).
- [ ] Update F-CS02, F-S01, F-W10, F-CS03, F-CS05 paste-ready issue bodies.
- [ ] Add api_utils follow-on note: harvest Notification/ExternalEvent services after schemas ship.
- [ ] Remove coordinator from Discovery MVP references; align with F-W09.

---

## References

| Item | Link |
| --- | --- |
| Admin domain design | [mentorhub#36 — F-W13](https://github.com/mentor-forge/mentorhub/issues/36) |
| Discovery domain design | [mentorhub#38 — F-W14](https://github.com/mentor-forge/mentorhub/issues/38) |
| Cross-SPA linking | [mentorhub_spa_utils#26 — F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26) |
| RBAC pattern | [mentorhub_api_utils#25 — F-UA12](https://github.com/mentor-forge/mentorhub_api_utils/issues/25) |
| Config constants | [mentorhub_api_utils#17 — F-UA08](https://github.com/mentor-forge/mentorhub_api_utils/issues/17) |
| Task file layout | [`tasks/_PLANNING.md`](../tasks/_PLANNING.md) |
| Customer journey issues (source) | [`customer_journey_issues.md`](./customer_journey_issues.md) |
