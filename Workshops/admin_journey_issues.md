# Admin Journey Issues

Sources:

- [F-W13: Design Admin Domain](https://github.com/mentor-forge/mentorhub/issues/36) — architectural decisions below
- `Workshops/customer_journey_issues_adjustments.md`
- `Workshops/customer_journey_issues.md` (Customer journey — consumes Admin ingress events)
- [F-W18: Bootstrap Admin + Discovery repos](https://github.com/mentor-forge/mentorhub/issues/52)
- [F-UA08 Config constants](https://github.com/mentor-forge/mentorhub_api_utils/issues/17), [F-UA12 RBAC pattern](https://github.com/mentor-forge/mentorhub_api_utils/issues/25)
- `DeveloperEdition/standards/api_standards.md`, `spa_standards.md` (copy sources — current CodeArtifact, JWT, CI patterns)
- `tasks/_PLANNING.md` (task file layout for each repo)

**Actor:** Platform operators and ingress automation (Stripe, Cognito, future external systems).

**How to use:** Paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md`.

**Related journeys:** [discovery_journey_issues.md](./discovery_journey_issues.md), [customer_journey_issues.md](./customer_journey_issues.md).

---

## Locked decisions (Admin domain — F-W13)

**Ingress is infrastructure, not business logic.** External systems (Stripe, Cognito, etc.) call **Admin API ingress** endpoints. Admin verifies signatures, validates and normalizes payloads, provisions minimal identities, and records immutable events. Admin does **not** interpret business meaning, run domain workflows, or populate domain-specific fields beyond provisioning.

**MVP ingress privileges (only exception to “no business logic”):**

- Create/provision identity aggregate roots: **Profile**, **Customer (Organization)**, and related roots as needed.
- Minimal fields + generated `_id`s; documents begin in **`provisioned`** status.
- Owning domains (Customer API, etc.) **enrich** provisioned documents later.

**Profile is canonical.** The previous Identity/Profile split is eliminated — one Profile per person.

**Organization onboarding.** Organizations are provisioned during customer onboarding (Cognito Post Confirmation → ingress). Additional members are **invited** by the organization; they do not self-register via public sign-up.

**MongoDB as initial event bus (MVP).** Append-only collections — **ExternalEvent**, **Event**, **Notification** — provide async cross-domain communication until EventBridge/SQS. Consumers (Customer API, Discovery API) must not depend on MongoDB-specific polling details that block a future bus swap.

**Event-driven architecture is the direction; sync ingress + document writes are sufficient for MVP.**

**Ingress pattern:**

```text
External system → Admin ingress (verify, normalize, provision, record ExternalEvent/Event)
                       ↓
              Domain API consumer (Customer, Discovery, …)
                       ↓
              Optional: write Notification for Discovery
```

---

## Repo bootstrap decision (locked — answers F-W13 open question)

F-W13 asked whether to **copy an existing journey service** or use **Stage0 Launch templates**.

**Decision: copy + refactor from live journey repos** — do **not** use Stage0 Launch until templates are updated to match current CodeArtifact, api-utils **0.5.x**, spa_utils **0.5.x**, JWT claims, and `tasks/_PLANNING.md` patterns (see follow-on **template refresh** note below).

| Option | Verdict | Why |
| --- | --- | --- |
| **Copy + refactor** (sibling journey repo) | **Use** | Inherits working CodeArtifact Pipfile/npm, CI, Docker, `mh` scripts, IdP auth, and task automation — subtract wrong domain, rename, register in compose |
| **Stage0 Launch** (`make stage0-launch-ui`) | **Defer** | Templates lag live repos (e.g. customer_api still on api-utils **0.2.1** with local services; Stage0 would replay platform plumbing ×4 repos) |
| Blind copy **one** repo for all four | **Do not** | Each target needs a different source (see table below) |

**Why not “copy customer for everything”?** Customer API is on **api-utils 0.2.1** with duplicated `src/services/*`; mentee/mentor are on **0.5.x** with harvested `api_utils.services`. Admin ingress should start from the **current** API shell, not the oldest.

### Copy sources (locked)

| New repo | Copy from | Strip / refactor (F-W18 scope) | Keep |
| --- | --- | --- | --- |
| `mentorhub_admin_api` | **`mentorhub_mentee_api`** | Remove journey, path, resource, aggregation, note routes + tests; remove domain OpenAPI sections | `server.py` shell, config/metrics/explorer, api-utils **0.5.x**, test harness, CI/Docker |
| `mentorhub_admin_spa` | **`mentorhub_customer_spa`** | E0-style: remove Card/Dashboard/Subscription/… pages, nav, Cypress; bump **spa_utils** to **0.5.x** (customer is on 0.2.2) | `initAuth`, router guards, **AdminPage.vue** starting point |
| `mentorhub_discovery_api` | **`mentorhub_customer_api`** | Remove card, dashboard, subscription, journey, rating, note routes; **upgrade api-utils 0.2→0.5** and migrate local services toward `api_utils.services` (coordinate F-UA08) | customer + profile routes as F-DA01 starting point |
| `mentorhub_discovery_spa` | **`mentorhub_mentee_spa`** | Remove mentee domain pages/nav; minimal auth shell | spa_utils **0.5.5**, CardGrid-ready patterns for F-DS01 |

**Copy mechanics (F-W18):** duplicate repo on GitHub (empty repo + push filtered copy, or org template — **not** Stage0 Launch UI). Rename package names, ports, GHCR image paths, compose service keys, and `README` titles. Preserve git history optional; clean single commit acceptable.

**After copy:** confirm each repo has `tasks/_PLANNING.md` and `tasks/_ORCHESTRATE.md` (copy from `mentorhub_customer_*` **F-CA-L001** / **F-CS-L001** shipped tasks if missing). Feature ingress/list work stays in **F-AA01**, **F-DA01**, etc.

**Follow-on (not blocking F-W18):** refresh Stage0 Launch templates from mentee/customer baseline so future domains can Launch again — file under cloudformation/SRE when convenient.

**F-W18** owns **copy, strip, rename, register in Developer Edition** — not F-W13, not F-AA-L001. Planning passes assume repos exist on GitHub and locally.

---

## Naming (CONTRIBUTING.md)

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-AA##` | **A**dmin **A**pi | `mentorhub_admin_api` |
| `F-AS##` | **A**dmin **S**pa | `mentorhub_admin_spa` |
| `F-W##` | **W**elcome / platform bootstrap | `mentorhub` |

Cross-domain data schemas (ExternalEvent, shared event types): **F-D29** in `mentorhub_mongodb_api` — see [discovery_journey_issues.md](./discovery_journey_issues.md).

---

## Experience map

| # | Experience | Intent | Suggested IDs |
| --- | --- | --- | --- |
| **A0** | **Bootstrap repos + Developer Edition** | Copy four repos from siblings; strip, rename, compose, welcome portal | **F-W18** |
| A1 | Ingress — Stripe + Cognito | Webhooks, identity provisioning, ExternalEvent | F-AA01 |
| A2 | Ingress — event recording | Shared ExternalEvent/Event write layer | F-AA02 |
| A3 | Planning + Admin SPA features | `_PLANNING.md` tasks; Products, Config, notifications | F-AA-L001, F-AS-L001, F-AS## |

---

## Suggested implementation order

1. **F-W18** — Copy, strip, rename four repos + Developer Edition wiring (see copy sources table).
2. **F-D29** — Event/ExternalEvent/Notification schemas (mongodb_api; blocks ingress).
3. **F-UA08** — Config constants (api_utils; all new APIs).
4. **F-AA-L001** / **F-AS-L001** — planning passes (in repos created by F-W18).
5. **F-AA02** then **F-AA01** — event recording utilities before full ingress (or parallel if AA02 is thin).
6. **F-AA01** — Stripe + Cognito ingress (depends on F-S01 for prod Cognito).
7. Admin SPA (**F-AS01**+): Products catalog UI, Config page, admin notification create.

Discovery repo bootstrap is listed in **F-W18** but Discovery feature issues live in [discovery_journey_issues.md](./discovery_journey_issues.md).

---

## Issue text — Welcome / platform (`F-W18`)

```text
Title: F-W18: Bootstrap Admin + Discovery repos (copy + refactor) and Developer Edition

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub

Description:
Create the four Admin and Discovery bounded-domain repositories by copying live journey
siblings (NOT Stage0 Launch — templates lag current CodeArtifact, api-utils, spa_utils, JWT).
Locked copy sources in Workshops/admin_journey_issues.md "Copy sources (locked)".

Goals — for each new repo (GitHub org mentor-forge, sibling clone under mentorhub parent):
1. mentorhub_admin_api — copy mentorhub_mentee_api; strip journey/path/resource/aggregation/note
   routes, services, tests, OpenAPI; rename ports/images/scripts to admin-api.
2. mentorhub_admin_spa — copy mentorhub_customer_spa; E0 strip legacy CRUD pages/nav/Cypress;
   bump spa_utils to 0.5.x; keep initAuth + AdminPage as starting point; rename to admin-spa.
3. mentorhub_discovery_api — copy mentorhub_customer_api; strip card/dashboard/subscription/
   journey/rating/note; plan api-utils 0.2→0.5 upgrade path; keep customer+profile routes; rename.
4. mentorhub_discovery_spa — copy mentorhub_mentee_spa; strip mentee domain pages; keep auth
   shell + spa_utils 0.5.5; rename to discovery-spa.

Platform wiring (all four):
- Confirm tasks/_PLANNING.md and tasks/_ORCHESTRATE.md (copy from customer_* L001 tasks if needed).
- DeveloperEdition/docker-compose.yaml: services, ports, env (stub until F-AA01 / F-DA01).
- Welcome portal + login.html links; default post-login → Discovery SPA base URL.
- Document port map for F-US09 cross-repo linking.
- Register in mh / workspace docs as applicable.

Out of scope for F-W18: F-AA01 ingress, F-DA01 list API, feature UI (file separately).

Depends on: mentorhub#36 F-W13 (design locked in admin_journey_issues.md).
Blocks: F-AA-L001, F-AS-L001, F-DA-L001, F-DS-L001, F-AA01, F-DA01, F-DS01, F-W10 local ingress URLs.

Context: Workshops/admin_journey_issues.md; Workshops/discovery_journey_issues.md
```

---

## Issue text — API planning pass (`F-AA-L001`)

```text
Title: F-AA-L001: Admin API — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_api

Description:
First planning pass for Admin API work. Read Workshops/admin_journey_issues.md and create
appropriately scoped task files under tasks/.

Architecture: Ingress only for MVP — webhooks, identity provisioning, immutable events.
No domain business logic beyond provisioning.

Depends on: F-W18 (repo exists); _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-UA08 (api_utils).
Blocks: F-AA01 and later F-AA* feature issues.
```

---

## Issue text — SPA planning pass (`F-AS-L001`)

```text
Title: F-AS-L001: Admin SPA — planning pass for journey tasks

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_spa

Description:
First planning pass for Admin SPA work. Read Workshops/admin_journey_issues.md and F-US09
(universal nav — Products, Config, admin-scoped notification create).

Depends on: F-W18 (repo exists); _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-US09 (spa_utils).
Blocks: F-AS01 and later F-AS* feature issues.
```

---

## Issue text — Admin API (`F-AA02`)

```text
Title: F-AA02: Ingress — immutable event recording utilities

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_api

Description:
Shared ingress service layer for ExternalEvent + Event append-only writes. Normalize payload
metadata; no domain-specific business logic. Designed so a future EventBridge/SQS bus can
replace MongoDB writes without changing consumer contracts.

Goals:
- ExternalEvent create (source, external id, payload hash, normalized body reference).
- Event create (event_types from F-D29, context refs).
- Idempotent external id handling where applicable.

Depends on: F-D29; F-W18; F-UA08.
Blocks: F-AA01 (implementation should call this layer).
Context: F-W13; Workshops/admin_journey_issues.md
```

---

## Issue text — Admin API (`F-AA01`)

```text
Title: F-AA01: Ingress — Stripe + Cognito webhooks and identity provisioning

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_api

Description:
MVP ingress layer per F-W13. Verify webhook signatures, normalize payloads, provision minimal
Customer (Organization) + Profile on Cognito Post Confirmation, append ExternalEvent/Event
via F-AA02. No business workflow execution beyond identity provisioning.

Goals:
- POST ingress routes for Stripe and Cognito (Post Confirmation).
- Signature verification (STRIPE_WEBHOOK_VERIFY in prod; false in local dev).
- Provision Profile + Customer (Organization) in provisioned status; record immutable events.
- Dev parity endpoints for F-W10 login.html register/join flows (shared service layer with Customer API enrichment).
- Do not expose Customer-domain enrichment or Stripe Checkout logic here.

Depends on: F-D29; F-W18; F-AA02; F-UA08; F-S01 (prod Cognito wiring).
Blocks: F-CA05, F-CA06, F-CA09 event consumers (customer_api).
Context: mentorhub#36 F-W13; Workshops/admin_journey_issues.md
```

---

## Explicitly out of scope (Admin API MVP)

- Business enrichment of Customer (subscriptions[], billing) — Customer API
- Stripe Checkout / Portal session creation — Customer API
- Cognito AdminCreateUser for member invites — Customer API
- Discovery list/dismiss — Discovery API
- Interpretation of Stripe events beyond normalize + record + trigger provisioning when required

---

## Explicitly out of scope (Admin SPA MVP — file later as F-AS##)

- Platform landing / default post-login home — Discovery SPA
- Customer org commerce UI — Customer SPA
