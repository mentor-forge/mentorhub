# S51 – Remove Coordinator from clone-all, standards, README, workspace refs

Status: Pending
Type: Feature
Depends On: S48
Description: F-W09 E0 — Remove remaining Developer Edition and platform references to deleted coordinator GitHub repos (`mentorhub_coordinator_api`, `mentorhub_coordinator_spa`).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/customer_journey_issues.md (F-W09)
- ./Specifications/architecture.yaml (updated by S48)
- ./Makefile
- ./DeveloperEdition/standards/branch_protection_standards.md
- ./Research/stripe_research.md

## Goals

- **`Makefile` `clone-all` target:** Remove `mentorhub_coordinator_api` and `mentorhub_coordinator_spa` from the clone loop. Do not add admin/discovery repos yet (BLOCKED.S53 / F-W18).
- **`DeveloperEdition/standards/branch_protection_standards.md`:** Remove coordinator API/SPA rows from repo and CI tables.
- **`README.md` Quick Start:** Update the port-range note (`8383-8394`) to reflect architecture after S48 (e.g. `8383-8398` including planned Discovery ports; coordinator ports removed).
- **Workspace references:** Search repo root for `*.code-workspace` and any docs listing coordinator folders. If `mentorhub.code-workspace` (or similar) exists, remove coordinator folder entries. If no workspace file exists, record no-op in Execution Notes — do not create a workspace file in this task.
- **`Research/stripe_research.md`:** Remove or update the stale “Under reflection — do not delete customer SPA/API” note now that the Coordinator microservice decision is locked (Customer API/SPA remain; Coordinator repos deleted).
- Do **not** edit historical workshop transcripts, fundraising copy, or MongoDB test-data docs — minimal scope only.

## Testing Expectations

- `grep -r coordinator Makefile DeveloperEdition/standards/branch_protection_standards.md README.md Research/stripe_research.md` — no references to `mentorhub_coordinator_*` or coordinator compose profiles.
- Markdown lint on touched files.
- `make clone-all` dry review — loop list has no coordinator repos.

## Outputs

- `Makefile` — update `clone-all` repo list.
- `DeveloperEdition/standards/branch_protection_standards.md` — remove coordinator rows.
- `README.md` — update port-range note.
- `Research/stripe_research.md` — update stale coordinator/customer boundary note (if present).

## Execution Notes
