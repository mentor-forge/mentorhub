# L026 – Document shared-origin welcome vs direct-port debugging

Status: Shipped
Type: Feature
Depends On: L025.welcome_portal_applications
Description: Document Developer Edition’s two entry modes: **one origin on :8080** for auth/`localStorage`, and **direct service ports** for OpenAPI, Cypress, and mocks — and that this nginx is not a substitute for the AWS ALB.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/standards/sre_standards.md (IDP_LOGIN_URI / nginx SPA proxy today)
- ./DeveloperEdition/standards/spa_standards.md
- ./Research/local_dev_mocks.md
- mentorhub_cloudformation/ARCHITECTURE.md (ALB `/{journey}/*` — local twin is welcome nginx, not CloudFormation)
- ./tasks/PENDING.L022.welcome_nginx_journey_proxy.md
- ./tasks/PENDING.L023.login_shared_origin_return_to.md
- ./tasks/PENDING.L024.stage0_launch_compose.md
- ./tasks/ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md

## Goals

- **`README.md` Quick Start:**
  - Front door: `http://localhost:8080` (portal), login `http://localhost:8080/login.html`, default app `http://localhost:8080/discovery/`.
  - Port note includes **8081 (Stage0 Launch)**, **9229**, **1025/8025**, **12111**, plus 8080 / 27017 / 8383–8398.
  - One sentence: journey SPAs behind `/discovery/` `/customer/` `/admin/` `/mentor/` `/mentee/` share origin and JWT `localStorage`; direct ports remain for debugging.
- **`CONTRIBUTING.md`:**
  - `HOST_NAME` / `IDP_LOGIN_URI` still `http://<HOST_NAME>:8080/login.html`.
  - After login, prefer portal Applications links (shared origin), not bookmarks to `:8398`.
  - `MENTORHUB_PATH` / Stage0: `mh up stage0` (or profile `all`); Launch UI on **8081**; `DELETE_ENABLED=True` optional; launchpad is the **parent** of the umbrella (`/Launchpad`).
  - Direct-port Cypress and `/docs/` explorers are supported on purpose.
- **`DeveloperEdition/standards/sre_standards.md`:**
  - Developer Edition welcome nginx is the **local path router** matching cloud ALB **intent**; CloudFormation still deploys the real ALB (out of scope here).
  - Do not route Admin Stripe/Cognito webhooks through :8080 (F-AA01).
  - Note that full same-origin navigation requires journey SPA Vue `base` + nginx prefix (ISSUE artifacts in `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md`).
- **`Research/local_dev_mocks.md`:** one line that mock **UIs** are linked from the portal on their own ports, not under `/{journey}/`.
- Do **not** edit CloudFormation templates.

## Testing Expectations

- README mentions `:8080/discovery/` and still lists direct API/SPA ports.
- CONTRIBUTING does not tell developers to open Discovery on **8398** as the primary app URL.
- Markdown lint on touched files if tooling is available.

## Outputs

- `README.md`
- `CONTRIBUTING.md`
- `DeveloperEdition/standards/sre_standards.md`
- `Research/local_dev_mocks.md` — portal vs mock-port note only if missing after L020/L021.

## Execution Notes

### Plan

1. **README Quick Start** — Replace single “visit :8080” line with portal/login/default-app URLs; expand port NOTE to include 8081, mocks, and 8383–8398 with Discovery examples; add shared-origin sentence; remove “default landing Discovery SPA (8398)”.
2. **CONTRIBUTING** — Add “Developer Edition — portal vs direct ports” (prefer Applications on :8080; Cypress/docs on direct ports); add Stage0 Launch subsection (`MENTORHUB_PATH`, `LAUNCHPAD_HOST`, `/Launchpad`, `mh up stage0`/`all`, 8081, `DELETE_ENABLED`); leave existing `HOST_NAME` / `IDP_LOGIN_URI` block unchanged.
3. **sre_standards.md** — Under Production alignment, add “Developer Edition welcome nginx” subsection: local ALB-intent path router, CloudFormation ALB out of scope, F-AA01 webhook exclusion, ISSUE SPA base/prefix dependency.
4. **local_dev_mocks.md** — One line after Related: mock UIs on portal Tools at direct ports, not under `/{journey}/`.

### Implementation

| File | Change |
|------|--------|
| `README.md` | Quick Start: portal `:8080`, login `:8080/login.html`, default app `:8080/discovery/`; port NOTE lists 8080, 8081, 27017, 8383–8398 (8397/8398 called out), 9229, 1025/8025, 12111; shared-origin + direct-port debugging sentence |
| `CONTRIBUTING.md` | New § before Development Standards: portal vs direct ports + Stage0 Launch (`MENTORHUB_PATH`, `/Launchpad`, `mh up stage0`/`all`, 8081, optional `DELETE_ENABLED=True`) |
| `DeveloperEdition/standards/sre_standards.md` | New § “Developer Edition welcome nginx (local path router)” under Production alignment |
| `Research/local_dev_mocks.md` | Portal Tools mock-UI port note (was missing after L020/L021) |

No CloudFormation edits.

### Testing

| Check | Result |
|-------|--------|
| README mentions `:8080/discovery/` | PASS |
| README lists direct API/SPA ports (8383–8398, 8397, 8398) | PASS |
| CONTRIBUTING does not recommend `:8398` as primary Discovery URL | PASS — explicitly warns against bookmarking `:8398` |
| `npx markdownlint-cli2` on touched files | Ran — 271 pre-existing MD013/MD012 issues across files; no new structural errors from L026 edits (same pattern as L021/S43) |

### Blockers

None. Full same-origin in-app navigation under `/{journey}/` remains blocked until ISSUE SPA Vue `base` + nginx prefix tasks ship (documented, not in L026 scope).