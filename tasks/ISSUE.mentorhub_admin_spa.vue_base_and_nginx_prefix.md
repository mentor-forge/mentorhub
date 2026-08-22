# Vue base + SPA nginx prefix `/admin/` (Admin SPA)

> **Cross-repo issue artifact.** Paste into a GitHub issue (or `_PLANNING.md` prompt) in
> **`mentorhub_admin_spa`**. Not part of the `PENDING.*` orchestration chain in
> `mentorhub` and must not be executed from that folder.
>
> **Blocked on:** mentorhub welcome nginx journey proxy (L022).
> **Blocks:** same-origin JWT `localStorage` when opening Admin via `:8080/admin/`.

## Summary

Mount Admin SPA at **`/admin/`**. Admin **webhook ingress** (F-AA01) stays a **separate
URL** — do not serve Stripe/Cognito webhooks under this browser prefix.

## Goals

- Vite `base: '/admin/'`; Vue `createWebHistory('/admin/')`.
- nginx: `location /admin/` history `try_files`; `location /admin/api/` →
  `http://${API_HOST}:${API_PORT}/api/` (`admin_api` **8389**).
- Optional `/` → `/admin/` redirect on direct port **8390**.
- Cypress visits `/admin/`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; F-AA01 ingress routes; CloudFormation ALB; F-US09 implementation.

## Planning prompt (for `mentorhub_admin_spa` `tasks/_PLANNING.md`)

```
Create @_PLANNING.md tasks to implement Vue base and nginx prefix /admin/
so the SPA works behind Developer Edition welcome and cloud ALB path routing.
Only create tasks, do not execute tasks, do not edit any files outside of the tasks folder.
See mentorhub/tasks/ISSUE.mentorhub_admin_spa.vue_base_and_nginx_prefix.md
```
