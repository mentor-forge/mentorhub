# Vue base + SPA nginx prefix `/mentor/` (Mentor SPA)

> **Cross-repo issue artifact.** Paste into a GitHub issue (or `_PLANNING.md` prompt) in
> **`mentorhub_mentor_spa`**. Not part of the `PENDING.*` orchestration chain in
> `mentorhub` and must not be executed from that folder.
>
> **Blocked on:** mentorhub welcome nginx journey proxy (L022).
> **Blocks:** same-origin JWT `localStorage` when opening Mentor via `:8080/mentor/`.

## Summary

Mount Mentor SPA at **`/mentor/`**. Welcome/ALB forward the **full URI**; SPA nginx
proxies API calls to `mentor_api`.

## Goals

- Vite `base: '/mentor/'`; Vue `createWebHistory('/mentor/')`.
- nginx: `location /mentor/` history `try_files`; `location /mentor/api/` →
  `http://${API_HOST}:${API_PORT}/api/` (port **8391**).
- Optional `/` → `/mentor/` redirect on direct port **8392**.
- Cypress visits `/mentor/`.
- `IDP_LOGIN_URI` remains `http://<HOST_NAME>:8080/login.html`.

## Out of scope

- Welcome nginx; CloudFormation ALB; F-US09 implementation.

## Planning prompt (for `mentorhub_mentor_spa` `tasks/_PLANNING.md`)

```
Create @_PLANNING.md tasks to implement Vue base and nginx prefix /mentor/
so the SPA works behind Developer Edition welcome and cloud ALB path routing.
Only create tasks, do not execute tasks, do not edit any files outside of the tasks folder.
See mentorhub/tasks/ISSUE.mentorhub_mentor_spa.vue_base_and_nginx_prefix.md
```
