Please create @_PLANNING.MD tasks to implement this issue. Only create tasks, do not edit any files outside of the @tasks folder.

**GitHub**: https://github.com/mentor-forge/mentorhub_admin_spa/issues/3

# F-AS01: Vue base + SPA nginx prefix `/admin/` (Admin SPA)

**Unblocked:** mentorhub welcome nginx (L022) already forwards the **full URI**
`http://<host>:8080/admin/` to this container with `X-Forwarded-Prefix: /admin`.
This issue is what remains so same-origin JWT `localStorage` works when opening
Admin via `:8080/admin/`.

## Summary

Mount Admin SPA at **`/admin/`**. Welcome and cloud ALB forward the **full URI**;
do not rely on welcome `rewrite` hacks. Today this repo assumes the app is at **`/`**:

- `vite.config.ts` has no `base` and no runtime-config inject
- `src/router/index.ts` uses `createWebHistory()` with `/` → `/admin` plus `/home`
- `nginx.conf.template` has `location /` + `location /api/` only
- SPA nginx already proxies `/api/` to `admin_api` (`API_HOST` / `API_PORT`, **8389**)

Local twin: welcome `:8080/admin/*` → `admin_spa:80`. Direct port **8390** stays
published.

Admin **webhook ingress** (F-AA01) stays a **separate URL** — do not serve
Stripe/Cognito webhooks under this browser prefix.

## Goals

- Vite `base: '/admin/'`. Router: `createWebHistory(import.meta.env.BASE_URL)`.
- **Avoid `/admin/admin`:** with that base, do not keep a route `path: '/admin'`.
  Serve the admin page at `/` (today `/` redirects to `/admin`). Keep `/home` as
  `/home` → `/admin/home`.
- `nginx.conf.template`:
  - `location /admin/api/` → `http://${API_HOST}:${API_PORT}/api/`.
  - `location /admin/` maps the prefix onto the dist root (Vite `base` changes
    asset URLs, not the output folder). Internal rewrite is OK.
  - Keep `location /api/` for **direct-port** debugging.
  - Optional: `location = /` redirect to `/admin/` so `http://<host>:8390/` still works.
- If you add `runtime-config.js` inject, load it under `/admin/runtime-config.js`
  as well as `/runtime-config.js`.
- Vite `server.proxy` should also proxy `/admin/api` to `localhost:8389` for
  `npm run dev` under the base.
- Cypress visits become `/admin/` (home), not `/admin` as a second path segment.
  Direct port **8390**.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; F-AA01 ingress routes; CloudFormation ALB; F-US09 implementation.

## Acceptance

- `http://<host>:8080/admin/` serves this SPA (not welcome `index.html`).
- `http://<host>:8390/admin/` works for single-SPA Cypress.
- In-app routes are `/admin/...`, not `/admin/admin/...`.
- API calls from the prefixed origin hit `admin_api` via SPA nginx.
- Webhook ingress is **not** mounted under `/admin/`.
- `npm run lint`, `npm run test`, Cypress e2e pass.
