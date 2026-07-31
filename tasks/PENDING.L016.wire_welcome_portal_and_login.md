# L016 – Wire welcome portal and login.html for Admin + Discovery

Status: Pending
Type: Feature
Depends On: L015.wire_developer_edition_compose
Description: F-W18 — Add Admin and Discovery links to the developer portal (`index.html`), wire `login.html` / `welcome-auth.js` so default post-login navigation targets **Discovery SPA** (`8398`), and preserve per-SPA `return_to` deep links.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/admin_journey_issues.md (welcome portal + login.html)
- ./Workshops/customer_journey_issues_adjustments.md (post-login landing → Discovery SPA F-DS01)
- ./Workshops/discovery_journey_issues.md (default post-login landing)
- ./Research/local_dev_mocks.md (F-W10 login.html tabs — out of scope here except URL wiring)
- ./Specifications/architecture.yaml
- ./index.html
- ./login.html
- ./welcome-auth.js
- ./tasks/SHIPPED.S50.welcome_portal_remove_coordinator.md (portal link pattern)

## Goals

- **`index.html` developer portal:**
  - Add SPA links: Admin SPA (**8390**), Discovery SPA (**8398**).
  - Add API explorer links: Admin API (`8389/docs/...`), Discovery API (`8397/docs/...`).
  - Add GitHub source links: `mentorhub_admin_api`, `mentorhub_admin_spa`, `mentorhub_discovery_api`, `mentorhub_discovery_spa`.
  - Extend hostname JavaScript block to set hrefs for new link IDs (same `hostname` pattern as existing journey links).
  - Optionally reorder SPA column so **Discovery SPA** appears prominently as default landing (before or after Customer — document choice in Execution Notes).
- **`login.html` / `welcome-auth.js`:**
  - When opened **without** `return_to` query param, default hidden `return_to` to Discovery SPA base URL: `http://${hostname}:8398/` (respect MagicDNS / `127.0.0.1` hostname detection used elsewhere).
  - Preserve existing `return_to` validation (loopback + `*.ts.net` allowlist).
  - Portal “Sign in” links from each SPA should continue passing explicit `return_to` (update portal if any SPA login links are added later in F-W10).
- Align with F-W10 direction: Discovery SPA is platform home after IdP login, not Customer SPA (**8388**).
- Do **not** implement register/join/update tabs (F-W10 scope).

## Testing Expectations

- Static review of `index.html` — new link IDs have matching `getElementById(...).href =` assignments; no broken JS references.
- Open `login.html` without query string — form submits to Discovery SPA (`8398`) with valid JWT hash bootstrap.
- Open `login.html?return_to=http://127.0.0.1:8388/` — still lands on Customer SPA (explicit override).
- `rg coordinator index.html` — still no coordinator links (S50 regression).
- Rebuild welcome container optional smoke: `make container`.
- HTML/markdown lint if tooling available.

## Outputs

- `index.html` — Admin + Discovery SPA/API/GitHub links and JS port wiring.
- `login.html` — only if markup changes needed for default landing copy/UX.
- `welcome-auth.js` — default `return_to` → Discovery SPA base URL when param absent.

## Execution Notes
