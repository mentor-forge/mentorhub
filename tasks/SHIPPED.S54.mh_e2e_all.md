# S54 – Add `mh e2e all` to run API e2e and SPA Cypress across architecture.yaml repos

Status: Shipped
Type: Feature
Depends On: S53
Description: Add `mh e2e all` that walks repositories in `Specifications/architecture.yaml`, runs `pipenv run e2e` for APIs and `npm run cypress:run` for SPAs (excluding mongodb_api, runbook_api, api_utils, spa_utils, and spa_ref), continues after failures, and prints a pass/fail report by repo.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/mh (S53 helper for architecture.yaml repo iteration)
- ./Specifications/architecture.yaml
- ./DeveloperEdition/standards/system_tour.md (per-repo `pipenv run e2e` / `npm run cypress:run`)
- ./DeveloperEdition/standards/api_standards.md
- ./DeveloperEdition/standards/spa_standards.md

## Goals

- Add an `e2e` command to `DeveloperEdition/mh` invoked as `mh e2e all`.
  - `$COMMAND` is `e2e`; `$NEW_PROFILE` must be `all`. If `all` is missing, print usage and return non-zero.
  - Do **not** add `e2e` to the docker-start case; this command does not start or stop compose services.
  - Do **not** call `ensureDevServices` / GHCR / CodeArtifact login for this command.
- Reuse the S53 architecture.yaml iterator. From each repo’s `name` and `type`:
  - **Exclude** (do not run): `mongodb_api`, `runbook_api`, `api_utils`, `spa_utils`, and any `type: spa_ref`.
  - **Include** journey APIs (`type: api`): `customer_api`, `admin_api`, `discovery_api`, `mentor_api`, `mentee_api`.
  - **Include** journey SPAs (`type: spa`): `customer_spa`, `admin_spa`, `discovery_spa`, `mentor_spa`, `mentee_spa`.
- Resolve folders as `$LAUNCHPAD_HOST/mentorhub_<name>`.
- Run tests **sequentially** (not in parallel) to avoid port and database contention:
  - API (`type: api`): `cd` into the folder and run `pipenv run e2e`.
  - SPA (`type: spa`): `cd` into the folder and run `npm run cypress:run`.
- Inherit the existing `mh` environment (`JWT_SECRET` and related exports already set at the top of the script) so API e2e auth matches Developer Edition.
- Per repo: log a clear header (folder name + type), stream the test command output, then record PASS, FAIL, or SKIP.
  - SKIP with reason if the folder is missing, is not a git/workdir, or the expected tool (`pipenv` / `npm`) is absent.
  - FAIL if the test command returns non-zero.
  - Continue to the next repo after FAIL or SKIP — do not abort the loop.
- After all repos, print a report that lists success and failure by repo, plus counts (passed / failed / skipped). Exit `0` only if every **run** repo passed (skips of excluded names do not count as failure; missing included folders count as failure or skip—treat missing included folders as FAIL so an incomplete clone is visible).
- Update in-script `manual` and `usage` to document `e2e all`.
- Document in the usage text that the Developer Edition stack (or per-repo API/SPA servers) must already be running; this command does not start them.

## Testing Expectations

- `zsh -n DeveloperEdition/mh` — no syntax errors.
- `shellcheck DeveloperEdition/mh` if available.
- Confirm the exclusion list: a dry `yq` + filter does **not** emit `mongodb_api`, `runbook_api`, `api_utils`, `spa_utils`, `configurator_spa`, or `runbook_spa`.
- Confirm included set is the ten journey API/SPA repos above.
- `mh e2e` (no `all`) prints usage and exits non-zero.
- `mh e2e all` with at least one missing folder still produces the end-of-run report (do not require a full green suite to ship the script).
- If a local stack is up, optionally smoke one API and one SPA path; otherwise syntax + dry-filter review is sufficient for this task.

## Outputs

- `DeveloperEdition/mh` — `e2e` command, per-repo runner, outcome tracking, final report, usage/manual updates.

## Execution Notes

- Implemented `e2eAll` in `DeveloperEdition/mh`, reusing
  `listArchitectureRepos` and running the ten journey API/SPA repositories
  sequentially.
- Excluded `mongodb_api`, `runbook_api`, `api_utils`, and `spa_utils`
  explicitly; `spa_ref` entries remain filtered by `listArchitectureRepos`.
- Missing included folders are recorded as FAIL; non-worktrees and missing
  `pipenv`/`npm` tools are recorded as SKIP. All outcomes continue to the final
  per-repository report and passed/failed/skipped counts.
- Updated `manual` and `usage` for `mh e2e all`, including the requirement that
  the stack (or per-repo servers) must already be running.
- Validation:
  - `zsh -n DeveloperEdition/mh` passed.
  - Dry `yq` plus the e2e filter emitted exactly the ten journey repositories
    and none of the excluded or `spa_ref` repositories.
  - `zsh DeveloperEdition/mh e2e` printed usage and exited with status 1.
  - `shellcheck` was not installed, so that optional check was skipped.
  - Full e2e suites were not run; a green local stack is not required for this
    task.
