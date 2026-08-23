# Vue base + SPA nginx prefix `/discovery/` (Discovery SPA)

> **Cross-repo issue artifact.** Paste into a GitHub issue (or `_PLANNING.md` prompt) in
> **`mentorhub_discovery_spa`**. Not part of the `PENDING.*` orchestration chain in
> `mentorhub` and must not be executed from that folder.
>
> **Blocked on:** mentorhub welcome nginx journey proxy (L022) landing so
> `http://<host>:8080/discovery/` forwards the **full URI** to this container.
> **Blocks:** same-origin JWT `localStorage` for Discovery as default post-login landing.

## Summary

Mount Discovery SPA at **`/discovery/`** so Developer Edition welcome (and cloud ALB) can
serve it on a **shared hostname**. Today `createWebHistory()` and nginx `location /`
assume the app is at **`/`**. Welcome **must not** strip the prefix; this repo must honor it.

Cloud intent: `/{journey}/*` → SPA nginx; SPA nginx still proxies API calls to
`discovery_api`. Local twin: welcome `:8080/discovery/*` → `discovery_spa:80`.

## Goals

- Vite `base: '/discovery/'` (or `import.meta.env.BASE_URL` from that base).
- Vue Router `createWebHistory('/discovery/')` (same `BASE_URL`).
- SPA `nginx.conf.template`:
  - `location /discovery/` `try_files` → `/discovery/index.html` (history mode).
  - API proxy under the prefix, e.g. `location /discovery/api/` → `http://${API_HOST}:${API_PORT}/api/`
    (keep a `location /api/` only if still required for **direct-port** debugging).
  - Optional: `location = /` redirect to `/discovery/` so `http://<host>:8398/` still works.
- Asset URLs, `runtime-config.js`, and Cypress visit **`/discovery/`** (not `/`).
- Direct host port **8398** remains published; use `http://<host>:8398/discovery/` for
  single-SPA Cypress. Do not maintain a second “root-only” build.
- `IDP_LOGIN_URI` stays `http://<HOST_NAME>:8080/login.html` (same origin as welcome).
- Do **not** turn Discovery into a reverse proxy or micro-frontend shell (F-DS01 is the
  product landing page, not the edge router).

## Out of scope

- Welcome `nginx.conf` / ALB CloudFormation.
- F-US09 CrossRepoLink implementation in spa_utils.
- F-W10 login.html tabs.

## Planning prompt (for `mentorhub_discovery_spa` `tasks/_PLANNING.md`)

```
Create @_PLANNING.md tasks to implement Vue base and nginx prefix /discovery/
so the SPA works behind Developer Edition welcome and cloud ALB path routing.
Only create tasks, do not execute tasks, do not edit any files outside of the tasks folder.
See mentorhub/tasks/ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md
```
