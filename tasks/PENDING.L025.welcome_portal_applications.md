# L025 – Refactor welcome portal for shared-origin apps and tools

Status: Pending
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
