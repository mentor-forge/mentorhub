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

_(reserved for the execution agent: plan, commands run, test results, follow-ups)_
