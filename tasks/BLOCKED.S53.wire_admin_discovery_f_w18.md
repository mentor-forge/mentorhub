# S53 – Wire Admin + Discovery into Developer Edition (F-W18)

Status: Blocked
Type: Feature
Depends On: S48, S49, S50, S51
Description: F-W09 follow-on blocked on **F-W18** — Register Admin and Discovery repos in compose, welcome portal, clone-all, and workspace once `mentorhub_admin_*` and `mentorhub_discovery_*` exist on GitHub with GHCR images.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./Workshops/admin_journey_issues.md (F-W18 issue text, copy sources, port wiring)
- ./Workshops/discovery_journey_issues.md
- ./Workshops/customer_journey_issues_adjustments.md (post-login → Discovery SPA)
- ./Specifications/architecture.yaml (ports from S48)
- ./DeveloperEdition/docker-compose.yaml
- ./index.html
- ./login.html
- ./Makefile
- [F-W18 mentorhub#52](https://github.com/mentor-forge/mentorhub/issues/52)

## External prerequisites (unblock criteria)

- F-W18 complete: four repos exist (`mentorhub_admin_api`, `mentorhub_admin_spa`, `mentorhub_discovery_api`, `mentorhub_discovery_spa`) with published `:latest` GHCR images.
- Port map matches S48 `architecture.yaml`: admin 8389/8390, discovery 8397/8398.

## Goals

- Add `admin_api`, `admin_spa`, `discovery_api`, `discovery_spa` services to `DeveloperEdition/docker-compose.yaml` with profiles (`admin`, `admin-api`, `discovery`, `discovery-api`, `all`) and env stubs per F-W18 (JWT, Mongo, `IDP_LOGIN_URI` on SPAs).
- Add Admin + Discovery links to `index.html` (SPA, API explorer, GitHub) using architecture ports.
- Add the four repos to `Makefile` `clone-all`.
- Update `README.md` port list and any workspace file (`mentorhub.code-workspace`) with new folder entries.
- Update `login.html` default post-auth navigation target to **Discovery SPA** base URL (per `customer_journey_issues_adjustments.md` — not Customer SPA).
- Document port map for F-US09 cross-repo linking (comment in compose or CONTRIBUTING one-liner).

## Testing Expectations

- `docker compose -f DeveloperEdition/docker-compose.yaml config` — includes admin + discovery services; parses cleanly.
- `mh up discovery` (or `all`) pulls and starts discovery stack when images exist.
- Welcome page links resolve to correct ports.
- `make update` succeeds.

## Outputs

- `DeveloperEdition/docker-compose.yaml`
- `index.html`
- `login.html` (default return_to / success navigation → Discovery)
- `Makefile`
- `README.md`
- `mentorhub.code-workspace` — only if created or already present as part of F-W18

## Execution Notes

**Blocked reason:** F-W18 repos and GHCR images not yet available. Promote to `PENDING` when F-W18 ships.
