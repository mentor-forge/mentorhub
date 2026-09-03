# L029 – Document JWT `display_name` and api_utils follow-on

Status: Shipped
Type: Feature
Depends On: L028.sync_login_personas_display_name
Description: F-W22 ([issue #68](https://github.com/mentor-forge/mentorhub/issues/68)) — Record that Developer Edition (and intended IdP) tokens use claim `display_name` instead of `name`, and leave a paste-ready ISSUE for `mentorhub_api_utils` `Token.to_dict()`.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./tasks/_ORCHESTRATE.md (do **not** edit sibling repos from this folder)
- ./tasks/SHIPPED.L027.issue_spa_base_path.md (ISSUE-file pattern for cross-repo follow-on)
- ./welcome-auth.js (after L028: JWT payload includes `display_name`, not `name`)
- ./Research/cognito.md (JWT claim table: `profile_id`, `customer_id`, `mentor_id`, `roles`)
- ./Research/local_dev_mocks.md (welcome page mints JWT from stored claims)
- ./DeveloperEdition/standards/api_standards.md (Authentication / Claims)
- ./DeveloperEdition/standards/sre_standards.md (Token Requirements: `iss`, `aud`, `sub`, `exp`)
- ./DeveloperEdition/standards/security_standards.md
- https://github.com/mentor-forge/mentorhub/issues/68

**Known sibling gap (do not fix here):** `mentorhub_api_utils` `Token.to_dict()` currently sets `"name": self.claims.get('name', '')`. After L028, that key will be empty unless api_utils reads `display_name`.

## Goals

- Update living docs in **this** repo so JWT identity display is **`display_name`**, not OIDC/JWT `name`:
  - `Research/cognito.md` — add `display_name` to the claim table (required or always-present string from Profile `display_name`; Pre Token Generation should copy it like other MentorHub claims). Do not add a Cognito `custom:name` mapping for the old claim.
  - `Research/local_dev_mocks.md` — sign-in / JWT minting notes say `display_name` (and the other existing claims), not `name`.
  - `DeveloperEdition/standards/api_standards.md` — Authentication bullets mention `display_name` on Developer Edition tokens alongside existing `iss`/`aud`/`sub`/`exp`/`roles`/`profile_id`.
  - `DeveloperEdition/standards/sre_standards.md` — Token Requirements list includes `display_name` if that list is meant to be exhaustive of MentorHub custom claims; otherwise add a short sentence that display identity is `display_name`.
- Create `tasks/ISSUE.mentorhub_api_utils.display_name_token_dict.md`: a paste-ready `_PLANNING` prompt for **`mentorhub_api_utils`** only:
  - `Token.to_dict()` / `create_flask_token()` expose `display_name` from the JWT (stop depending on claim `name` for the human-readable label).
  - Update unit tests that assert `token_dict["name"]` / `claims.get('name')`.
  - Profile document lookup by `name` + `token.user_id` (`sub`) is **unchanged** unless the live Profile schema says otherwise.
  - Do not implement that work in `mentorhub`.
- Add a short **Downstream follow-on** row to `tasks/_PLANNING.md` pointing at that ISSUE file (same pattern as the SPA nginx table).
- Do not change `login.html` / `welcome-auth.js` in this task (L028).
- Do not invent spa_utils work unless a doc already claims SPAs read JWT `name` (they currently do not for chrome).

## Testing Expectations

- Markdown review: no remaining guidance that Developer Edition login JWTs mint or require claim `name` for display (search `welcome-auth`, `login.html`, `cognito.md`, `local_dev_mocks.md`, `api_standards.md`, `sre_standards.md`).
- `Research/cognito.md` claim table includes `display_name`.
- ISSUE file is complete enough to paste into `mentorhub_api_utils/tasks` planning (GitHub issue URL may be TBD; include F-W22 / mentorhub #68 as the driver).
- Lint markdown if tooling is available.

## Outputs

- `Research/cognito.md`
- `Research/local_dev_mocks.md`
- `DeveloperEdition/standards/api_standards.md`
- `DeveloperEdition/standards/sre_standards.md` (only if Token Requirements / auth prose needs the claim)
- `DeveloperEdition/standards/security_standards.md` (only if it lists token claims by name)
- `tasks/ISSUE.mentorhub_api_utils.display_name_token_dict.md` (new)
- `tasks/_PLANNING.md` (downstream table row only)

## Execution Notes

**Plan:**

1. Update the Cognito, local-development, API, and SRE documentation so
   `display_name` is the explicit human-readable JWT identity claim alongside
   the existing standard and MentorHub claims.
2. Create a paste-ready `mentorhub_api_utils` planning artifact that scopes the
   `Token.to_dict()` / `create_flask_token()` follow-on without changing Profile
   lookup semantics.
3. Add the downstream artifact to `_PLANNING.md`, then run the required claim
   searches and available Markdown linting before recording results and shipping
   this task file.

**Implemented (2026-09-03):**

- Added `display_name` to the Cognito claim contract and custom-attribute /
  Pre Token Generation guidance, with Profile `display_name` as its source.
- Documented the complete Developer Edition token shape in local mock and API
  standards, and clarified in SRE standards that the display claim is
  `display_name`, not `name`.
- Added a paste-ready `mentorhub_api_utils` ISSUE covering `Token.to_dict()`,
  `create_flask_token()`, affected tests, documentation, and unchanged Profile
  lookup semantics; indexed it in `_PLANNING.md`.
- Left `login.html`, `welcome-auth.js`, sibling repositories, and
  `security_standards.md` unchanged.

**Testing (2026-09-03):**

- Searched `welcome-auth.js`, `login.html`, `Research/cognito.md`,
  `Research/local_dev_mocks.md`, `api_standards.md`, and `sre_standards.md` for
  `name` / `display_name`. The remaining `name` matches are HTML/Web Crypto
  attributes, Profile/form fields, or explicit statements that JWT display
  identity does not use `name`; no guidance mints or requires JWT `name`.
- Verified `Research/cognito.md` contains the required `display_name` claim row
  and contains no `custom:name` mapping.
- Verified the ISSUE contains F-W22 / mentorhub #68, `Token.to_dict()`,
  `create_flask_token()`, unit-test updates, and unchanged Profile lookup
  requirements; verified `_PLANNING.md` links the artifact.
- `git diff --check` passed.
- No repository Markdown lint command or installed `markdownlint` executable
  was available. IDE diagnostics reported no errors in the changed Markdown
  files.
