Please create @_PLANNING.MD tasks to implement this issue. Only create tasks, do not edit any files outside of the @tasks folder.

**GitHub**: https://github.com/mentor-forge/mentorhub_customer_spa/issues/14

# F-CS11: Vue base + SPA nginx prefix `/customer/` (Customer SPA)

**Unblocked:** mentorhub welcome nginx (L022) already forwards the **full URI**
`http://<host>:8080/customer/` to this container with `X-Forwarded-Prefix: /customer`.
This issue is what remains so same-origin JWT `localStorage` works when opening
Customer via `:8080/customer/`.

## Summary

Mount Customer SPA at **`/customer/`**. Welcome and cloud ALB forward the **full URI**;
do not rely on welcome `rewrite` hacks. Today this repo assumes the app is at **`/`**:

- `vite.config.ts` has no `base` and no runtime-config inject
- `src/router/index.ts` uses `createWebHistory()` (home `/` → `/subscriptions`)
- `nginx.conf.template` has `location /` + `location /api/` only
- SPA nginx already proxies `/api/` to `customer_api` (`API_HOST` / `API_PORT`, **8387**)

Local twin: welcome `:8080/customer/*` → `customer_spa:80`. Direct port **8388**
stays published.

## Goals

- Vite `base: '/customer/'`. Router: `createWebHistory(import.meta.env.BASE_URL)`.
  Keep route paths (`/subscriptions`, `/profiles`, …); they become
  `/customer/subscriptions` automatically. Do **not** duplicate the prefix in
  route `path` strings.
- `nginx.conf.template`:
  - `location /customer/api/` → `http://${API_HOST}:${API_PORT}/api/`.
  - `location /customer/` maps the prefix onto the dist root (Vite `base` changes
    asset URLs, not the output folder). Internal rewrite is OK.
  - Keep `location /api/` for **direct-port** debugging.
  - Optional: `location = /` redirect to `/customer/` so `http://<host>:8388/` still works.
- If you add `runtime-config.js` inject (other journey SPAs already do), load it
  under `/customer/runtime-config.js` as well as `/runtime-config.js`.
- Vite `server.proxy` should also proxy `/customer/api` to `localhost:8387` for
  `npm run dev` under the base.
- Cypress `baseUrl` stays `http://localhost:8388`; visits become `/customer/...`
  (e.g. `/customer/subscriptions`), not `/subscriptions`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.
- Keep Stripe Checkout return URLs compatible with the prefixed origin when those
  tickets land (no Checkout URLs in this repo yet).

## Out of scope

- Welcome nginx; CloudFormation ALB; Customer API; F-US09 implementation.

## Acceptance

- `http://<host>:8080/customer/` serves this SPA (not welcome `index.html`).
- `http://<host>:8388/customer/` works for single-SPA Cypress.
- API calls from the prefixed origin hit `customer_api` via SPA nginx.
- `npm run lint`, `npm run test`, Cypress e2e pass.
