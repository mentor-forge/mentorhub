# S45 – Manual approval: container IdP redirect over MagicDNS

Status: Blocked
Type: Feature
Depends On: S44
Description: Human checkpoint — confirm journey SPA containers redirect unauthenticated users to the mock IdP at `http://<HOST_NAME>:8080/login.html` (not `127.0.0.1`) after mentee_spa L123 integration testing. Unblock spa_utils F030 (0.5.7 release) only after Mike approves.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/mh
- `./tasks/PENDING.S44.compose_idp_login_uri_journey_spas.md`

**External prerequisites (human confirms before unblocking):**

- `mentorhub_spa_utils` task **F029** shipped on branch **`0.5.8-IDP-Login`**.
- `mentorhub_mentee_spa` tasks **L122** and **L123** shipped on the F-W08 branch (mentee_spa temporarily depends on local `../mentorhub_spa_utils`).

## Goals

- Mike manually repeats the integration test from L123:
  1. `cd ~/source/mentor-forge/mentorhub_mentee_spa && mh down && npm run container`
  2. `cd ~/source/mentor-forge/mentorhub && make update && mh up mentee`
  3. Open `http://<HOST_NAME>:8080`, follow the mentee SPA link, and confirm unauthenticated redirect lands on `http://<HOST_NAME>:8080/login.html` (browser address bar shows MagicDNS host, not `127.0.0.1`).
  4. Log out (if needed) and confirm logout redirect uses the same host.
- Record approval (date + tester) in **Execution Notes** and rename this file to `SHIPPED.S45...` or delete after F030 starts.

## Testing Expectations

- Manual browser verification only — no code changes in this task.
- If redirect still shows `127.0.0.1`, keep **Blocked** and file follow-up defects; do not proceed to F030.

## Outputs

- This task file — **Execution Notes** only (approval record).

## Execution Notes

Reserved for Mike's manual test results and approval timestamp.

