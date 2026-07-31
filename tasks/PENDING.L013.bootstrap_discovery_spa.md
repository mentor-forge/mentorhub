# L013 – Bootstrap mentorhub_discovery_spa from mentorhub_mentee_spa

Status: Pending
Type: Feature
Depends On: none
Description: F-W18 — Copy `mentorhub_mentee_spa` into the empty `mentorhub_discovery_spa` repo, strip mentee domain pages/nav, keep minimal auth shell with spa_utils **0.5.5**, and rename to `discovery-spa` (port **8398**).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Copy sources table, F-W18)
- ./Workshops/discovery_journey_issues.md (F-DS01 CardGrid-ready shell)
- ./Specifications/architecture.yaml (discovery_spa port 8398)
- ../mentorhub_mentee_spa/ (copy source — spa_utils **0.5.5**)
- ../mentorhub_discovery_spa/ (empty repo — LICENSE + README only today)

## Goals

- Copy the full mentee SPA project tree from `../mentorhub_mentee_spa/` into `../mentorhub_discovery_spa/` (exclude `.git`; exclude mentee `tasks/` shipped history unless needed for `_PLANNING` seed in L014).
- **Strip mentee domain UI:**
  - Remove pages, routes, nav, components, and API modules for Journey, Path, Resource, Aggregation, Note, Rating, and mentee-specific workflows.
  - Remove mentee Cypress/Vitest specs for stripped domains.
- **Keep minimal auth shell:**
  - `initAuth`, router guards, `useAuth`, API client 401 → IdP redirect (spa_utils **0.5.5** patterns).
  - Placeholder home route (`/` or `/discovery`) ready for F-DS01 CardGrid — simple “Discovery landing (stub)” view, not mentee journey UI.
  - Retain CardGrid/MhCard import patterns from mentee list pages where useful as F-DS01 scaffolding (optional thin placeholder).
- **Rename to discovery-spa:**
  - Container/nginx host port **8398** (maps to container 80).
  - GHCR image: `ghcr.io/mentor-forge/mentorhub_discovery_spa:latest`.
  - `API_PORT` **8397** (discovery API); package name `mentorhub_discovery_spa`.
  - Pipfile/npm scripts and README local URLs updated.
- Pin `@mentor-forge/mentorhub_spa_utils` at **0.5.5** (or current mentee baseline if newer patch).
- Initial commit in `mentorhub_discovery_spa`; push to `mentor-forge/mentorhub_discovery_spa`.
- Do **not** implement F-DS01 polymorphic CardGrid or F-US09 universal nav.

## Testing Expectations

- In `../mentorhub_discovery_spa/`: `npm run lint` and `npm run test:unit` pass.
- `npm run build` succeeds.
- Router enforces auth; stripped mentee routes/pages absent from bundle.
- Grep — no `mentorhub_mentee_spa`, port **8394**, or mentee journey/path/resource page names in active source.
- Default authenticated landing is discovery stub, not mentee home.

## Outputs

- `../mentorhub_discovery_spa/` — full bootstrapped SPA repo, including but not limited to:
  - `package.json`, `package-lock.json`
  - `src/main.ts`, `src/App.vue`, `src/router/index.ts`
  - `src/pages/` (minimal stub home only)
  - `src/composables/useAuth.ts`, `src/api/client.ts`
  - `Dockerfile`, `nginx.conf`, `.github/workflows/`
  - `README.md`

## Execution Notes
