# S40 – Bind Developer Edition compose ports to 0.0.0.0

Status: Pending
Type: Feature
Depends On: none
Description: Expose all Developer Edition services on every network interface (`0.0.0.0`) so a developer's local stack is reachable by teammates over the Tailscale VPN (issue F-W08 #40).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./DeveloperEdition/docker-compose.yaml

## Goals

- Every published port in `DeveloperEdition/docker-compose.yaml` binds to `0.0.0.0` instead of `127.0.0.1`. This includes:
  - `welcome` `8080:80`
  - `mongodb` `27017:27017`
  - `mongodb_api` `8383:8383`
  - `mongodb_spa` `8384:8384`
  - `customer_api` `8387:8387`, `customer_spa` `8388:80`
  - `coordinator_api` `8389:8389`, `coordinator_spa` `8390:80`
  - `mentor_api` `8391:8391`, `mentor_spa` `8392:80`
  - `mentee_api` `8393:8393`, `mentee_spa` `8394:80`
- MongoDB (`27017`) is deliberately bound to `0.0.0.0` as well (per issue decision — full remote DB access over the tailnet).
- No changes to `profiles`, `environment`, `depends_on`, `healthcheck`, or `extra_hosts`.
- A short security note is added (compose comment and/or CONTRIBUTING via S43) that MongoDB runs with `--bind_ip_all` and **no authentication**, so tailnet ACLs are the only access control — this is acceptable for Developer Edition only.

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` parses without error and shows `0.0.0.0` host bindings for all services.
- Markdown lint on any docs touched by this task (none expected beyond the compose comment).

## Outputs

- `DeveloperEdition/docker-compose.yaml` — change all 12 `127.0.0.1:` port bindings to `0.0.0.0:`.

## Execution Notes

**Summary of changes**
- Changed all published port bindings in `DeveloperEdition/docker-compose.yaml` from `127.0.0.1:` to `0.0.0.0:`. This branch's compose (from `origin/main`) had **13** active bindings — the 12 listed services plus a now-active `mock_stripe_api` (`12111`) that wasn't present in the stale local `main`. All 13 were updated.
- Left the `extra_hosts` mapping (`mongodb:127.0.0.1`) and the three `IDP_LOGIN_URI` fallbacks (`http://127.0.0.1:8080/login.html`) unchanged — S41 drives the login URI via `mh`.
- Added a Developer-Edition security note above the `mongodb` service documenting the 0.0.0.0 exposure, MongoDB's `--bind_ip_all` + no-auth posture, and tailnet-ACL reliance.

**Verification results**
- `docker compose -f DeveloperEdition/docker-compose.yaml --profile all config` → `rc=0`, parses cleanly; every service renders `host_ip: 0.0.0.0`; `extra_hosts` shows `mongodb=127.0.0.1`; `IDP_LOGIN_URI` defaults to `http://127.0.0.1:8080/login.html` (as expected without `mh`).

**Follow-up tasks**
- None. S41 handles the `IDP_LOGIN_URI` / magic-host wiring.
