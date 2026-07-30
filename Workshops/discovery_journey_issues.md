# Discovery Journey Issues

Sources:

- [F-W14: Design Discover Domain](https://github.com/mentor-forge/mentorhub/issues/38)
- `Workshops/customer_journey_issues_adjustments.md`
- [F-US09 Cross-repo linking](https://github.com/mentor-forge/mentorhub_spa_utils/issues/26)
- [F-UA12 RBAC pattern](https://github.com/mentor-forge/mentorhub_api_utils/issues/25)
- `tasks/_PLANNING.md` (task file layout for each repo)

**Actor:** Any authenticated user — Discovery is the platform **front door** (default post-login landing).

**How to use:** Paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md`.

**Scope:** Discovery owns **find, navigate, and be informed** — dashboard/home, notifications UX, polymorphic cards, cross-SPA linking. Discovery **consumes** data from other domains; it does not own Customer, Profile, or business aggregates.

**Related journeys:** [admin_journey_issues.md](./admin_journey_issues.md), [customer_journey_issues.md](./customer_journey_issues.md).

**Repo bootstrap:** Discovery repos are **created in F-W18** by copying **`mentorhub_customer_api`** (API) and **`mentorhub_mentee_spa`** (SPA) — see [admin_journey_issues.md — Copy sources](./admin_journey_issues.md#copy-sources-locked). Discovery API inherits customer/profile routes but must plan **api-utils 0.2→0.5** migration during strip.

## Naming (CONTRIBUTING.md)

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-DA##` | **D**iscovery **A**pi | `mentorhub_discovery_api` |
| `F-DS##` | **D**iscovery **S**pa | `mentorhub_discovery_spa` |
| `F-D##` | **D**ata (mongodb configurator) | `mentorhub_mongodb_api` |

Discovery API/SPA use the **D**iscovery user letter (`F-DA`, `F-DS`). Dictionary/schema tickets in `mentorhub_mongodb_api` use **`F-D##`** (Data — no layer letter), e.g. **F-D29** below.

---

## Suggested implementation order

1. **F-W18** — Copy, strip, rename four repos + Developer Edition wiring ([admin_journey_issues.md](./admin_journey_issues.md) — **copy sources table**).
2. **F-D29** — Notification, card schemas, event_types extension.
3. **F-UA12**, **F-US09** — RBAC + cross-repo linking prerequisites.
4. **F-DA-L001** / **F-DS-L001** — planning passes.
5. **F-DA01** — Discovery list API.
6. **F-DS01** — Discovery landing SPA (default post-login home).

---

## Issue text — Data (`F-D29`)

```text
Title: F-D29: Event types, ExternalEvent, Notification, and Discovery card schemas

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_mongodb_api

Description:
Cross-domain event and notification schemas for Admin ingress and Discovery. Extends
Event.event_types enum beyond mentee/mentor activity. Blocks F-AA01, F-DA01, F-CA05, F-CA06.

Goals:
- Review event_types — add ingress, subscription, invite, notification, GDPR values.
- ExternalEvent dictionary (append-only): source stripe|cognito, external id, payload hash, normalized body ref.
- Notification dictionary: scope all|customer|mentor|profile, target ids, dismiss state, link metadata.
- Card polymorphic schema (configurator-only, non-persisted) for Discovery UI card types; omit coordinator MVP.
- Profile / Customer provisioned → active lifecycle support.
- Test data: ExternalEvent + Event chains; Notification fixtures for invite and past_due.

Depends on: F-D-E0 (customer journey E0 drops).
Blocks: F-AA01, F-AA02, F-DA01, F-CA05, F-CA06, F-CA09.
Context: mentorhub#36 F-W13, mentorhub#38 F-W14; Workshops/discovery_journey_issues.md
```

---

## Issue text — API planning pass (`F-DA-L001`)

```text
Title: F-DA-L001: Discovery API — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_api

Description:
First planning pass for Discovery API work. Read Workshops/discovery_journey_issues.md and create
appropriately scoped task files under tasks/.

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo.
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
(default landing, universal nav Home → Discovery).

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-US09 (spa_utils).
Blocks: F-DS01 and later F-DS* feature issues.
```

---

## Issue text — Discovery API (`F-DA01`)

```text
Title: F-DA01: Discovery list API — Profiles, Customers, Notifications

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_discovery_api

Description:
Discovery bounded domain API per F-W14. Returns polymorphic card data: Profiles, Customers,
Notifications ordered by recent activity. Discovery owns dismiss mutation on Notifications.

Goals:
- List endpoints with F-UA12 outbound RBAC filters (own profile, customer_id scope, admin sees all).
- Notification dismiss PATCH; write by producer domains only.
- Filter/order in API layer; pagination strategy per F-W14 (profiles paginated, notifications/customers always returned for MVP).

Depends on: F-D29; F-UA12; F-US09.
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
Default post-login landing per F-W14 and F-US09 (Home → Discovery). Polymorphic cards link to
Customer, Mentor, Mentee, Admin SPAs via cross-repo linking. Omit coordinator card type (F-W09).

Goals:
- CardGrid dashboard: Notifications, Customers, Profiles per F-DA01.
- Single-result forward to target SPA without showing intermediate card when appropriate.
- Notification dismiss UX; create-notification remains on producer SPAs (Admin, Customer, Mentor).

Depends on: F-DA01; F-US09; F-W18.
Context: mentorhub#38 F-W14; Workshops/discovery_journey_issues.md
```
