# Vue base + SPA nginx prefix `/mentee/` (Mentee SPA)

> **Cross-repo issue artifact.** Paste into a GitHub issue (or `_PLANNING.md` prompt) in
> **`mentorhub_mentee_spa`**. Not part of the `PENDING.*` orchestration chain in
> `mentorhub` and must not be executed from that folder.
>
> **Blocked on:** mentorhub welcome nginx journey proxy (L022).
> **Blocks:** same-origin JWT `localStorage` when opening Mentee via `:8080/mentee/`.

## Summary

Mount Mentee SPA at **`/mentee/`**. Welcome/ALB forward the **full URI**; SPA nginx
proxies API calls to `mentee_api` (`API_HOST` / `API_PORT`). Local twin: welcome
`:8080/mentee/*` → `mentee_spa:80`.

## Goals

- Vite `base: '/mentee/'`; Vue `createWebHistory('/mentee/')`.
- nginx: `location /mentee/` history `try_files`; `location /mentee/api/` →
  `http://${API_HOST}:${API_PORT}/api/` (port **8393**).
- Optional `/` → `/mentee/` redirect on direct port **8394**.
- Cypress visits `/mentee/`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; CloudFormation ALB; F-US09 implementation.

## Planning prompt (for `mentorhub_mentee_spa` `tasks/_PLANNING.md`)

```
Create @_PLANNING.md tasks to implement Vue base and nginx prefix /mentee/
so the SPA works behind Developer Edition welcome and cloud ALB path routing.
Only create tasks, do not execute tasks, do not edit any files outside of the tasks folder.
See mentorhub/tasks/ISSUE.mentorhub_mentee_spa.vue_base_and_nginx_prefix.md
```
