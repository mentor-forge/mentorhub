# L011 – Bootstrap mentorhub_admin_spa from mentorhub_customer_spa

Status: Pending
Type: Feature
Depends On: none
Description: F-W18 — Copy `mentorhub_customer_spa` into the empty `mentorhub_admin_spa` repo, E0-strip legacy CRUD pages/nav/Cypress, bump `spa_utils` to **0.5.x**, keep `initAuth` + `AdminPage` as the starting shell, and rename to `admin-spa` (port **8390**).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Copy sources table, F-W18)
- ./Workshops/customer_journey_issues.md (E0 cleanup patterns — F-CS02)
- ./Specifications/architecture.yaml (admin_spa port 8390)
- ../mentorhub_customer_spa/ (copy source)
- ../mentorhub_admin_spa/ (empty repo — LICENSE + README only today)
- ../mentorhub_mentee_spa/package.json (reference for spa_utils **0.5.x** adoption)

## Goals

- Copy the full customer SPA project tree from `../mentorhub_customer_spa/` into `../mentorhub_admin_spa/` (exclude `.git`).
- **E0 strip legacy template CRUD:**
  - Remove pages, routes, nav entries, and API client modules for Cards, Dashboards, Subscriptions, Events, Journeys, Ratings, Notes, and other customer-domain CRUD not needed for Admin MVP.
  - Remove Cypress E2E specs and support files for stripped pages.
  - Simplify `App.vue` navigation to a minimal auth shell (logout + placeholder home).
- **Keep as starting point:**
  - Cognito/IdP redirect guards and `initAuth` / `bootstrapAuthFromUrl` wiring from customer source.
  - `AdminPage.vue` route (spa_utils `AdminPage` component) — admin-only entry for future F-AS## work.
- **Bump spa_utils:** `@mentor-forge/mentorhub_spa_utils` from **0.2.2** → **0.5.x** (match mentee SPA baseline; resolve breaking import/API changes per spa_standards.md).
- **Rename to admin-spa:**
  - Container/nginx and compose-facing port **8390** (SPA maps host 8390 → container 80).
  - GHCR image: `ghcr.io/mentor-forge/mentorhub_admin_spa:latest`.
  - `package.json` / CI / Docker scripts: `mentorhub_admin_spa`, `API_PORT` **8389** (admin API).
  - Default authenticated route: `/admin` (or equivalent AdminPage path).
- Initial commit in `mentorhub_admin_spa`; push to `mentor-forge/mentorhub_admin_spa`.
- Do **not** build Products/Config/notification-create UI (F-AS## scope).

## Testing Expectations

- In `../mentorhub_admin_spa/`: `npm run lint` and `npm run test:unit` pass.
- `npm run build` succeeds with spa_utils **0.5.x**.
- Grep stripped page filenames — removed from `src/pages/` and `src/router/index.ts`.
- Router still enforces auth guard; unauthenticated users redirect to IdP login URI pattern.
- No references to `mentorhub_customer_spa`, port **8388**, or removed CRUD routes in active source.

## Outputs

- `../mentorhub_admin_spa/` — full bootstrapped SPA repo, including but not limited to:
  - `package.json`, `package-lock.json`
  - `src/main.ts`, `src/App.vue`, `src/router/index.ts`, `src/pages/AdminPage.vue`
  - `src/composables/useAuth.ts`, `src/api/client.ts`
  - `Dockerfile`, `nginx.conf`, `.github/workflows/`
  - `README.md`
  - Removed: `cypress/` (and cypress npm scripts if no specs remain)

## Execution Notes
