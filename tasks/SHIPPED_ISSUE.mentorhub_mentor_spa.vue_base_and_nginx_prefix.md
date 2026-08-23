Please create @_PLANNING.MD tasks to implement this issue. Only create tasks, do not edit any files outside of the @tasks folder.

**GitHub**: https://github.com/mentor-forge/mentorhub_mentor_spa/issues/33

# F-RS15: Vue base + SPA nginx prefix `/mentor/` (Mentor SPA)

**Unblocked:** mentorhub welcome nginx (L022) already forwards the **full URI**
`http://<host>:8080/mentor/` to this container with `X-Forwarded-Prefix: /mentor`.
This issue is what remains so same-origin JWT `localStorage` works when opening
Mentor via `:8080/mentor/`.

## Summary

Mount Mentor SPA at **`/mentor/`**. Welcome/ALB forward the **full URI**. Today
this repo assumes the app is at **`/`**:

- `vite.config.ts` has no `base`; `injectRuntimeConfig` loads `/runtime-config.js`
- `src/router/index.ts` uses `createWebHistory()` (home `/` → `/profiles`)
- `nginx.conf.template` has `location /`, `location /api/`, and
  `location = /runtime-config.js`
- Cypress visits `/profiles`, `/resources`, `/paths`, `/plans`, `/encounters`
  against `baseUrl` `http://localhost:8392`

SPA nginx already proxies `/api/` to `mentor_api` (`API_HOST` / `API_PORT`, **8391**).
Local twin: welcome `:8080/mentor/*` → `mentor_spa:80`. Direct port **8392** stays
published.

## Goals

- Vite `base: '/mentor/'`. Router: `createWebHistory(import.meta.env.BASE_URL)`.
  Keep route paths (`/profiles`, `/resources`, …); they become `/mentor/profiles`
  automatically. Do **not** duplicate the prefix in route `path` strings.
- `nginx.conf.template`:
  - `location /mentor/api/` → `http://${API_HOST}:${API_PORT}/api/`.
  - `location /mentor/` maps the prefix onto the dist root (Vite `base` changes
    asset URLs, not the output folder). Internal rewrite is OK.
  - Keep `location /api/` for **direct-port** debugging.
  - Prefixed `runtime-config.js` (and keep `/runtime-config.js` for direct port).
  - Optional: `location = /` redirect to `/mentor/` so `http://<host>:8392/` still works.
- Vite HTML inject must load runtime-config under the prefix (or
  `import.meta.env.BASE_URL`).
- Vite `server.proxy` should also proxy `/mentor/api` to `localhost:8391` for
  `npm run dev` under the base.
- Cypress `baseUrl` stays `http://localhost:8392`; visits become `/mentor/profiles`,
  `/mentor/resources`, etc.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; CloudFormation ALB; F-US09 implementation.

## Acceptance

- `http://<host>:8080/mentor/` serves this SPA (not welcome `index.html`).
- `http://<host>:8392/mentor/` works for single-SPA Cypress.
- API calls from the prefixed origin hit `mentor_api` via SPA nginx.
- `npm run lint`, `npm run test`, Cypress e2e pass.
