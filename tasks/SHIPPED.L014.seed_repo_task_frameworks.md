# L014 – Seed task automation frameworks in four new repos

Status: Shipped
Type: Feature
Depends On: L013.bootstrap_discovery_spa
Description: F-W18 — Confirm each new Admin/Discovery repo has `tasks/_PLANNING.md` and `tasks/_ORCHESTRATE.md` adapted from live journey repo templates so F-AA-L001, F-AS-L001, F-DA-L001, and F-DS-L001 planning agents can run in-repo.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (After copy: confirm tasks frameworks)
- ./tasks/_PLANNING.md (umbrella template reference)
- ./tasks/_ORCHESTRATE.md (umbrella template reference)
- ../mentorhub_mentee_api/tasks/_PLANNING.md (API repo template)
- ../mentorhub_mentee_api/tasks/_ORCHESTRATE.md (API repo template)
- ../mentorhub_customer_spa/tasks/_PLANNING.md (SPA repo template)
- ../mentorhub_mentee_spa/tasks/_ORCHESTRATE.md (SPA repo template)
- ../mentorhub_admin_api/, ../mentorhub_admin_spa/, ../mentorhub_discovery_api/, ../mentorhub_discovery_spa/ (targets — must exist from L010–L013)

## Goals

- **Blocked gate:** If any of L010–L013 repos are still empty or missing pushed bootstrap commits, set this task **Status** to `Blocked` and stop.
- Add `tasks/_PLANNING.md` to each new repo, adapted from the appropriate sibling template:
  - `mentorhub_admin_api`, `mentorhub_discovery_api` ← mentee/customer **API** `_PLANNING.md` patterns (path anchoring to repo root with `Pipfile`; OpenAPI port from `architecture.yaml`).
  - `mentorhub_admin_spa`, `mentorhub_discovery_spa` ← customer/mentee **SPA** `_PLANNING.md` patterns.
- Add `tasks/_ORCHESTRATE.md` to each new repo with the standard orchestration model (single-repo scope, branch check, PENDING→SHIPPED lifecycle).
- Update repo-specific references in each file:
  - Repository name (`mentorhub_admin_api`, etc.).
  - Default API port (**8389** / **8397**) for OpenAPI curl examples.
  - Workshop context links (`Workshops/` lives in umbrella `mentorhub` — use `../mentorhub/Workshops/...` paths).
- Commit and push task-framework files in each of the four repos (one commit per repo or single coordinated push per team convention).

## Testing Expectations

- Each repo contains both `tasks/_PLANNING.md` and `tasks/_ORCHESTRATE.md`.
- Path anchoring in API repo files references correct local port (8389 or 8397) in OpenAPI curl examples.
- Markdown lint on all eight new task framework files if tooling available.
- No references to wrong repo names (`mentorhub_mentee_api`, `mentorhub_customer_spa`, etc.) in path anchoring sections.

## Outputs

- `../mentorhub_admin_api/tasks/_PLANNING.md`
- `../mentorhub_admin_api/tasks/_ORCHESTRATE.md`
- `../mentorhub_admin_spa/tasks/_PLANNING.md`
- `../mentorhub_admin_spa/tasks/_ORCHESTRATE.md`
- `../mentorhub_discovery_api/tasks/_PLANNING.md`
- `../mentorhub_discovery_api/tasks/_ORCHESTRATE.md`
- `../mentorhub_discovery_spa/tasks/_PLANNING.md`
- `../mentorhub_discovery_spa/tasks/_ORCHESTRATE.md`

## Execution Notes

- Seeded `tasks/_PLANNING.md` and `tasks/_ORCHESTRATE.md` in all four repos from mentee API/SPA templates.
- API repos: ports **8389** / **8397** in OpenAPI curl examples; workshop links to `admin_journey_issues.md` / `discovery_journey_issues.md`.
- Commits pushed: `mentorhub_admin_api` `9715556`, `mentorhub_admin_spa` `d4d0151`, `mentorhub_discovery_api` `248a1c4`, `mentorhub_discovery_spa` `1fda127`.
- Verified each repo contains both framework files; no wrong `mentorhub_mentee_*` anchors in path sections.