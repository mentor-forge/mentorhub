# L022 – Welcome nginx path proxy for journey SPAs

Status: Shipped
Type: Feature
Depends On: L021.add_mailhog_compose
Description: Make the existing welcome nginx on **:8080** the local twin of cloud ALB path routing — `/{journey}/*` reverse-proxies to each journey SPA container — without a second proxy port and without putting routing inside Discovery SPA.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./nginx.conf (today: static `try_files` only)
- ./Dockerfile (copies `nginx.conf` into `nginx:stable-alpine`)
- ./DeveloperEdition/docker-compose.yaml (`welcome` image `ghcr.io/mentor-forge/mentorhub:latest`, host **8080:80**)
- ./Makefile (`make container`, `make update`)
- ./Specifications/architecture.yaml (journey ports; keep published)
- mentorhub_cloudformation/ARCHITECTURE.md (path prefixes `/{journey}/*`; SPA nginx still proxies `/api/*` to the paired API)
- ./tasks/PENDING.L027.issue_spa_base_path.md (SPA Vue `base` / nginx prefix — welcome must **not** strip prefixes)
- ./tasks/ISSUE.mentorhub_discovery_spa.vue_base_and_nginx_prefix.md (and sibling ISSUE files)

## Goals

- Extend `nginx.conf` with Docker DNS **`resolver 127.0.0.11 valid=10s`** and variable `proxy_pass` (so SPA containers can appear after nginx starts).
- Add prefix locations that **forward the full URI** (no `rewrite` that strips `/{journey}`):

  | Prefix | Upstream (compose service name :80) |
  | --- | --- |
  | `/discovery/` | `discovery_spa` |
  | `/customer/` | `customer_spa` |
  | `/admin/` | `admin_spa` |
  | `/mentor/` | `mentor_spa` |
  | `/mentee/` | `mentee_spa` |

- Proxy headers: `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Forwarded-Prefix` (the journey prefix). WebSocket upgrade headers as used by SPA nginx.
- **Do not** add a catch-all `/api/` on welcome. After SPA prefix work, API calls are `/{journey}/api/*` and the **SPA** nginx continues to proxy `/api/` (or `/{journey}/api/`) to its paired API. Welcome only forwards the journey tree.
- Keep **`/`** as the static developer portal (`index.html`) and **`/login.html`** / **`welcome-auth.js`** as local files. Prefix locations must be more specific than `location /`.
- Do **not** proxy Stripe, Cognito, MailHog, or Admin webhook paths on this tree (F-AA01 stays a separate URL).
- Do **not** add a second proxy publish port; welcome stays **8080**.
- Keep existing **host** port bindings on journey API/SPA services (8387–8398) for OpenAPI, Cypress, and debugging.
- Compose: `welcome` stays on the default compose network so it can resolve SPA service names. Do **not** `depends_on` every SPA (that would break `mh up mentee`). Missing upstream → 502 is acceptable when that profile is not running.
- Local iteration: bind-mount `nginx.conf` into welcome **or** document `make container` + retag. If bind-mounting, `make update` must copy `nginx.conf` next to the installed compose file (`~/.mentorhub/`) so the relative volume works after install — same pattern as L018 `cognito-local/`.
- Rebuild the welcome image (`make container`) so `ghcr.io/mentor-forge/mentorhub:latest` used by compose includes the new nginx (publish is optional unless this branch ships the image).

## Testing Expectations

- `nginx -t` equivalent: `docker compose -f DeveloperEdition/docker-compose.yaml config` parses; welcome still publishes **8080**.
- Grep `nginx.conf`: `resolver 127.0.0.11`; five `location /{journey}/` blocks; **no** rewrite that strips the prefix; **no** welcome-level `/api/` proxy.
- `curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/` → **200** (portal).
- `curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/login.html` → **200**.
- With `mh up all` (or profile that includes `discovery_spa`): request `http://127.0.0.1:8080/discovery/` reaches `discovery_spa` (200, 301, or SPA index — **not** welcome `index.html`). Until SPA prefix ISSUEs ship, **404 from the SPA nginx** is acceptable; **welcome 404** is not.
- Direct ports still published: `discovery_spa` **8398**, `customer_spa` **8388**, etc.
- `make update` succeeds if nginx is bind-mounted from `~/.mentorhub/`.

## Outputs

- `nginx.conf` — resolver + journey `proxy_pass` locations; static `/` and `/login.html` unchanged in purpose.
- `Dockerfile` — only if copy/paths change.
- `DeveloperEdition/docker-compose.yaml` — welcome volume for nginx bind-mount if used; no new proxy port.
- `Makefile` — copy `nginx.conf` on `make update` if bind-mounting from `~/.mentorhub/`.

## Execution Notes

### Plan

1. Add Docker DNS resolution and five exact journey-prefix proxy locations to the welcome nginx configuration, using variable `proxy_pass` values so unavailable SPA services do not prevent nginx startup.
2. Bind-mount the configuration beside the Developer Edition compose file and copy it into `~/.mentorhub/` during `make update`, without changing welcome dependencies or published ports.
3. Rebuild the welcome image, validate compose and nginx configuration, exercise portal/login/journey routes, confirm direct SPA ports, and record all results and blockers here.

### Implementation

- Added `resolver 127.0.0.11 valid=10s ipv6=off` and `/discovery/`, `/customer/`, `/admin/`, `/mentor/`, and `/mentee/` locations. Each location sets its service URL in `$upstream` and uses `proxy_pass $upstream;`, preserving the complete request URI.
- Added the required forwarding and WebSocket headers, with a journey-specific `X-Forwarded-Prefix`.
- Bind-mounted `./nginx.conf` read-only into the welcome service. `DeveloperEdition/nginx.conf` is a symlink to the repository configuration, while `make update` copies the repository configuration to `~/.mentorhub/nginx.conf`.
- Kept welcome on port 8080, retained all direct SPA port publications, and added no dependencies or welcome-level API/webhook proxies.

### Test Results

- `docker compose -f DeveloperEdition/docker-compose.yaml --profile all config`: passed; welcome publishes `0.0.0.0:8080:80`, uses the read-only nginx bind mount, and has no SPA `depends_on`.
- Installed compose (`~/.mentorhub/docker-compose.yaml`) config: passed and resolves the bind source to `~/.mentorhub/nginx.conf`.
- Static nginx checks: resolver and all five journey locations present; no `rewrite`, trailing-slash upstream URI, or `location /api/`.
- `make container`: passed; rebuilt `ghcr.io/mentor-forge/mentorhub:latest` with the updated nginx configuration.
- `make update`: passed; copied the compose file and nginx configuration into `~/.mentorhub`.
- `nginx -t`: passed both in a one-off image container and inside the running welcome container.
- `GET http://127.0.0.1:8080/`: 200, welcome portal body.
- `GET http://127.0.0.1:8080/login.html`: 200.
- Journey proxy checks against each directly published SPA path:
  - discovery: proxy 200, direct port 8398 returned 200, bodies matched.
  - customer: proxy 200, direct port 8388 returned 200, bodies matched.
  - admin: proxy 200, direct port 8390 returned 200, bodies matched.
  - mentor: proxy 200, direct port 8392 returned 200, bodies matched.
  - mentee: proxy 200, direct port 8394 returned 200, bodies matched.
- The discovery proxy body hash differed from the welcome portal hash and exactly matched the direct discovery SPA response, confirming the request reached `discovery_spa`.
- Direct journey SPA ports 8388, 8390, 8392, 8394, and 8398 remain published.

### Blockers

None.
