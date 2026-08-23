# L027 – Cross-repo workflow index for SPA base-path ISSUEs

Status: Shipped
Type: Feature
Depends On: L022.welcome_nginx_journey_proxy
Description: Confirm paste-ready `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md` files exist for every journey SPA, and record the serial workflow: welcome nginx can land first; same-origin navigation is blocked until those repos ship Vue `base` + nginx prefix.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./tasks/_ORCHESTRATE.md (this repo must **not** edit sibling SPA repos)
- ./tasks/SHIPPED.S47.runtime_idp_login_workflow_index.md (index pattern)
- ./tasks/SHIPPED.L022.welcome_nginx_journey_proxy.md
- ./tasks/ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_customer_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_admin_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_mentor_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_mentee_spa.vue_base_and_nginx_prefix.md
- mentorhub_cloudformation/ARCHITECTURE.md
- F-US09 (spa_utils cross-repo links) — out of scope to implement; path-based same origin is the prerequisite

## Goals

- Do **not** implement Vue or SPA nginx in this repo.
- Verify each ISSUE file is paste-ready for that SPA’s `_PLANNING.md` (prefix, `createWebHistory`, nginx `try_files`, `/api` under the prefix, dual use of direct host port).
- This index file is the single place in **mentorhub** that lists the follow-on order
  (pattern: `SHIPPED.S47.runtime_idp_login_workflow_index.md`).

## Serial workflow

| Step | Repo | Task / artifact | What changes |
| --- | --- | --- | --- |
| 1 | **mentorhub** | `SHIPPED.L022` | Welcome nginx `location /{journey}/` → `{journey}_spa:80`; variable `proxy_pass`; **no** prefix strip; **no** welcome `/api/` |
| 2a | **mentorhub_discovery_spa** | `ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md` | Vue `base` + nginx `/discovery/`; `/discovery/api/` → `discovery_api` |
| 2b | **mentorhub_customer_spa** | `ISSUE.mentorhub_customer_spa.vue_base_and_nginx_prefix.md` | Vue `base` + nginx `/customer/`; `/customer/api/` → `customer_api` |
| 2c | **mentorhub_admin_spa** | `ISSUE.mentorhub_admin_spa.vue_base_and_nginx_prefix.md` | Vue `base` + nginx `/admin/`; `/admin/api/` → `admin_api` |
| 2d | **mentorhub_mentor_spa** | `ISSUE.mentorhub_mentor_spa.vue_base_and_nginx_prefix.md` | Vue `base` + nginx `/mentor/`; `/mentor/api/` → `mentor_api` |
| 2e | **mentorhub_mentee_spa** | `ISSUE.mentorhub_mentee_spa.vue_base_and_nginx_prefix.md` | Vue `base` + nginx `/mentee/`; `/mentee/api/` → `mentee_api` |
| 3 | **mentorhub** | Manual (Mike) | After SPA images publish: `http://<host>:8080/discovery/` loads Discovery (same-origin JWT); repeat for other journeys |

Welcome prefix → compose upstream (L022; must match `DeveloperEdition/nginx.conf`):

| Prefix | Compose service | Direct host port |
| --- | --- | --- |
| `/discovery/` | `discovery_spa` | **8398** |
| `/customer/` | `customer_spa` | **8388** |
| `/admin/` | `admin_spa` | **8390** |
| `/mentor/` | `mentor_spa` | **8392** |
| `/mentee/` | `mentee_spa` | **8394** |

- If an ISSUE file is missing or the prefix table is wrong, fix the ISSUE file in this task (do not silently add welcome `rewrite` hacks).

## Testing Expectations

- Five ISSUE files exist under `tasks/` and name the correct compose service + prefix.
- This file’s table matches L022 location paths.
- No code changes outside `tasks/` unless an ISSUE file needs a correction (ISSUE files only).

## Outputs

- This file (`tasks/RUNNING.L027.issue_spa_base_path.md`) — workflow index; rename to `SHIPPED.*` when step 3 manual passes.
- `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md` — only if a correction is required.

## Execution Notes

**Verified (2026-08-22):** All five `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md`
files exist. Prefixes match L022 welcome `location` paths and `DeveloperEdition/nginx.conf`
(no prefix strip; no welcome-level `/api/`). Each ISSUE includes Vite `base`, Vue
`createWebHistory`, nginx `try_files` under the prefix, `/{journey}/api/` proxy, direct
host port for Cypress/debug, `_PLANNING.md` planning prompt, and `IDP_LOGIN_URI` on
`:8080/login.html`.

**ISSUE corrections:** Added explicit `welcome :8080/{journey}/*` → `{journey}_spa:80`
local-twin lines to customer, admin, mentor, and mentee ISSUE summaries (discovery already
had one). Prefix tables were already correct; no welcome `rewrite` guidance added.

**Blockers:** Same-origin navigation via `:8080/{journey}/` remains broken until each SPA
repo ships its ISSUE (step 2). Until then, L022 proxy may return SPA nginx **404** — that is
expected and acceptable per L022; welcome **404** is not.

**Next:** Paste each ISSUE into the matching SPA repo’s `_PLANNING.md` workflow; after images
publish, run step 3 manual on `http://<host>:8080/discovery/`.
