# L017 – Document port map and register Admin + Discovery repos in platform docs

Status: Shipped
Type: Feature
Depends On: L016.wire_welcome_portal_and_login
Description: F-W18 — Finalize platform registration for the four new repos: confirm `architecture.yaml` port map for **F-US09** cross-repo linking, update `Makefile clone-all`, branch protection standards, and umbrella docs so developers can discover and clone Admin + Discovery domains.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (Register in mh / workspace docs)
- ./Workshops/discovery_journey_issues.md
- ./Specifications/architecture.yaml (admin + discovery domains — S48)
- ./Specifications/journeys.yaml
- ./Makefile
- ./DeveloperEdition/standards/branch_protection_standards.md
- ./tasks/SHIPPED.S48.refactor_architecture_remove_coordinator.md
- ./tasks/SHIPPED.S51.platform_refs_remove_coordinator.md

## Goals

- **`Specifications/architecture.yaml`:**
  - Confirm `admin` and `discovery` journey domains list correct repo names and ports (**8389/8390/8397/8398**) — adjust only if S48 drift found.
  - Add **F-US09 cross-repo SPA base URL map** (or equivalent structured block) documenting local Developer Edition URLs per SPA for spa_utils universal nav consumption, e.g.:
    - `customer_spa`: `http://<host>:8388/`
    - `admin_spa`: `http://<host>:8390/`
    - `discovery_spa`: `http://<host>:8398/` (**default post-login**)
    - `mentor_spa`, `mentee_spa`, schema configurator — include existing ports for completeness.
  - Document that `<host>` resolves via `~/.mentorhub/HOST_NAME` or `127.0.0.1` (link to CONTRIBUTING VPN section).
- **`Makefile` `clone-all`:** Add four repos to clone list:
  - `mentorhub_admin_api`, `mentorhub_admin_spa`, `mentorhub_discovery_api`, `mentorhub_discovery_spa`.
- **`DeveloperEdition/standards/branch_protection_standards.md`:** Add four repos to the protected-repo table (if present) matching customer/mentee rows.
- **`README.md`:** Confirm Quick Start / port-range text lists Admin + Discovery ports (8389–8390, 8397–8398) and mentions default post-login Discovery SPA if not already complete after S51.
- **`CONTRIBUTING.md`:** Only if a short cross-reference to F-W18 bootstrap or clone-all list is missing — avoid duplicating S43 hostname guidance.
- **`Workshops/README.md`:** Add links to `admin_journey_issues.md` and `discovery_journey_issues.md` if not already indexed.
- Do **not** implement F-US09 spa_utils code — documentation/registry only.

## Testing Expectations

- `yq '.' Specifications/architecture.yaml` succeeds; port values unique across all repos.
- Grep `Makefile` clone-all — four new repo names present.
- Grep `architecture.yaml` — cross-repo / SPA URL section documents discovery_spa **8398** as default landing.
- `make clone-all` dry review — new repos in loop (skip-if-exists behavior unchanged).
- Markdown/YAML lint on touched files if tooling available.

## Outputs

- `Specifications/architecture.yaml` — F-US09 cross-repo SPA URL map (and any S48 correction).
- `Makefile` — `clone-all` target repo list.
- `DeveloperEdition/standards/branch_protection_standards.md` — four new repos (if table exists).
- `README.md` — port map / clone references (minimal delta).
- `Workshops/README.md` — journey doc index (if missing links).

## Execution Notes

- Added `cross_repo_spa_urls` block to `Specifications/architecture.yaml` with F-US09 Developer Edition SPA base URLs; `default_post_login: discovery_spa`.
- `Makefile clone-all` — four new repos added.
- `branch_protection_standards.md` — admin/discovery API and SPA rows added.
- `README.md` — default post-login Discovery SPA note.
- `Workshops/README.md` — admin and discovery journey doc links.
- `yq '.' Specifications/architecture.yaml` — pass; ports unique.