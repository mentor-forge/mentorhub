# Vue base + SPA nginx prefix `/customer/` (Customer SPA)

> **Cross-repo issue artifact.** Paste into a GitHub issue (or `_PLANNING.md` prompt) in
> **`mentorhub_customer_spa`**. Not part of the `PENDING.*` orchestration chain in
> `mentorhub` and must not be executed from that folder.
>
> **Blocked on:** mentorhub welcome nginx journey proxy (L022).
> **Blocks:** same-origin JWT `localStorage` when opening Customer via `:8080/customer/`.

## Summary

Mount Customer SPA at **`/customer/`**. Welcome and cloud ALB forward the **full URI**;
do not rely on welcome `rewrite` hacks. SPA nginx continues to proxy API traffic to
`customer_api` (`API_HOST` / `API_PORT`). Local twin: welcome `:8080/customer/*` →
`customer_spa:80`.

## Goals

- Vite `base: '/customer/'`; Vue `createWebHistory('/customer/')`.
- nginx: `location /customer/` history `try_files`; `location /customer/api/` →
  `http://${API_HOST}:${API_PORT}/api/`.
- Optional `/` → `/customer/` redirect on direct port **8388**.
- Cypress and asset paths use `/customer/`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.
- Keep Stripe Checkout return URLs compatible with the prefixed origin when those tickets land.

## Out of scope

- Welcome nginx; CloudFormation ALB; Customer API; F-US09 implementation.

## Planning prompt (for `mentorhub_customer_spa` `tasks/_PLANNING.md`)

```
Create @_PLANNING.md tasks to implement Vue base and nginx prefix /customer/
so the SPA works behind Developer Edition welcome and cloud ALB path routing.
Only create tasks, do not execute tasks, do not edit any files outside of the tasks folder.
See mentorhub/tasks/ISSUE.mentorhub_customer_spa.vue_base_and_nginx_prefix.md
```
