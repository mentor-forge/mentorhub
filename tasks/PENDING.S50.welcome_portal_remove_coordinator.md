# S50 – Strip Coordinator links from welcome portal (index.html)

Status: Pending
Type: Feature
Depends On: S48
Description: F-W09 E0 — Remove Coordinator SPA/API/GitHub links from the welcome page; Admin + Discovery portal links are added when F-W18 lands (BLOCKED.S53).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./Specifications/architecture.yaml (updated by S48)
- ./index.html
- ./Workshops/customer_journey_issues.md (F-W09)

## Goals

- Remove Coordinator SPA link (`coordinator-spa-link`) and Coordinator API explorer link (`coordinator-api-docs-link`) from `index.html`.
- Remove GitHub source links for `mentorhub_coordinator_api` and `mentorhub_coordinator_spa`.
- Remove JavaScript that sets coordinator hrefs (ports 8389/8390).
- Keep Customer, Mentor, Mentee, and Schema configurator links and port wiring intact.
- Do **not** add Admin/Discovery links yet (placeholder comment optional — full wiring is BLOCKED.S53).
- Do **not** change `login.html` or `welcome-auth.js` mock personas — `coordinator` remains a valid Profile `user_roles` value for local IdP testing.

## Testing Expectations

- Open or statically review `index.html` — no `coordinator` strings remain.
- Remaining SPA/API link IDs still have matching `getElementById` assignments (no JS errors).
- Rebuild welcome container if needed: `make container` (optional smoke).
- HTML/markdown lint if tooling available.

## Outputs

- `index.html` — remove coordinator links and script lines.

## Execution Notes
