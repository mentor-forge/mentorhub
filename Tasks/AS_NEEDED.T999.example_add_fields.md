# T999 – Example: Add OpenAPI field to SPA page

**Status**: Run as needed  
**Type**: Feature  
**Depends On**: none  
**Description**: Parameterized template for surfacing a new API field on an SPA page after the backing API OpenAPI specification has been updated. Edit the parameter values under **Context** before promoting this task to `Pending`.

## Context

Always read these files before implementation:

- `../DeveloperEdition/standards/spa_standards.md`
- `./README_SPA.md`

**Parameters (edit before running)**

- **SPA repository** (working directory for all commands and Outputs paths): `../../mentorhub_mentor_spa`
- **SPA README**: `../../mentorhub_mentor_spa/README.md`
- **OpenAPI spec**: `../../mentorhub_mentor_api/docs/openapi.yaml`
- **OpenAPI schema**: `Profile`
- **New field**: `full_name` (`string`, optional) — display name distinct from IdP `name`
- **Target page**: `src/pages/ProfileViewPage.vue` — read-only profile detail view
- **Display label**: `Full Name`
- **Automation ID**: `profile-view-full-name-display`
- **Predecessor task**: `../../mentorhub_mentor_api/tasks/PENDING.L100.UpdateOpenapi.md` — OpenAPI must include the field before this task runs

**Additional input files** (paths relative to SPA repository root unless noted):

- OpenAPI spec and schema named above
- Target page named above
- `src/api/types.ts`
- `src/api/client.ts`
- `src/api/Profile.client.test.ts` (or domain-specific client test)
- `cypress/e2e/profile.cy.ts` (or domain-specific E2E spec)

## Goals

- The **Profile** TypeScript interface in `src/api/types.ts` includes `full_name` with type and optionality matching OpenAPI.
- The **View Profile** page displays **Full Name** when the API returns a value, and `N/A` when absent.
- The display element uses `data-automation-id="profile-view-full-name-display"` per spa_standards.
- Unit tests pass with mock profiles that include `full_name`.
- E2E tests assert the field is visible on the profile detail page when the API returns a value.

## Testing Expectations

Run all commands from the **SPA repository root** named in Context.

- **Unit tests**
  - `npm run test`

- **Dev verification**
  - `npm run api` — start db + backing API containers
  - `npm run dev` — start Vite dev server
  - Confirm the target page shows the new field for a profile with test data

- **E2E tests** (dev runtime)
  - `npm run cypress:run` — headless end-to-end tests

- **Packaging verification**
  - `npm run container` — build SPA container image
  - `npm run service` — run app and backing services in containers
  - `npm run cypress:run` — E2E tests against packaged runtime

## Outputs

Paths are relative to the **SPA repository root**.

- `src/api/types.ts` — add `full_name?: string` to the `Profile` interface
- `src/pages/ProfileViewPage.vue` — read-only **Full Name** display with `data-automation-id="profile-view-full-name-display"`
- `src/api/Profile.client.test.ts` — include `full_name` in mock profile responses
- `cypress/e2e/profile.cy.ts` — assert `profile-view-full-name-display` is visible on profile detail page

The agent must not update files outside this list.

## Execution Notes

_Reserved for the task execution agent._
