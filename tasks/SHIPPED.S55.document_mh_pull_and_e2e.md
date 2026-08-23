# S55 – Document `mh pull all` git sync and `mh e2e all` in developer guides

Status: Shipped
Type: Feature
Depends On: S54
Description: Update Developer Edition onboarding docs so `mh pull all` git-sync and `mh e2e all` match the S53/S54 CLI behavior.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/standards/system_tour.md
- ./DeveloperEdition/mh (S53 + S54 behavior)
- ./Specifications/architecture.yaml

## Goals

- Update `DeveloperEdition/standards/system_tour.md`:
  - `mh pull all` currently says it only pulls containers. Document that with parameter `all` it also `git fetch && git pull`s each real repo listed in `Specifications/architecture.yaml` (sibling folders `mentorhub_<name>`), then still pulls compose images for profile `all`.
  - Add an `mh e2e all` step after the per-repo e2e/Cypress tour: run black-box tests for every journey API (`pipenv run e2e`) and journey SPA (`npm run cypress:run`), driven by `architecture.yaml` types, excluding `mongodb_api`, `runbook_api`, `api_utils`, `spa_utils`, and `spa_ref` entries. Note that the stack must already be up (`mh up all` or equivalent) and that a pass/fail report is printed at the end.
- Update `CONTRIBUTING.md` only if there is an existing `mh` command list or developer-workflow section that should mention the two commands; do not invent a large new CLI chapter. A short note under Developer Edition / system tour cross-reference is enough if no command list exists.
- Do **not** change `README.md` Quick Start (non-contributor docker-compose path) unless it already documents `mh pull` / `mh e2e`.
- Do **not** change `DeveloperEdition/mh` in this task (usage/manual already updated in S53/S54).

## Testing Expectations

- Markdown lint on touched files if tooling is available.
- Grep docs: `mh pull all` mentions git fetch/pull and architecture.yaml; `mh e2e all` is documented with exclusions and the report.
- Confirm docs do not claim that mongodb_api, runbook_api, api_utils, or spa_utils are included in `mh e2e all`.

## Outputs

- `DeveloperEdition/standards/system_tour.md` — document git sync on `mh pull all` and the `mh e2e all` workflow.
- `CONTRIBUTING.md` — only if a short cross-reference is warranted.

## Execution Notes

- Plan: document the shipped `mh pull all` repository sync and `mh e2e all` journey-suite behavior in the system tour without changing the CLI, install workflow, or Quick Start.
- Documentation: updated `DeveloperEdition/standards/system_tour.md`; no `CONTRIBUTING.md` change was needed because the system tour is already linked from its onboarding and standards sections.
- Verification commands:
  - `rg -n -i 'mh pull all|git fetch|git pull|architecture\.yaml|compose images|profile \`all\`' DeveloperEdition/standards/system_tour.md`
  - `rg -n -i 'mh e2e all|pipenv run e2e|npm run cypress:run|mongodb_api|runbook_api|api_utils|spa_utils|spa_ref|pass/fail report' DeveloperEdition/standards/system_tour.md`
- Results: both searches passed and confirmed the commands, architecture-driven behavior, test runners, exclusions, running-stack prerequisite, and final report. Markdown lint tooling was not available in the environment.
- Follow-ups: none.
