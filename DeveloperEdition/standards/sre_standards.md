# SRE Standards

## Tech Stack
- Source Control: Github 
- CI Automation: Github Actions
- Private Container Registry: GitHub Container Registry
- Private PyPi Registry: GitHub (see [API Standards](./api_standards.md)) 
- Private NPM Registry: GitHub (see [SPA Standards](./spa_standards.md))
- Infrastructure Automation: Docker Compose for local dev environment
- Container Runtime Hosting: TBD
- Container Orchestration: TBD
- Monitoring: Prometheus, Grafana, ELK
- Runbook Automation: [stage0 runbooks](https://github.com/agile-learning-institute/stage0_runbooks)

## Developer Experience
The ``im`` Developer Edition CLI is how SRE provides a strong developer experience. It manages developer environment values (keys, secrets, JWT material for local tooling, etc.) and wraps the services configured in the system [docker-compose](../docker-compose.yaml) file. Developers can run the full stack on local hardware without using `docker compose` directly for normal workflows.

## Authentication
See the [API Standards authentication](./api_standards.md#authentication) sections for core auth implementation details, and [SPA Standards authentication](./spa_standards.md#authentication-pattern) for the UI implementations. 

Developer Edition CLI and compose uses a **stable `JWT_SECRET`** so SPAs and backends agree across restarts. The umbrella **welcome page** (`index.html`) issues persona links: it opens each SPA with URL-hash bootstrap parameters (`access_token`, `expires_at`, `roles`). SPAs call **`bootstrapAuthFromUrl`** from shared SPA utilities before boot so `localStorage` matches production-style bearer usage. **`IDP_LOGIN_URI`** / **`VITE_IDP_LOGIN_URI`** default to the welcome page origin (for example `http://127.0.0.1:8080/`) so unauthenticated guards, `401` handling, and logout send users back to that page—not to a per-SPA `/login` route.

**Verifying the stack after compose or image changes** (from the product checkout root, for example the repo that contains `DeveloperEdition/`):

```sh
cd {{ info.slug }}
make update
im up all
```

## Production alignment

**API gateway and commercial IdP:** In production, traffic is intended to sit behind an **API gateway** (or edge proxy) with **TLS**, routing to SPA static assets and API services. **Authentication** uses a **commercial IdP** (OAuth2/OIDC). Access tokens are issued by the IdP (or a BFF); applications do not use APIs as a substitute IdP. APIs validate JWTs (shared secret or JWKS) with the same claim expectations as in Developer Edition. SPAs redirect to the real IdP login/authorize entry via the configured login base URL—preserving a single auth story from the local welcome page through to production IdP.

## Continuous Integration
The developer workflow follows the feature branch pattern. A developer creates a branch to work on a feature, and submit a pull request (PR) when the feature is ready to be deployed. When a PR is approved by a reviewer and merged to the main branch, the CI automation will build and push a new container with a :latest tag to the system's container registry. These containers are deployed to a cloud DEV environment, and available for developers to use for local development.

## Continuous Deployment
Infrastructure provisioning and maintenance has not been implemented.

## API Reverse Proxy
All SPA's are served by NGINX with reverse proxy configuration for API endpoints. This allows for secure networking configurations that do not expose the API to external access, establishing a clear separation between the front end and back end networks.

### NGINX Configuration Pattern
SPA containers use an NGINX configuration template (`nginx.conf.template`) that is processed at container startup using `envsubst`. The template supports the following environment variables:

- **`API_HOST`**: Hostname of the API server (default: `localhost`)
- **`API_PORT`**: Port of the API server (default: `8083`)
- **`IDP_LOGIN_URI`**: Full base URL for login redirect after logout, on `401`, or when the SPA is not authenticated (Developer Edition default: umbrella welcome page, e.g. `http://127.0.0.1:8080/`; production: IdP or gateway login entry)

Build-time SPA env (**`VITE_IDP_LOGIN_URI`**) should match the same logical URL so the client can redirect without relying on NGINX-only rewrites.

### Reverse Proxy Routes
The NGINX configuration proxies the following routes to the API server:

- **`/api/*`**: All API endpoints are proxied to `http://${API_HOST}:${API_PORT}/api/`

Proxy only **`/api/*`** (and static assets) through this SPA NGINX layer; do not expose ad-hoc authentication helper routes on the API reverse proxy.

### Authentication Redirect Pattern
Protected routes and the API client redirect the browser to the configured **login base URL** (`getIdpLoginBaseUrl()` / `VITE_IDP_LOGIN_URI`) when the user is unauthenticated or tokens are cleared:

- **Developer Edition:** Points at the umbrella welcome page so developers pick a persona and land in the SPA with hash bootstrap.
- **Production:** Points at the commercial IdP (or gateway-hosted login) with TLS.

This keeps one redirect contract from local through production without per-SPA `/login` pages. 

## Service Configurability
All API's are configured using a shared [Config singleton]( {{org.git_host}}/{{org.git_org}}/{{ info.slug }}_api_utils/blob/main/py_utils/config/config.py). The Config object manages all configuration items for all API and SPA code. Configuration values are read from the first of: Config File, Environment Var, Default Value. The configuration items and non-secret values are exposed through the Config API endpoint, which is used by the SPA to get runtime configuration values.

## Service Observability
All API's expose a /metrics endpoint which exposes a text-based exposition format that Prometheus understands. This endpoint exposes detailed, real-time metrics about the API's performance, latency, error rates, and internal health.

## API Security Standards

### Production Requirements

Before deploying any API to production, ensure:

- [ ] `JWT_SECRET` is set to a strong, randomly generated value (not default)
- [ ] MongoDB connection uses authentication and encryption
- [ ] HTTPS/TLS is configured via reverse proxy
- [ ] Monitoring and logging are enabled
- [ ] All dependencies are up to date

### JWT Security

- **Signature Verification**: api_utils validates JWT signatures when `JWT_SECRET` is configured
- **Fail-Fast Validation**: Applications will not start with default `JWT_SECRET` value
- **Token Requirements**: All tokens must include `iss`, `aud`, `sub`, `exp` claims
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