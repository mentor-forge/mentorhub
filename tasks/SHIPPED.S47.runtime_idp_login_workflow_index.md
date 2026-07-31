# S47 – Cross-repo workflow index: runtime `IDP_LOGIN_URI`

Status: Shipped
Type: Feature
Depends On: none
Description: Master index for the F-W08 SPA login guardrails fix. Execution tasks live in each repository's `tasks/` folder; this file is the single place in **mentorhub** to see the full serial workflow across `mentorhub`, `mentorhub_spa_utils`, `mentorhub_mentee_spa`, and `mentorhub_mentor_spa`.

## Context

- ./tasks/SHIPPED.S44.compose_idp_login_uri_journey_spas.md
- ./tasks/SHIPPED.S45.manual_approval_container_idp_redirect.md
- ./tasks/SHIPPED.S46.document_runtime_idp_login_uri.md
- ../mentorhub_spa_utils/tasks/SHIPPED.F029.runtime_idp_login_uri_resolution.md
- ../mentorhub_spa_utils/tasks/SHIPPED.F030.bump_patch_release_0_5_7.md
- ../mentorhub_spa_utils/tasks/SHIPPED.F031.wait_codeartifact_0_5_7_publish.md
- ../mentorhub_mentee_spa/tasks/SHIPPED.L122.runtime_idp_login_container_wiring.md
- ../mentorhub_mentee_spa/tasks/SHIPPED.L123.integration_test_idp_redirect.md
- ../mentorhub_mentee_spa/tasks/SHIPPED.L125.adopt_spa_utils_0_5_7_codeartifact.md
- ../mentorhub_mentee_spa/tasks/SHIPPED.L126.manual_approval_codeartifact_build.md
- ../mentorhub_mentor_spa/tasks/SHIPPED.R146.runtime_idp_login_container_wiring.md
- ../mentorhub_mentor_spa/tasks/SHIPPED.R147.manual_approval_mentor_spa.md

## Why tasks are split across repos

`mentorhub/tasks/_ORCHESTRATE.md` limits **orchestrated execution** to files in this repo. Code changes to spa_utils and journey SPAs must be executed from **their own** `tasks/` folders (each repo's `_ORCHESTRATE.md` / `_PLANNING.md`). This index links the serial chain so nothing is missed when planning from mentorhub.

## Goal

Same SPA container image honors **`IDP_LOGIN_URI`** at runtime in every environment (`npm run dev` → `127.0.0.1`; container + `mh` + MagicDNS → `http://<HOST_NAME>:8080/login.html`; cloud → Cognito URL).

## Serial workflow

| Step | Repo | Task file | What changes |
|------|------|-----------|--------------|
| 1 | **mentorhub** | `SHIPPED.S44` | Confirm compose passes `IDP_LOGIN_URI`; `make update` |
| 2 | **spa_utils** | `SHIPPED.F029` | Runtime `IDP_LOGIN_URI` in `idpRedirect.ts`; remove 0.5.6 hostname rewrite |
| 3 | **mentee_spa** | `SHIPPED.L122` | Local `file:../mentorhub_spa_utils`; Dockerfile/nginx runtime config injection |
| 4 | **mentee_spa** | `SHIPPED.L123` | Integration test: `npm run container` + `mh up mentee` |
| 5 | **mentorhub** | `SHIPPED.S45` | **Mike:** manual redirect test over MagicDNS |
| 6 | **spa_utils** | `SHIPPED.F030` | Bump **0.5.7**, commit, push, open PR |
| 7 | **spa_utils** | `SHIPPED.F031` | **Mike:** merge, tag, confirm CodeArtifact publish |
| 8 | **mentee_spa** | `SHIPPED.L125` | Switch to CodeArtifact `@mentor-forge/mentorhub_spa_utils@0.5.7`; test dev + container |
| 9 | **mentee_spa** | `SHIPPED.L126` | **Mike:** re-test and merge mentee PR |
| 10 | **mentor_spa** | `SHIPPED.R146` | Same runtime wiring + spa_utils 0.5.7 (CodeArtifact) |
| 11 | **mentor_spa** | `SHIPPED.R147` | **Mike:** re-test and merge mentor PR |
| 12 | **mentorhub** | `SHIPPED.S46` | Update `sre_standards.md`, `spa_standards.md`, `CONTRIBUTING.md` |

## Branches

- **mentorhub**, **mentee_spa**, **mentor_spa:** **F-W08** branches (merge PRs to `main` when ready).
- **spa_utils:** **0.5.7** on `main` (F029–F031).

## Testing Expectations

- No code changes in this task — index only.
- Confirm all linked task files exist before starting step 1.

## Outputs

- This file only (`tasks/SHIPPED.S47.runtime_idp_login_workflow_index.md`).

## Execution Notes

**Completed (2026-07-31):** All 12 steps shipped. F-W08 runtime `IDP_LOGIN_URI` workflow complete.

- spa_utils **0.5.7** on CodeArtifact; mentee + mentor SPAs inject runtime config at container startup.
- Developer Edition: `mh` + `HOST_NAME` → MagicDNS IdP; `npm run dev` uses `.env.development` (`127.0.0.1`).
- Docs: S46 updated standards + CONTRIBUTING.

**PRs:** mentee_spa #27, mentor_spa #32, spa_utils #28 (merged).
