Please create @_PLANNING.MD tasks to implement this issue. Only create tasks, do not edit any files outside of the @tasks folder.

**GitHub**: https://github.com/mentor-forge/mentorhub_discovery_spa/issues/5

# F-DS02: Vue base + SPA nginx prefix `/discovery/` (Discovery SPA)

**Unblocked:** mentorhub welcome nginx (L022) already forwards the **full URI**
`http://<host>:8080/discovery/` to this container with `X-Forwarded-Prefix: /discovery`.
This issue is what remains so same-origin JWT `localStorage` works as the default
post-login landing.

## Summary

Mount Discovery SPA at **`/discovery/`** so Developer Edition welcome (and cloud ALB)
can serve it on a **shared hostname**. Today this repo assumes the app is at **`/`**:

- `vite.config.ts` has no `base`; `injectRuntimeConfig` loads `/runtime-config.js`
- `src/router/index.ts` uses `createWebHistory()` with routes `/` → `/discovery`
- `nginx.conf.template` has `location /` + `location /api/` only
- Cypress `baseUrl` is `http://localhost:8398` and visits `/discovery`

Welcome **must not** strip the prefix; this repo must honor it. Local twin:
`:8080/discovery/*` → `discovery_spa:80`. Direct port **8398** stays published.

Do **not** turn Discovery into a reverse proxy or micro-frontend shell (F-DS01 is
the product landing page, not the edge router).

## Goals

- Vite `base: '/discovery/'`. Router: `createWebHistory(import.meta.env.BASE_URL)`.
- **Avoid `/discovery/discovery`:** with that base, the home route must be `/`
  (today `/` redirects to `/discovery`). Serve `DiscoveryHomePage` at `/`.
- `nginx.conf.template`:
  - `location /discovery/api/` → `http://${API_HOST}:${API_PORT}/api/` (API **8397**).
  - `location /discovery/` maps the prefix onto the dist root (Vite `base` changes
    asset URLs, not the output folder). Internal rewrite is OK; welcome already
    forwarded the full URI.
  - Keep `location /api/` for **direct-port** debugging.
  - `location = /` redirect to `/discovery/` so `http://<host>:8398/` still works.
  - Prefixed `runtime-config.js` (and keep `/runtime-config.js` for direct port).
- Vite HTML inject and any hardcoded `/runtime-config.js` must use the prefix
  (or `import.meta.env.BASE_URL`).
- Vite `server.proxy` should also proxy `/discovery/api` to `localhost:8397` for
  `npm run dev` under the base.
- Cypress visits become `/discovery/` (home), not `/discovery` as a second path
  segment. `baseUrl` stays `http://localhost:8398`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.
- Do not maintain a second root-only build.

## Out of scope

- Welcome `nginx.conf` / CloudFormation ALB.
- F-US09 CrossRepoLink in spa_utils.
- F-W10 login.html tabs.
- F-DS01 landing-page product work.

## Acceptance

- `http://<host>:8080/discovery/` serves this SPA (not welcome `index.html`).
- `http://<host>:8398/discovery/` works for single-SPA Cypress.
- In-app routes are `/discovery/...`, not `/discovery/discovery/...`.
- API calls from the prefixed origin hit `discovery_api` via SPA nginx.
- `npm run lint`, `npm run test`, Cypress e2e pass.
