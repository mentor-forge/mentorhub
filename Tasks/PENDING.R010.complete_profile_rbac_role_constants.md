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
  - `mentor_api`: `dashboard-refactor` (local commits `24da09e` RBAC, `ca8af87` OpenAPI wording)

## Change control checklist

- [ ] Reviewed all **Context / Input files**.
- [ ] Designed and documented the solution approach in this file.
- [ ] Implemented code changes (role constants + RBAC + OpenAPI wording).
- [ ] Bumped `api_utils` version and published to CodeArtifact.
- [ ] Bumped `mentor_api` `Pipfile` pin and reinstalled (no editable install).
- [ ] Added/updated **unit tests**.
- [ ] Added/updated **e2e tests**.
- [ ] Ran unit tests and e2e tests; all passing.
- [ ] Ran packaging/build steps (`pipenv run container` / `make container`); build successful.
- [ ] Created scoped commits referencing this task ID.

## Implementation notes (to be updated by the agent)

**Summary of changes**
- _Role constants added to `api_utils/config/config.py`; `ProfileService` uses `Config.MENTOR_ROLE`/`Config.ADMIN_ROLE`; OpenAPI Profile descriptions updated to "mentor or admin" with `403` responses._

**Testing results**
- Unit tests: _command(s) run, high-level outcome_
- E2E tests: _command(s) run, high-level outcome_
- Packaging/build: _command(s) run, high-level outcome_

**Follow-up tasks**
- _e.g., adopt the shared role constants in the other domain APIs (coordinator, customer, mentee) to remove their local role strings._
