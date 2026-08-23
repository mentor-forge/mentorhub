# L025 – Refactor welcome portal for shared-origin apps and tools

Status: Shipped
Type: Feature
Depends On: L024.stage0_launch_compose
Description: Rebuild `index.html` as the Developer Edition front door: journey **Applications** go through **:8080/{journey}/**; API explorers and mocks keep direct ports; add Stage0 Launch, MailHog, Stripe mock, Cognito mock, Schema, and Runbook; remove the GitHub section.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./index.html (sections: “Single Page Applications”, “API Explorer”, “GitHub”; SPA hrefs use per-SPA host ports)
- ./welcome-auth.js (L023 default `return_to` → `:8080/discovery/`)
- ./Specifications/architecture.yaml (ports: schema 8383/8384, customer 8387/8388, admin 8389/8390, mentor 8391/8392, mentee 8393/8394, runbook 8395/8396, discovery 8397/8398)
- ./DeveloperEdition/docker-compose.yaml after L018–L021 and L024 (`mock_stripe_api` 12111, `mock_cognito` 9229, `mock_mailhog` 8025, `stage0_launch` **8081**)
- ./tasks/PENDING.L022.welcome_nginx_journey_proxy.md
- ./tasks/PENDING.L024.stage0_launch_compose.md
- ./tasks/SHIPPED.L016.wire_welcome_portal_and_login.md

## Goals

- Rename the first section **“Applications”** (not “Single Page Applications”).
- **Use the app** (same origin, welcome nginx):

  | Label | Href |
  | --- | --- |
  | Discovery (default landing) | `http://${hostname}:8080/discovery/` |
  | Customer | `http://${hostname}:8080/customer/` |
  | Admin | `http://${hostname}:8080/admin/` |
  | Mentor | `http://${hostname}:8080/mentor/` |
  | Mentee | `http://${hostname}:8080/mentee/` |

- **Tools / utilities** (direct ports — not journey prefixes; do not put mocks on the ALB-shaped tree):

  | Label | Href |
  | --- | --- |
  | Schema configurator | `http://${hostname}:8384/` |
  | Runbook | `http://${hostname}:8396/` (architecture `runbook_spa`) |
  | MailHog | `http://${hostname}:8025/` |
  | Stripe mock | `http://${hostname}:12111/` |
  | Cognito mock | `http://${hostname}:9229/` |
  | Stage0 Launch | `http://${hostname}:8081/` |

  Put tools in Applications or a sibling “Tools” block — keep the page scannable. If **runbook** services are missing from compose, add `runbook_api` / `runbook_spa` (ports **8395** / **8396**, GHCR images, profiles `all` and `runbook`) so the Runbook link has a backend. Do not invent a `/runbook/` welcome prefix in this ticket (not in the locked journey list).
- **API Explorer:** include **all** running APIs (schema **8383**, customer **8387**, admin **8389**, mentor **8391**, mentee **8393**, discovery **8397**, runbook **8395**). Keep `/docs/` explorer URLs. Direct ports only.
- **Remove** the GitHub links section entirely.
- Make the **H1 “Mentor Hub”** a link to `https://github.com/mentor-forge/mentorhub` (`target="_blank"` + `rel="noopener noreferrer"`).
- Keep `target="_blank"` on app/tool/API links.
- Hostname JS remains `window.location.hostname` so MagicDNS works.
- Do not add Admin webhook URLs.

## Testing Expectations

- No remaining `getElementById` for removed GitHub-only IDs; every new link id has a matching `href` assignment.
- `rg ':8398/' index.html` — Discovery **app** link is **:8080/discovery/**, not :8398 (API explorer may still use 8397).
- `rg github.com/mentor-forge/mentorhub_` index.html — no per-repo GitHub list; H1 may still point at the umbrella repo.
- `rg coordinator index.html` — still none (S50).
- Optional: open portal, Applications → Discovery uses port 8080.

## Outputs

- `index.html` — Applications / tools / API explorers; H1 repo link; GitHub section removed.
- `DeveloperEdition/docker-compose.yaml` — only if runbook services are added.

## Execution Notes

### Plan
1. Restructure `index.html` into **Applications** (journey SPAs via welcome nginx `:8080/{journey}/`), **Tools** (direct-port utilities/mocks), and **API Explorer** (all seven APIs on direct ports with existing `/docs/` patterns).
2. Make H1 a static link to the umbrella repo; remove the GitHub per-repo section and all related DOM/JS.
3. Add `runbook_api` / `runbook_spa` to `DeveloperEdition/docker-compose.yaml` (ports 8395/8396, profiles `all` + `runbook`) — confirmed absent today; use `mentorhub_runbook_api` GHCR image and `stage0_runbook_spa` utility image from `mentorhub_runbook_api/docker-compose.yaml`.
4. Run grep and compose config checks from Testing Expectations.

### Implementation
- **`index.html`**: Renamed first section to **Applications**; journey links use `:8080/discovery|customer|admin|mentor|mentee/`; new **Tools** section for schema (8384), runbook (8396), MailHog (8025), Stripe mock (12111), Cognito mock (9229), Stage0 Launch (8081); API Explorer adds Runbook API (8395); GitHub list removed; H1 links to `https://github.com/mentor-forge/mentorhub`; hostname JS unchanged (`window.location.hostname`).
- **`DeveloperEdition/docker-compose.yaml`**: Added `runbook_api` and `runbook_spa` after `discovery_spa`; no `/runbook/` welcome prefix.

### Runbook images chosen
| Service | Image |
| --- | --- |
| `runbook_api` | `ghcr.io/mentor-forge/mentorhub_runbook_api:latest` |
| `runbook_spa` | `ghcr.io/agile-learning-institute/stage0_runbook_spa:latest` (spa_ref utility — sourced from `mentorhub_runbook_api/docker-compose.yaml`, not a `mentorhub_runbook_spa` repo) |

### Href map (`${hostname}` = `window.location.hostname`)
| ID | Href |
| --- | --- |
| `repo-link` | `https://github.com/mentor-forge/mentorhub` (static in HTML) |
| `discovery-app-link` | `http://${hostname}:8080/discovery/` |
| `customer-app-link` | `http://${hostname}:8080/customer/` |
| `admin-app-link` | `http://${hostname}:8080/admin/` |
| `mentor-app-link` | `http://${hostname}:8080/mentor/` |
| `mentee-app-link` | `http://${hostname}:8080/mentee/` |
| `schema-spa-link` | `http://${hostname}:8384/` |
| `runbook-spa-link` | `http://${hostname}:8396/` |
| `mailhog-link` | `http://${hostname}:8025/` |
| `stripe-mock-link` | `http://${hostname}:12111/` |
| `cognito-mock-link` | `http://${hostname}:9229/` |
| `stage0-launch-link` | `http://${hostname}:8081/` |
| `schema-api-docs-link` | `http://${hostname}:8383/docs/index.html` |
| `customer-api-docs-link` | `http://${hostname}:8387/docs/explorer.html` |
| `admin-api-docs-link` | `http://${hostname}:8389/docs/explorer.html` |
| `mentor-api-docs-link` | `http://${hostname}:8391/docs/explorer.html` |
| `mentee-api-docs-link` | `http://${hostname}:8393/docs/explorer.html` |
| `discovery-api-docs-link` | `http://${hostname}:8397/docs/explorer.html` |
| `runbook-api-docs-link` | `http://${hostname}:8395/docs/explorer.html` |

### Test results
| Check | Result |
| --- | --- |
| No `getElementById` for removed GitHub-only IDs | PASS — only app/tool/API link IDs remain |
| Every `href="#"` link id has JS assignment or static href | PASS — 18 dynamic ids + `repo-link` static |
| `rg ':8398/' index.html` | PASS — no matches (Discovery app uses `:8080/discovery/`) |
| `rg 'github.com/mentor-forge/mentorhub_' index.html` | PASS — no per-repo links |
| `rg coordinator index.html` | PASS — none |
| `docker compose config` (with `GITHUB_TOKEN` + `LAUNCHPAD_HOST` for stage0) | PASS |
| `--profile runbook` lists ports 8395/8396 | PASS |
| Port collision grep 8395/8396 | PASS — unique bindings |

### Blockers
- None for this task. Welcome image must be rebuilt for live portal to serve new `index.html` (baked into image unless volume-mounted); source check confirms correct hrefs.
- Full stack `docker compose config` without env vars fails on pre-existing `stage0_launch` `${LAUNCHPAD_HOST:?}` / `${GITHUB_TOKEN:?}` — not introduced by this change.