# L026 – Document shared-origin welcome vs direct-port debugging

Status: Pending
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
