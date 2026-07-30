# Admin Journey Issues

Sources:

- [F-W13: Design Admin Domain](https://github.com/mentor-forge/mentorhub/issues/36)
- `Workshops/customer_journey_issues_adjustments.md`
- `Workshops/customer_journey_issues.md` (Customer journey — consumes Admin ingress events)
- [F-UA08 Config constants](https://github.com/mentor-forge/mentorhub_api_utils/issues/17), [F-UA12 RBAC pattern](https://github.com/mentor-forge/mentorhub_api_utils/issues/25)
- `tasks/_PLANNING.md` (task file layout for each repo)

**Actor:** Platform operators and ingress automation (Stripe, Cognito, future external systems).

**How to use:** Paste-ready **Issue text** per target repository. Give an issue to a planning agent **in that repo only** — each issue ends with instructions to create `tasks/` files via `_PLANNING.md`.

**Scope:** Admin owns **ingress** — verify external webhooks, normalize payloads, provision minimal identities (Profile, Customer/Organization), record immutable ExternalEvent/Event documents. Admin does **not** execute domain business workflows beyond identity provisioning.

**Ingress pattern:**

```text
External system → Admin ingress (verify, provision, record ExternalEvent/Event)
                       ↓
              Domain API consumer (Customer, Discovery, …)
```

**Related journeys:** [discovery_journey_issues.md](./discovery_journey_issues.md), [customer_journey_issues.md](./customer_journey_issues.md).

---

## Naming (CONTRIBUTING.md)

| Prefix | Meaning | Repo |
| --- | --- | --- |
| `F-AA##` | **A**dmin **A**pi | `mentorhub_admin_api` |
| `F-AS##` | **A**dmin **S**pa | `mentorhub_admin_spa` |
| `F-W##` | **W**elcome / platform bootstrap | `mentorhub` |

Cross-domain data schemas (ExternalEvent, shared event types): **F-D29** in `mentorhub_mongodb_api` — see [discovery_journey_issues.md](./discovery_journey_issues.md).

---

## Suggested implementation order

1. **F-W18** — Bootstrap Admin (+ Discovery) repos in Developer Edition.
2. **F-D29** — Event/ExternalEvent schemas (mongodb_api; blocks ingress).
3. **F-AA-L001** / **F-AS-L001** — planning passes.
4. **F-AA01** — Stripe + Cognito ingress.
5. **F-AA02** — Immutable event recording utilities.
6. Admin SPA features (Products, Config, admin-scoped notification create) — file as F-AS## when ready.

---

## Issue text — Welcome / platform (`F-W18`)

```text
Title: F-W18: Bootstrap Admin + Discovery repos in Developer Edition

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub

Description:
Wire new Admin and Discovery bounded domains into Developer Edition after F-W13/F-W14 design.
Create repos from stage0 or mentee template as decided in F-W13 (#36).

Goals:
- docker-compose services for admin_api, admin_spa, discovery_api, discovery_spa.
- Welcome portal + login.html links; default post-login → Discovery SPA.
- API gateway / port map documented for F-US09 cross-repo linking.

Depends on: mentorhub#36 F-W13, mentorhub#38 F-W14.
Blocks: F-AA01, F-DS01, F-DA01 local integration.

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

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo.
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

Depends on: _PLANNING.md / _ORCHESTRATE.md present in repo.
Prerequisites: F-US09 (spa_utils).
Blocks: F-AS01 and later F-AS* feature issues.
```

---

## Issue text — Admin API (`F-AA01`)

```text
Title: F-AA01: Ingress — Stripe + Cognito webhooks and identity provisioning

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_api

Description:
MVP ingress layer per F-W13. Verify webhook signatures, normalize payloads, provision minimal
Customer (Organization) + Profile on Cognito Post Confirmation, append ExternalEvent/Event.
No business workflow execution beyond identity provisioning.

Goals:
- POST ingress routes for Stripe and Cognito (Post Confirmation).
- Signature verification (STRIPE_WEBHOOK_VERIFY in prod; false in local dev).
- Provision Profile + Customer (Organization) in provisioned state; record immutable events.
- Dev parity endpoints for F-W10 login.html register/join flows.

Depends on: F-D29; F-W18; F-UA08; F-S01 (prod Cognito wiring).
Blocks: F-CA05, F-CA06, F-CA09 event consumers (customer_api).
Context: mentorhub#36 F-W13; Workshops/admin_journey_issues.md
```

---

## Issue text — Admin API (`F-AA02`)

```text
Title: F-AA02: Ingress — immutable event recording utilities

Create @_PLANNING.md tasks to implement this issue. Only create tsaks, do not execute tasks, do not edit any files outside of the @tasks folder.

Repository: mentor-forge/mentorhub_admin_api

Description:
Shared ingress service layer for ExternalEvent + Event writes. No domain-specific business logic.

Depends on: F-D29; F-AA01.
Context: F-W13; Workshops/admin_journey_issues.md
```
