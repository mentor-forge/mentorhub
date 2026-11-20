# SRE Standards

Platform provisioning, CloudFormation tasks, platform config, and AWS architecture: **[mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)**. This document covers org-wide standards and what **application developers** need for CI, DE auth, and production alignment.

## Tech Stack

- GitHub Container Registry for container images.
- GitHub Releases for public Python wheels and GitHub Packages for scoped npm packages.
- Docker Compose for local development. Provider-specific provisioning and deployment overlays belong in the infrastructure repository.

The AWS account, identity, audit, budget, and CodeArtifact configuration are maintained through [the AWS infrastructure repo](https://github.com/mentor-forge/mentorhub_cloudformation) and its [deferred infrastructure and teardown work](https://github.com/mentor-forge/mentorhub_cloudformation/issues/12).

## Developer Experience

The `mh` CLI installs local configuration and wraps Compose for everyday development. Follow [Developer Onboarding](../../CONTRIBUTING.md#install-developer-edition) for initial setup and package authentication.

## Authentication

See the [API Standards authentication](./api_standards.md#authentication) sections for core auth implementation details, and [SPA Standards authentication](./spa_standards.md#authentication-pattern) for the UI implementations.

Developer Edition CLI and compose uses a **stable `JWT_SECRET`** so SPAs and backends agree across restarts. The umbrella **developer sign-in page** (`login.html`) mints persona JWTs client-side; journey SPAs load tokens into `localStorage` via `bootstrapAuthFromUrl()` from shared SPA utilities before boot. **`IDP_LOGIN_URI`** / **`VITE_IDP_LOGIN_URI`** default to `http://127.0.0.1:8080/login.html` so unauthenticated guards, `401` handling, and logout send users to that page—not to a per-SPA `/login` route.

Developer Edition and the intended production IdP use `display_name` as the
human-readable JWT identity claim; consumers must not require the OIDC/JWT
`name` claim for display.

**Verifying the stack after compose or image changes** (from the product checkout root, for example the repo that contains `DeveloperEdition/`):

```sh
cd mentorhub
make update
mh up all
```

## Production alignment

**API gateway and OIDC identity provider:** In production, traffic is intended to sit behind an **API gateway** (or edge proxy) with **TLS**, routing to SPA static assets and API services. **Authentication** uses a configured **OAuth2/OIDC identity provider**. Access tokens are issued by the IdP (or a BFF); applications do not use APIs as a substitute IdP. APIs validate JWTs (shared secret or JWKS) with the same claim expectations as in Developer Edition. SPAs redirect to the real IdP login/authorize entry via the configured login base URL—preserving a single auth story from the local welcome page through to production IdP.

### Developer Edition welcome nginx (local path router)

The welcome container on **:8080** path-proxies journey SPAs at `/discovery/`, `/customer/`, `/admin/`, `/mentor/`, and `/mentee/`. Configure equivalent public routes in the production deployment overlay.

- **Not proxied on :8080:** `/api/*` (APIs stay on direct ports), `/runbook/` (Runbook tools use **8395** / **8396**), and **Admin webhook ingress** — do **not** route webhook ingress through the welcome nginx (**F-AA01**); use direct Admin API port or production ingress.
- **Same-origin navigation:** Full in-app routing under `/{journey}/` requires each journey SPA's Vue **`base`** and nginx prefix configuration — tracked in `tasks/SHIPPED_ISSUE.mentorhub_*_spa.vue_base_and_nginx_prefix.md` (GitHub issues On Deck).

## Continuous Integration

- Publish images to GitHub Container Registry after a push to `main`. The [journey publish workflow example](./examples/docker-push.yml) builds both supported architectures. Choose the API or SPA job for the repository.
- API builds install the pinned public GitHub Release wheel with the existing Pipenv lock. SPA builds install the pinned GitHub Packages dependency with `npm ci`.
- Grant SPA consumer workflow repositories read access to the npm package in GitHub Packages. The publish workflow uses `contents: read` and `packages: write` for source checkout and image publishing, and passes the npm credential only to the install step as a BuildKit secret.
- Run any pull request tests in a separate `pull_request` workflow with read permissions, no image publishing, and no privileged credentials for fork builds. Use `packages: read` only where the job can read the package with its own workflow token. Keep credential-dependent checks out of fork jobs that lack access.

## Shared package releases

1. Merge the publisher change after review and passing package tests. Use one version across the source manifest, tag, and published archive or package. Inspect the built contents and verify that expected files and entry points are present.
2. Publish the API wheel as a public GitHub Release asset and the SPA package to GitHub Packages. Treat tags and published artifacts as immutable. Confirm the wheel downloads anonymously and that consumer workflow repositories can read the npm package.
3. After the release is verified, update each consumer pin and lockfile together. Verify a clean install, tests, and image build from the committed locks before merging.
4. Roll back a consumer by restoring the prior known-good pin and lockfile or redeploying its previous verified image digest. Publish a corrected package version when needed.

## Continuous Deployment

Continuous deployment promotes immutable container images.

Standards:
- Build once.
- Tag images for promotion.
- Deploy the same image through test, staging, and production.
- Do not rebuild per environment.
- The container image is the deployable artifact.
- Environment-specific configuration changes between environments; the artifact does not.

Recommended promotion model:

```text
main merge
  -> build container image
  -> push immutable image to registry
  -> deploy to test/dev
  -> tag/promote same image to staging
  -> run migration validation + automated tests
  -> tag/promote same image to production
```

Infrastructure provisioning and environment promotion are handled by the infrastructure repository for the selected provider.

## API Reverse Proxy

All SPAs are served by NGINX with reverse proxy configuration for API endpoints. This allows for secure networking configurations that do not expose the API to external access, establishing a clear separation between the front end and back end networks.

### NGINX Configuration Pattern

SPA containers use an NGINX configuration template (`nginx.conf.template`) that is processed at container startup using `envsubst`. The template supports the following environment variables:

- **`API_HOST`**: Hostname of the API server (default: `localhost`)
- **`API_PORT`**: Port of the API server (default: `8083`)
- **`IDP_LOGIN_URI`**: Full URL for login redirect after logout, on `401`, or when the SPA is not authenticated (Developer Edition default: `http://127.0.0.1:8080/login.html`; production: IdP or gateway login entry). Compose passes this env var into journey SPA containers; **`mh`** sets it from `~/.mentorhub/HOST_NAME` when present (see [CONTRIBUTING.md](../../../CONTRIBUTING.md)).

At **container startup**, journey SPAs also run `envsubst` on `runtime-config.js.template` to write `/runtime-config.js`, setting `window.__MENTORHUB_RUNTIME__.IDP_LOGIN_URI` from **`IDP_LOGIN_URI`**. NGINX serves that file with **`Cache-Control: no-store`**. The SPA loads it before the app bundle so `getIdpLoginBaseUrl()` in `@mentor-forge/mentorhub_spa_utils` reads the runtime value — **same container image** in local dev, Tailscale VPN, and cloud (where the deployment sets the identity-provider or gateway URL).

Build-time SPA env (**`VITE_IDP_LOGIN_URI`**) applies to **`npm run dev`** only (typically `http://127.0.0.1:8080/login.html`). Resolution order in spa_utils: runtime **`IDP_LOGIN_URI`** → **`VITE_IDP_LOGIN_URI`** → Developer Edition fallback. Do not rely on client-side loopback hostname rewrites.

### Reverse Proxy Routes

The NGINX configuration proxies the following routes to the API server:

- **`/api/*`**: All API endpoints are proxied to `http://${API_HOST}:${API_PORT}/api/`

Proxy only **`/api/*`** (and static assets) through this SPA NGINX layer; do not expose ad-hoc authentication helper routes on the API reverse proxy.

### Authentication Redirect Pattern

Protected routes and the API client redirect the browser to the configured **login base URL** (`getIdpLoginBaseUrl()` from `@mentor-forge/mentorhub_spa_utils`) when the user is unauthenticated or tokens are cleared:

- **Developer Edition:** Points at the umbrella developer sign-in page (`login.html`) so developers pick a persona and land in the SPA with hash bootstrap.
- **Production:** Points at the commercial IdP (or gateway-hosted login) with TLS.

This keeps one redirect contract from local through production without per-SPA `/login` pages.

## Service Configurability

All APIs are configured using a shared [Config singleton](https://github.com/mentor-forge/mentorhub_api_utils/blob/main/py_utils/config/config.py). The Config object manages all configuration items for all API and SPA code. Configuration values are read from the first of: Config File, Environment Variable, Default Value. The configuration items and non-secret values are exposed through the Config API endpoint, which is used by the SPA to get runtime configuration values.

## Service Observability

All APIs expose a `/metrics` endpoint which exposes a text-based exposition format that Prometheus understands. This endpoint exposes detailed, real-time metrics about the API's performance, latency, error rates, and internal health.

## API Security Standards

### Production Requirements

Before deploying any API to production, ensure:

- [ ] `JWT_SECRET` is set to a strong, randomly generated value (not default)
- [ ] MongoDB connection uses authentication and encryption
- [ ] HTTPS/TLS is configured via reverse proxy
- [ ] Monitoring and logging are enabled
- [ ] All dependencies are up to date
- [ ] Audit logging and cost alerts are enabled in the hosting environment
- [ ] Human access uses centrally managed identity
- [ ] Automation uses short-lived workload credentials

### JWT Security

- **Signature Verification**: api_utils validates JWT signatures when `JWT_SECRET` is configured
- **Fail-Fast Validation**: Applications will not start with default `JWT_SECRET` value
- **Token Requirements**: All tokens must include `iss`, `aud`, `sub`, `exp` claims
- **Display Identity**: MentorHub tokens carry the human-readable label in `display_name`, not `name`
- **Secret Rotation**: Plan for regular secret rotation in production environments

### Development vs Production

| Feature | Developer Edition | Production |
|---------|-------------------|------------|
| Credential-issuing HTTP routes on APIs | Not registered | Not registered |
| `JWT_SECRET` | Stable value in compose (aligns CLI/local JWT tooling) | Strong random / secrets manager |
| Token issuance | Welcome page / local personas; URL hash bootstrap into SPAs | Commercial IdP |
| Token validation | Full signature verification | Full signature verification |
| SPAs | redirect to index base URL | redirect to IdP URL |
| Logging | INFO or DEBUG | WARNING or ERROR |

## API Container Configuration

- Dockerfile must define `API_HOST` and `API_PORT` environment variables
- NGINX configuration template (`nginx.conf.template` or `default.conf.template`) must use `${API_HOST}` and `${API_PORT}` in proxy_pass directive
- Template pattern: `proxy_pass http://${API_HOST}:${API_PORT}/api/;`
- NGINX automatically substitutes environment variables from templates in `/etc/nginx/templates/`
- Container exposes port 80 by default (or `SPA_PORT` if specified)

See Also: [security_standards](./security_standards.md)

## Revision history

| Date | Change |
|------|--------|
| 2026-05-29 | Initial SRE standards |
| 2026-06-04 | AWS Organization, IAM Identity Center, MentorHub-Dev, CodeArtifact target, Shared-Services placement, CD promotion model |
