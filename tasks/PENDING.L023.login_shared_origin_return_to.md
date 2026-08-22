# L023 – Default login return_to to shared-origin Discovery

Status: Pending
Type: Feature
Depends On: L022.welcome_nginx_journey_proxy
Description: Point mock IdP default post-login landing at **`http://<host>:8080/discovery/`** on the welcome origin so one JWT in `localStorage` is visible to every journey SPA behind that origin. Keep explicit `return_to` for deep links and Cypress.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./login.html
- ./welcome-auth.js (`defaultReturnTo` is currently `http://${hostname}:8398/`; `isAllowedReturnTo` allows `127.0.0.1`, `localhost`, `*.ts.net`)
- ./tasks/SHIPPED.L016.wire_welcome_portal_and_login.md (Discovery default landing — update the **URL shape**, not the product decision)
- ./DeveloperEdition/mh (`IDP_LOGIN_URI=http://<HOST_NAME>:8080/login.html`)
- ./DeveloperEdition/standards/spa_standards.md

## Goals

- When `login.html` is opened **without** `return_to`, default to **`http://${hostname}:8080/discovery/`** (same host as the login page, port **8080**, path **`/discovery/`**).
- Preserve explicit `return_to` (including direct-port Cypress URLs such as `http://127.0.0.1:8388/`).
- Keep the loopback + `*.ts.net` allowlist. Same-origin `http://<host>:8080/discovery/` must already pass (host is `127.0.0.1`, `localhost`, or MagicDNS).
- Hash-fragment token bootstrap remains as a **fallback**; same-origin `localStorage` is the primary win once SPA prefix work lands. Do not remove hash bootstrap in this task.
- Do **not** implement F-W10 register/invite/update tabs.
- Do **not** change JWT claims (`iss: dev-idp`, `aud: dev-api`, HS256).
- Compose `IDP_LOGIN_URI` default stays `http://127.0.0.1:8080/login.html` (already same origin as the new default `return_to`).

## Testing Expectations

- Static review: `welcome-auth.js` default is `:8080/discovery/`, not `:8398/`.
- Open `login.html` with no query → hidden `return_to` is `http://<host>:8080/discovery/`; submit enabled.
- Open `login.html?return_to=http://127.0.0.1:8388/` → still that Customer direct-port URL.
- Invalid host still blocked by `isAllowedReturnTo`.
- Optional: after login with default `return_to`, Location/redirect targets `/discovery/` on port 8080.

## Outputs

- `welcome-auth.js` — default `return_to`.
- `login.html` — only if copy/help text still mentions `:8398`.

## Execution Notes
