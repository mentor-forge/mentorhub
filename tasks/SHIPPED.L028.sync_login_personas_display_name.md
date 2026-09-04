# L028 – Sync login personas and mint `display_name`

Status: Shipped
Type: Feature
Depends On: none
Description: F-W22 ([issue #68](https://github.com/mentor-forge/mentorhub/issues/68)) — Align the Developer Edition sign-in page with the latest Profile test data, and mint JWT claim `display_name` instead of `name`.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./tasks/_PLANNING.md (MongoDB dictionary source of truth is the **running** configurator, not files in `mentorhub_mongodb_api`)
- ./login.html (hardcoded `<option>` list duplicates `PROFILES`)
- ./welcome-auth.js (`PROFILES` static map; `signJwt` payload includes `name: profile.name`)
- ./Research/cognito.md (JWT claims `profile_id`, `customer_id`, `mentor_id`, `roles` — no `display_name` yet)
- ./Research/local_dev_mocks.md (sign-in tab mints JWT from seeded profiles)
- ./DeveloperEdition/docker-compose.yaml (`mongodb_api` on **8383**)
- https://github.com/mentor-forge/mentorhub/issues/68

**Source of truth (required before editing personas):** start the configurator if needed (`mh up` with a profile that includes `mongodb_api`, or equivalent), then:

```bash
curl -X GET "http://localhost:8383/api/configurations/json_schema/Profile.yaml/latest/" -H "accept: application/json"
```

Also load the latest **Profile test data** from the running configurator (same service, latest version). Use the JSON schema to identify the human-readable field (`display_name`) vs the document `name` (Word / login key). If the configurator is unavailable, set this task **Status** to `Blocked` and stop — do **not** read `../mentorhub_mongodb_api/configurator/test_data/`.

**Out of scope (other repos):** `api_utils` `Token.to_dict()` still copies JWT `name` into the Flask token dict; journey SPAs / `spa_utils` are not edited from this folder. Document that follow-on in L029.

**Out of scope (this repo):** F-W10 extra login tabs; `return_to` / shared-origin defaults (L023); JWT secret, `iss`, `aud`, TTL; Cognito pool attributes.

## Goals

- Rebuild `welcome-auth.js` `PROFILES` so every seeded Profile in the latest test data is selectable, with:
  - `sub` / select `value` aligned to the Profile login key (today: `mike`, `daniel`, … — confirm against test data `name` or equivalent)
  - `profile_id`, `roles`, `customer_id`, `mentor_id` taken from the same Profile documents (empty string when absent, matching current token shape)
  - `display_name` taken from the Profile `display_name` field (not the old JWT `name` claim)
  - `label` suitable for the dropdown (persona nickname + roles is fine if still accurate)
- Mint JWTs with **`display_name`** (string) and **without** a **`name`** claim. Keep `iss`, `aud`, `sub`, `iat`, `exp`, `roles`, `profile_id`, `customer_id`, `mentor_id`.
- Stop duplicating the persona list in `login.html`: empty the `<select>` (placeholder only if needed) and let `populateUserSelect()` always fill options from `PROFILES` (today it no-ops when HTML already has options).
- Add/update the comment above `PROFILES` so it points at the **configurator** as the source, not a path inside `mentorhub_mongodb_api`.
- Add, drop, or rename personas if test data changed (do not keep stale ids/roles/labels).
- Do not change hash-fragment bootstrap (`access_token`, `expires_at`, `roles`).

## Testing Expectations

- Configurator `json_schema/Profile.yaml/latest` includes `display_name` (or document the actual field name used and map it to the JWT claim `display_name`).
- Every Profile document in latest test data appears once in `PROFILES`; every `PROFILES` entry has a matching test-data `_id` / `profile_id`.
- Unit-style check (Node is fine, same approach as L023): decode a minted payload for at least two personas (e.g. admin + multi-role) and assert:
  - `display_name` is the non-empty human-readable string from test data
  - `name` is **absent**
  - `sub`, `roles`, `profile_id`, `customer_id`, `mentor_id` match `PROFILES`
- `login.html` `<select>` has no hardcoded persona `<option>`s; opening the page (or a jsdom/DOM check) shows one option per `PROFILES` key.
- Regression: `defaultReturnTo` remains `http://${hostname}:8080/discovery/`; `isAllowedReturnTo` unchanged.
- Optional live check after `make container` + welcome restart: sign in as one persona, decode `#access_token` in the redirect hash.

## Outputs

- `welcome-auth.js` — `PROFILES` + JWT payload (`display_name`); `populateUserSelect` always rebuilds options.
- `login.html` — select options no longer hardcode personas.

## Execution Notes

### Plan

1. Query the running configurator for the latest Profile JSON schema, configuration metadata, and referenced test-data document set.
2. Rebuild `PROFILES` from every latest test-data document, using `display_name` for the human-readable JWT claim and the unique email local-part as the login key because the current schema/test data do not define a document `name`.
3. Update JWT minting to emit `display_name` without `name`, and make `populateUserSelect()` rebuild the select from `PROFILES`.
4. Remove hardcoded persona options from `login.html`.
5. Run source-of-truth parity, JWT payload, DOM population, and return-target regression checks; record results here and ship the task.

### Implementation summary

- Queried the running configurator on port 8383. The latest Profile configuration is `0.1.0.0` and references `Profile.0.1.0.0.json`.
- The latest JSON schema defines `display_name` and does not define `name`. Because every latest Profile document has a unique email, the email local-part is used as the login key / `sub`.
- Synchronized `PROFILES` to all 21 current test-data documents, including the six newer personas `patha-owner`, `nora`, `helen`, `pat`, `riley`, and `quinn`.
- Replaced persona `name` properties and the JWT `name` claim with `display_name`.
- Changed `populateUserSelect()` to clear and rebuild the dropdown every time it runs, and removed all hardcoded persona options from `login.html`.
- L029 follow-on remains out of scope: shared API token-dict behavior and downstream SPA consumers are not changed here.

### Test results

- Required schema request passed:
  `curl -X GET "http://localhost:8383/api/configurations/json_schema/Profile.yaml/latest/" -H "accept: application/json"`
- Live configuration and test-data requests passed:
  `GET /api/configurations/Profile.yaml/` and
  `GET /api/test_data/Profile.0.1.0.0.json/`.
- `node --check welcome-auth.js`: passed.
- Node unit-style source-of-truth check: passed.
  - Verified `display_name` exists in the schema and `name` does not.
  - Verified all 21 live Profile documents appear exactly once in `PROFILES`, with matching login key, `profile_id`, roles, customer, mentor, and display name.
  - Minted and decoded JWTs for `mike` (admin) and `mary` (multi-role); both contain non-empty `display_name`, omit `name`, and match all `PROFILES` identity claims.
  - Verified `login.html` has no hardcoded persona options and the populated DOM has one option per `PROFILES` key.
  - Verified `defaultReturnTo` remains `http://${hostname}:8080/discovery/` and `isAllowedReturnTo` is byte-for-byte unchanged from `HEAD`.
- IDE diagnostics for `welcome-auth.js` and `login.html`: no errors.
- Optional live browser/container sign-in was not run; all required Testing Expectations passed.
