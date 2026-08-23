Please create @_PLANNING.MD tasks to implement this issue. Only create tasks, do not edit any files outside of the @tasks folder.

**GitHub**: https://github.com/mentor-forge/mentorhub_mentee_spa/issues/28

# F-ES09: Vue base + SPA nginx prefix `/mentee/` (Mentee SPA)

**Unblocked:** mentorhub welcome nginx (L022) already forwards the **full URI**
`http://<host>:8080/mentee/` to this container with `X-Forwarded-Prefix: /mentee`.
This issue is what remains so same-origin JWT `localStorage` works when opening
Mentee via `:8080/mentee/`.

## Summary

Mount Mentee SPA at **`/mentee/`**. Welcome/ALB forward the **full URI**. Today
this repo assumes the app is at **`/`**:

- `vite.config.ts` has no `base`; `injectRuntimeConfig` loads `/runtime-config.js`
- `src/router/index.ts` uses `createWebHistory()` (home `/` → `/journey`)
- `nginx.conf.template` has `location /`, `location /api/`, and
  `location = /runtime-config.js`
- Cypress visits `/`, `/journey`, `/resources`, `/paths` against `baseUrl`
  `http://localhost:8394`

SPA nginx already proxies `/api/` to `mentee_api` (`API_HOST` / `API_PORT`, **8393**).
Local twin: welcome `:8080/mentee/*` → `mentee_spa:80`. Direct port **8394** stays
published.

## Goals

- Vite `base: '/mentee/'`. Router: `createWebHistory(import.meta.env.BASE_URL)`.
  Keep route paths (`/journey`, `/resources`, `/paths`); they become
  `/mentee/journey` automatically. Do **not** duplicate the prefix in route
  `path` strings.
- `nginx.conf.template`:
  - `location /mentee/api/` → `http://${API_HOST}:${API_PORT}/api/` (port **8393**).
  - `location /mentee/` maps the prefix onto the dist root (Vite `base` changes
    asset URLs, not the output folder). Internal rewrite is OK.
  - Keep `location /api/` for **direct-port** debugging.
  - Prefixed `runtime-config.js` (and keep `/runtime-config.js` for direct port).
  - Optional: `location = /` redirect to `/mentee/` so `http://<host>:8394/` still works.
- Vite HTML inject must load runtime-config under the prefix (or
  `import.meta.env.BASE_URL`).
- Vite `server.proxy` should also proxy `/mentee/api` to `localhost:8393` for
  `npm run dev` under the base.
- Cypress `baseUrl` stays `http://localhost:8394`; visits become `/mentee/`,
  `/mentee/journey`, `/mentee/resources`, `/mentee/paths`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; CloudFormation ALB; F-US09 implementation.

## Acceptance

- `http://<host>:8080/mentee/` serves this SPA (not welcome `index.html`).
- `http://<host>:8394/mentee/` works for single-SPA Cypress.
- API calls from the prefixed origin hit `mentee_api` via SPA nginx.
- `npm run lint`, `npm run test`, Cypress e2e pass.
