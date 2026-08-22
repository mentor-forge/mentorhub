# L027 – Cross-repo workflow index for SPA base-path ISSUEs

Status: Pending
Type: Feature
Depends On: L022.welcome_nginx_journey_proxy
Description: Confirm paste-ready `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md` files exist for every journey SPA, and record the serial workflow: welcome nginx can land first; same-origin navigation is blocked until those repos ship Vue `base` + nginx prefix.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./tasks/_ORCHESTRATE.md (this repo must **not** edit sibling SPA repos)
- ./tasks/SHIPPED.S47.runtime_idp_login_workflow_index.md (index pattern)
- ./tasks/PENDING.L022.welcome_nginx_journey_proxy.md
- ./tasks/ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_customer_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_admin_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_mentor_spa.vue_base_and_nginx_prefix.md
- ./tasks/ISSUE.mentorhub_mentee_spa.vue_base_and_nginx_prefix.md
- mentorhub_cloudformation/ARCHITECTURE.md
- F-US09 (spa_utils cross-repo links) — out of scope to implement; path-based same origin is the prerequisite

## Goals

- Do **not** implement Vue or SPA nginx in this repo.
- Verify each ISSUE file is paste-ready for that SPA’s `_PLANNING.md` (prefix, `createWebHistory`, nginx `try_files`, `/api` under the prefix, dual use of direct host port).
- This index file is the single place in **mentorhub** that lists the follow-on order:

  | Step | Repo | Work |
  | --- | --- | --- |
  | 1 | mentorhub | L022 welcome proxy (no prefix strip) |
  | 2 | each `mentorhub_*_spa` | ISSUE: Vue `base` + nginx `/{journey}/` |
  | 3 | mentorhub | Manual: `http://<host>:8080/discovery/` after SPA images publish |

- If an ISSUE file is missing or the prefix table is wrong, fix the ISSUE file in this task (do not silently add welcome `rewrite` hacks).

## Testing Expectations

- Five ISSUE files exist under `tasks/` and name the correct compose service + prefix.
- This file’s table matches L022 location paths.
- No code changes outside `tasks/` unless an ISSUE file needs a correction (ISSUE files only).

## Outputs

- This file (`tasks/PENDING.L027.issue_spa_base_path.md`) — becomes the workflow index; rename to `SHIPPED.*` when verified.
- `tasks/ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md` — only if a correction is required.

## Execution Notes
