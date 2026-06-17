# R010 – Complete Profile RBAC via shared Config role constants

**Status**: Pending  
**Task Type**: Feature  
**Run Mode**: Sequential  <!-- options: Sequential | Run as needed -->

## Goal

Finish the Profile role-based access control (RBAC) feature so that:
- `mentor_api` consumes shared role constants from `api_utils.Config` instead of declaring role strings locally.
- The Profile endpoints authorize **both** the `mentor` and `admin` roles.
- The change is fully releasable: `api_utils` is published with the new constants and `mentor_api` pins that published version (no editable-install dependency).

## Context / Input files

These files must be treated as **inputs** and read before implementation:

- `mentorhub_api_utils/api_utils/config/config.py` – role constants (`ADMIN_ROLE`, `MENTOR_ROLE`, `MENTEE_ROLE`, `CUSTOMER_ROLE`, `COORDINATOR_ROLE`, `ALL_ROLES`)
- `mentorhub_api_utils/pyproject.toml` – package version to bump
- `mentorhub_mentor_api/Pipfile` – `api-utils` version pin (currently `==0.2.1`)
- `mentorhub_mentor_api/src/services/profile_service.py` – `_check_permission` (mentor OR admin)
- `mentorhub_mentor_api/test/services/test_profile_service.py` – RBAC unit tests
- `mentorhub_mentor_api/docs/openapi.yaml` – Profile endpoint docs (role wording + `403` responses)

The agent may also consult:

- `mentorhub/DeveloperEdition/standards/api_standards.md` – API + documentation standards.
- CodeArtifact publishing/auth flow (`mh` CLI) used by sibling services.

## Requirements

- **api_utils**
  - Confirm the role constants in `Config` are exposed and importable as `Config.MENTOR_ROLE` / `Config.ADMIN_ROLE` (already implemented locally).
  - Bump the package version in `pyproject.toml`.
  - Build and publish the package to CodeArtifact.
- **mentor_api**
  - Replace any locally declared role strings with the shared `Config` constants (already implemented locally).
  - Authorize both `mentor` and `admin` for all Profile operations.
  - Bump the `api-utils` pin in `Pipfile` to the newly published version and reinstall (`pipenv run install`) so the build no longer relies on an editable install.
  - Ensure `openapi.yaml` documents the role requirement ("`mentor` or `admin`") and the `403` response on both Profile endpoints (already implemented locally).

## Testing expectations

- **Unit tests**
  - `pipenv run test` in `mentorhub_mentor_api` and `mentorhub_api_utils`.
  - Cover: mentor allowed, admin allowed, other roles denied (`403`).
- **End-to-end (e2e) tests**
  - `pipenv run e2e` in `mentorhub_mentor_api` (against a running API at `localhost:8391`).
  - Confirm the Mentor Dashboard endpoint returns the expected dashboard card structure for an authorized role.

## Packaging / build checks

Before marking this task as completed:

- `api_utils`: build/publish succeeds and the new version is resolvable from CodeArtifact.
- `mentor_api`: `pipenv run install` resolves the new `api-utils` pin (no editable install), and `pipenv run container` (or `make container`) builds successfully.
- No new linter/type-checking errors (`pipenv run lint`).

## Dependencies / Ordering

- Must run **after**: `api_utils` role constants are merged and published (the `mentor_api` Pipfile pin cannot be bumped until the new version exists in CodeArtifact).
- **Blocking note**: the `mentor_api` RBAC commit currently passes only because of an editable install of `api_utils`; it is not mergeable until the published version + Pipfile pin are in place.
- Related branches/PRs:
  - `api_utils`: `feature/role-constants` (PR #5)
  - `mentor_api`: `dashboard-refactor` (PR #4, draft) — RBAC + Mentee domain + OpenAPI
  - `mentorhub`: `feature/R010-profile-rbac-task` (PR #16) — tasks R010–R012

## Open questions / handoff (BLOCKED on team)

The implementation is complete, tested, and in review; the remaining steps are
process/infra steps owned by the team, not coding:

1. **Review + merge** PR #5, PR #4, PR #16.
2. **Publish `api_utils`** — there is **no manual publish in this repo**: the
   `publish-package` Pipfile script is a no-op, there is no `.github/workflows/`,
   and `pyproject.toml` still says `0.1.0` while consumers pin `0.2.1`. Publishing
   therefore happens in a **centralized/CI pipeline** on merge to `main`.
3. **OPEN QUESTION for the team**: when PR #5 merges, *what `api_utils` version
   gets published to CodeArtifact, and how is that number decided* (auto-bump by
   the pipeline, git tag, or manual)? This is the single blocker for steps below.
4. Once the published version is known: bump the `mentor_api` `Pipfile` pin off
   `==0.2.1`, run `pipenv run install`, and take PR #4 out of draft.

## Change control checklist

- [x] Reviewed all **Context / Input files**.
- [x] Designed and documented the solution approach in this file.
- [x] Implemented code changes (role constants + RBAC + OpenAPI wording).
- [ ] Bumped `api_utils` version and published to CodeArtifact. _(BLOCKED — CI/pipeline owned; see Open questions.)_
- [ ] Bumped `mentor_api` `Pipfile` pin and reinstalled (no editable install). _(BLOCKED on publish.)_
- [x] Added/updated **unit tests**.
- [x] Added/updated **e2e tests**.
- [x] Ran unit tests and e2e tests; all passing (locally, via editable `api_utils`).
- [ ] Ran packaging/build steps (`pipenv run container` / `make container`); build successful.
- [x] Created scoped commits referencing this task ID.

## Implementation notes (to be updated by the agent)

**Summary of changes**
- Role constants added to `api_utils/config/config.py` (`ADMIN_ROLE`, `MENTOR_ROLE`, `MENTEE_ROLE`, `CUSTOMER_ROLE`, `COORDINATOR_ROLE`, `ALL_ROLES`).
- `ProfileService` uses `Config.MENTOR_ROLE`/`Config.ADMIN_ROLE`; OpenAPI Profile descriptions updated to "mentor or admin" with `403` responses.

**Testing results**
- Unit tests: `pipenv run test` (mentor_api) — 145 passed.
- E2E tests: `pipenv run e2e` (mentor_api) — 26 passed, 1 skipped (no mentee data for the test persona).
- Packaging/build: not yet run (blocked on the published `api_utils` version + Pipfile pin).

**Status**: Implemented and in review (PRs #5 / #4 / #16). Not "Shipped" until
`api_utils` is published, the `mentor_api` pin is bumped, and the PRs merge.

**Follow-up tasks**
- Adopt the shared role constants in the other domain APIs (coordinator, customer, mentee) to remove their local role strings.
- Replace the `Note`-backed mentee notes with Mary's dedicated Mentee schema when published (see R012).
