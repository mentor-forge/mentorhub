Please create @_PLANNING.md tasks to implement this issue. Only create tasks;
do not execute tasks or edit files outside the @tasks folder.

Target repository: **`mentorhub_api_utils` only**.

**Driver:** F-W22 / [mentorhub issue #68](https://github.com/mentor-forge/mentorhub/issues/68)

# F-U: Expose JWT `display_name` from `Token.to_dict()`

## Context

MentorHub Developer Edition persona JWTs now carry the Profile human-readable
label in claim **`display_name`** and do not carry claim `name`. The intended
production IdP contract uses the same claim. `mentorhub_api_utils` must preserve
that wire contract when converting a validated token into the dictionary used
by domain APIs.

The current `Token.to_dict()` implementation depends on
`self.claims.get("name", "")` for the human-readable label. That produces an
empty value for current Developer Edition tokens.

## Goals

- Update `Token.to_dict()` so its returned dictionary exposes
  **`display_name`** from JWT claim `display_name`.
- Ensure `create_flask_token()` returns that same token dictionary contract.
- Stop depending on JWT claim `name` for the human-readable identity label; do
  not document or add a fallback that makes `name` the MentorHub wire contract.
- Update unit tests that currently assert `token_dict["name"]` or construct the
  expectation from `claims.get("name")`. Cover a token containing
  `display_name` and no `name`.
- Update api_utils documentation that still says the JWT wire claim is `name`.

## Preserve Profile lookup semantics

Profile document lookup by document field `name` plus `token.user_id` (derived
from JWT `sub`) is unchanged by this issue. Do not rename Profile query fields
or alter that lookup unless the current live Profile schema independently
requires a different change.

## Out of scope

- Changes to `mentorhub`, its `login.html`, or its `welcome-auth.js`.
- Changes to Profile documents, Profile schema, or Profile service lookup
  behavior unrelated to token-dictionary conversion.
- SPA changes.

## Acceptance

- A JWT with `display_name: "Mike Storey"` and no `name` produces a token
  dictionary with `display_name == "Mike Storey"`.
- `create_flask_token()` exposes the same `display_name` value.
- Token conversion no longer relies on `claims.get("name")`, and affected tests
  no longer assert `token_dict["name"]` as the display-label contract.
- Existing Profile lookup by `name` and `token.user_id` remains unchanged.
- Unit tests and lint pass in `mentorhub_api_utils`.
