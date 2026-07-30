# Discovery Journey Issues

Sources:

- [F-W14: Design Discovery Domain](https://github.com/mentor-forge/mentorhub/issues/38) — architectural decisions below
- `Workshops/customer_journey_issues_adjustments.md`
- [F-W18: Bootstrap repos](https://github.com/mentor-forge/mentorhub/issues/52) — copy sources in [admin_journey_issues.md](./admin_journey_issues.md)
- [F-US09 Cross-repo linking](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)
- [F-UA12 RBAC pattern](https://github.com/mentor-forge/mentorhub_api_utils/issues/25), [F-UA08 Config constants](https://github.com/mentor-forge/mentorhub_api_utils/issues/17)
- `Workshops/customer_journey_issues.md` (Customer journey — writes Notifications; Discovery presents)
- `Workshops/admin_journey_issues.md` (Admin — operator-facing; Discovery — user-facing)
- `tasks/_PLANNING.md` (task file layout for each repo)

**Actor:** Any authenticated platform user — Discovery is the **front door** (default post-login landing).

**How to use:** Paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md`. Do not reference specific task filenames here.

**Related journeys:** [admin_journey_issues.md](./admin_journey_issues.md), [customer_journey_issues.md](./customer_journey_issues.md).

**Repo bootstrap:** Discovery repos are **created in F-W18** by copying **`mentorhub_customer_api`** (API) and **`mentorhub_mentee_spa`** (SPA). Discovery API inherits customer/profile list patterns but must plan **api-utils 0.2→0.5** migration during strip. See [admin_journey_issues.md — Copy sources](./admin_journey_issues.md#copy-sources-locked).

---

## Locked decisions (Discovery domain — F-W14)

**Discovery vs Search:** The bounded domain is **Discovery** (not a standalone Search microservice name). Issue IDs use **F-DA** / **F-DS**; repos use **`mentorhub_discovery_*`**. Full-text **search indexing** is **future** — not MVP.

**Consume, do not own.** Discovery helps users **find, navigate, and be informed** about information that already exists. It owns the **UX** around discovery — not Customer, Profile, Organization, or other business aggregates.

**Default post-login landing.** After IdP login, users arrive at **Discovery SPA** (`F-DS01`), not Customer or Mentee home. Other domains are reached via universal nav ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)) or card deep links.

**Mission-control dashboard (MVP).** The landing page is a **polymorphic CardGrid** of:

- **Notifications** — “what needs my attention?”
- **Customers (Organizations)** — orgs the user can see
- **Profiles** — people the user can see (including self)

MVP includes **Notifications + Customers + Profiles** cards. **Recently viewed**, **recommended actions**, and **rich search** are **future** (see [Explicitly out of scope](#explicitly-out-of-scope-future)).

**Notifications contract:**

| Responsibility | Owner |
| --- | --- |
| **Write** Notification documents | Producer domains (Customer API, Mentor API, Admin SPA, …) |
| **Present** + **dismiss** UX | Discovery API (`PATCH` dismiss) + Discovery SPA |
| **Admin suppression** of notifications | **Future** — not MVP |

Examples producers should emit (via Customer journey and others): new invitation, payment reminder, apprentice task completed, organization approval, new review.

**Cross-SPA navigation.** Cards link into the correct SPA and route (Profile, Organization/Customer, Learning Plan, …) using **F-US09** cross-repo linking. Discovery does not own destination pages.

**Human-centered vs Admin.** Discovery answers *“What do I need to do?”* Admin answers *“How is the system operating?”* ([admin_journey_issues.md](./admin_journey_issues.md)).

**Coordinator role.** **Omit** `Profile (Coordinator)` card type and coordinator-specific Discovery MVP scope — aligned with **F-W09** Coordinator microservice removal.

**Pagination (MVP — locked).** Use the **hybrid** approach from F-W14 workshop:

1. **Always return all Notifications and all visible Customers** for the caller (typically small sets).
2. **Paginate Profiles only** (cursor/offset via standard list query utilities).
3. **Sort:** Notifications by **newest first** (event time or `created`); Customers by **`name`**; Profiles with **caller’s own profile first**, then others by **newest related activity** descending.

Alternative designs (single merged paginated stack; separate fully paginated endpoints for each collection) are **deferred** — revisit if admin users hit scale limits.

**Single-result forward.** If the dashboard query yields **exactly one** navigable card, **redirect** to that card’s target SPA/route without rendering an intermediate profile card shell.

**Create notification UI** lives on **Admin, Customer, and Mentor SPAs** (role-scoped) — **not** on Discovery SPA. Discovery is read/dismiss for notifications in MVP.

**Card type schema.** Polymorphic card types are defined in the **Configurator** as a **non-persisted** schema (orphan / version `-1` pattern) — not a MongoDB collection. Implemented in **F-D29**.

**Data ticket naming.** F-W14 originally used **F-SD01** for Discovery data; filed as **F-D29** in `mentorhub_mongodb_api` (shared with Admin ingress event schemas). One data ticket owns Notification + card types + `event_types` extensions.

---

## Design principles

| Assumption | Prefer |
| --- | --- |
| User thinks in domains (“Open Customer SPA”) | **Discovery** as front door — “Show me Mike”, “What needs attention?” |
| Discovery owns Profile/Customer documents | **Consume** via API reads + RBAC filters; producers own writes |
| Notification business events | **Write** in producer domain; Discovery **dismiss** only |
| Search indexing / Elasticsearch | **Future**; MVP = filtered lists + card dashboard |
| Pagination complexity | **API-owned** sort/filter; SPA renders CardGrid from F-DA01 aggregate |
| Card CRUD in MongoDB | **No** — polymorphic card types are configurator-only |
| Coordinator personas | **Dropped** from MVP card catalog |

---

## Polymorphic card types (MVP catalog)

Configurator-only schema (**F-D29**). Types map to cross-SPA link templates ([F-US09](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)).

| Card type | Source data | Typical link target |
| --- | --- | --- |
| **Customer (Mine)** | Customer org for JWT `customer_id` | Customer SPA org home |
| **Customer (Other)** | Customer visible via RBAC | Customer SPA (if permitted) |
| **Profile (Me)** | Caller’s Profile | Profile view / edit in owning SPA |
| **Profile (Mentor)** | Profiles linked via `mentor_id` | Mentor SPA context |
| **Profile (Mentee)** | Mentee profiles visible to mentor/customer | Mentee SPA context |
| **Profile (Customer)** | Profiles with `customer` role in org | Customer SPA members |
| **Notification (Global)** | Scope `all` | In-app target from `link_metadata` |
| **Notification (Customer)** | Scope `customer` + id | Customer SPA route |
| **Notification (Mentor)** | Scope `mentor` + id | Mentor SPA route |
| **Notification (Profile)** | Scope `profile` + id | Profile route |

**Not in MVP:** `Profile (Coordinator)` (removed).

---

## RBAC — Profile and Customer visibility (MVP)

Discovery API list endpoints use **F-UA12** outbound filter composition:

| Caller | Customers | Profiles |
| --- | --- | --- |
| Any authenticated user | — | Own Profile always |
| `customer_id` claim set | Own Customer org | Profiles with same `customer_id` |
| `mentor_id` claim set | — | Mentee profiles linked to mentor (per domain rules) |
| `admin` role | All (non-archived) | All (non-archived) |

**Get-by-id** must pass the same filter (post-fetch deny if no match). Admin role sees everything for support/ops.

---

## Long-term vision (future — not filed as MVP tickets)

Discovery becomes a major **event consumer** when the platform moves beyond MongoDB-as-bus:

```text
Profile Updated        → refresh profile cards / search index
Organization Created   → add Customer card
Learning Path Assigned → surface notification
Review Completed       → refresh recommendations
```

Implement after MVP dashboard ships; do not block **F-DA01** / **F-DS01** on indexing infrastructure.

---

## Naming (CONTRIBUTING.md)

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-DA##` | **D**iscovery **A**pi | `mentorhub_discovery_api` |
| `F-DS##` | **D**iscovery **S**pa | `mentorhub_discovery_spa` |
| `F-D##` | **D**ata (mongodb configurator — no layer letter) | `mentorhub_mongodb_api` |

Legacy F-W14 labels **F-SS01** / **F-SA01** / **F-SD01** map to **F-DA01** / **F-DS01** / **F-D29** respectively.

### Next numbers (provisional)

| Prefix | Next to assign | Notes |
| --- | --- | --- |
| `F-DA` | **F-DA01** | Discovery list + dismiss API |
| `F-DS` | **F-DS01** | Landing CardGrid |
| `F-D` | **F-D29** ([#61](https://github.com/mentor-forge/mentorhub_mongodb_api/issues/61)) | Notification + card schemas (+ Admin ExternalEvent) |

---

## Experience map

| # | Experience | Intent | Suggested IDs |
| --- | --- | --- | --- |
| **D0** | Bootstrap (with Admin) | Copy discovery_api + discovery_spa in **F-W18** | F-W18 |
| D1 | Data — Notification + card schemas | Configurator + test data | F-D29 |
| D2 | Discovery API — dashboard aggregate | Lists, sort, pagination, dismiss | F-DA01 |
| D3 | Discovery SPA — landing | CardGrid, cross-SPA links, single-forward | F-DS01 |
| D4 | Create notification (elsewhere) | Admin / Customer / Mentor SPAs write Notifications | F-AS##, F-CS##, F-RS## (not Discovery) |

---

## Suggested implementation order

1. **F-W18** — Copy discovery repos ([admin_journey_issues.md](./admin_journey_issues.md)).
2. **F-D29** — Notification dictionary, card polymorphic schema, `event_types`.
3. **F-UA12**, **F-US09** — RBAC filters + cross-repo links.
4. **F-DA-L001** / **F-DS-L001** — planning passes in new repos.
5. **F-DA01** — Discovery list/dismiss API (`discovery_service` layer).
6. **F-DS01** — Discovery landing SPA (default post-login).
7. Producer notification writes — Customer journey (**F-CA08**, **F-CA06**, …) and Admin SPA when filed.

---

## Issue text — Data (`F-D29`)

```text
Title: F-D29: Event types, ExternalEvent, Notification, and Discovery card schemas

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Cross-domain schemas for Admin ingress and Discovery. Supersedes F-W14 F-SD01 naming.
Extends Event.event_types beyond mentee/mentor activity.

Goals:
- Notification dictionary: scope enum (all, customer, mentor, profile), target ids,
  message, link_metadata for cross-SPA routes, dismiss state, created breadcrumb.
- Card polymorphic schema (configurator-only, non-persisted, version -1 pattern) per
  Workshops/discovery_journey_issues.md card type catalog; omit Coordinator.
- Review event_types for ingress, subscription, invite, notification, GDPR (Admin).
- ExternalEvent dictionary for Admin ingress (append-only).
- Profile / Customer provisioned → active lifecycle support.
- Test data: Notification fixtures (invite, payment reminder, past_due); card chain samples.

Depends on: F-D-E0 (customer journey E0 drops, if coordinated).
Blocks: F-AA01, F-AA02, F-DA01, F-CA05, F-CA06, F-CA08, F-CA09.
Context: mentorhub#38 F-W14; Workshops/discovery_journey_issues.md
```

---

## Issue text — API planning pass (`F-DA-L001`)

```text
Title: F-DA-L001: Discovery API — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_api

Description:
First planning pass for Discovery API work. Read Workshops/discovery_journey_issues.md
and create appropriately scoped task files under tasks/.

Architecture: discovery_service aggregates Notifications, Customers, Profiles for dashboard;
owns dismiss mutation only. RBAC via F-UA12.

Depends on: F-W18 (repo exists); _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-UA12, F-D29.
Blocks: F-DA01 and later F-DA* feature issues.
```

---

## Issue text — SPA planning pass (`F-DS-L001`)

```text
Title: F-DS-L001: Discovery SPA — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_spa

Description:
First planning pass for Discovery SPA work. Read Workshops/discovery_journey_issues.md and F-US09
(Home → Discovery; cross-repo card links).

Depends on: F-W18 (repo exists); _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-US09 (spa_utils).
Blocks: F-DS01 and later F-DS* feature issues.
```

---

## Issue text — Discovery API (`F-DA01`)

```text
Title: F-DA01: Discovery dashboard API — Notifications, Customers, Profiles

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_api

Description:
Discovery bounded domain API per F-W14 (mentorhub#38). Implements discovery_service layer
that returns polymorphic card payload for the landing dashboard. Filter/order in API.

Goals:
- GET dashboard aggregate (or parallel GETs): Notifications, Customers, Profiles per RBAC.
- Sort: Notifications newest first; Customers by name; Profiles — own first, then by activity.
- Pagination MVP: return all Notifications + Customers; paginate Profiles only (locked).
- PATCH notification dismiss (Discovery owns dismiss mutation; writes by producer domains).
- F-UA12 outbound filters: own profile, customer_id scope, mentor_id scope, admin all.
- OpenAPI documents card payload shapes aligned with F-D29 polymorphic card types.
- Do not implement search indexing, notification create, or business domain writes.

Depends on: F-D29; F-UA12; F-W18; api-utils 0.5.x migration if copied from customer_api.
Blocks: F-DS01.
Context: mentorhub#38 F-W14; Workshops/discovery_journey_issues.md
```

---

## Issue text — Discovery SPA (`F-DS01`)

```text
Title: F-DS01: Discovery landing — polymorphic CardGrid and cross-SPA links

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_spa

Description:
Default post-login landing per F-W14 and F-US09. Mission-control CardGrid: Notifications,
Customers, Profiles. spa_utils CardGrid + cross-repo link helper.

Goals:
- Landing route as platform home after IdP login (coordinate welcome/login.html F-W18).
- Render polymorphic cards from F-DA01; map card types to SPA routes via F-US09.
- Notification dismiss UX (calls Discovery API dismiss).
- Single-result forward: one card → navigate directly without intermediate shell.
- Load-more or pager for Profiles only; Notifications and Customers render in full.
- Do not implement notification create (Admin/Customer/Mentor SPAs).
- Omit coordinator card type.

Depends on: F-DA01; F-US09; F-W18.
Context: mentorhub#38 F-W14; Workshops/discovery_journey_issues.md
```

---

## Explicitly out of scope (future)

- **Search indexing** / universal cross-domain full-text search
- **Saved searches**, favorites, dashboard layout preferences
- **Search history** and personalized recommendations
- **Recently viewed objects** (until explicit ticket)
- **Recommended actions** engine
- **Admin notification suppression** (ops override)
- **Notification create UI** on Discovery SPA
- **Coordinator** card type and Coordinator SPA links
- **Owning** Customer, Profile, or Organization write APIs — stay in domain APIs
- **MongoDB Event consumer workers** for index refresh — post-MVP event bus work

---

## Explicitly out of scope (other domains)

| Capability | Owner |
| --- | --- |
| Write Notification content | Customer API, Mentor API, Admin SPA, … |
| Customer org commerce / billing UI | Customer SPA |
| Ingress / webhooks | Admin API ([admin_journey_issues.md](./admin_journey_issues.md)) |
| Products catalog admin | Admin SPA |
