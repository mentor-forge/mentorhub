# SRE Standards

Platform provisioning, CloudFormation tasks, and migration runbooks: **[mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)** (`docs/specifications/`). This document covers org-wide standards and what **application developers** need for CI, DE auth, and production alignment.

## Tech Stack
- Source Control: GitHub
- CI Automation: GitHub Actions
- Private Container Registry: GitHub Container Registry today; AWS ECR is the preferred AWS-native target for cloud deployment (separate from dependency registry migration)
- Private PyPI Registry: AWS CodeArtifact (see [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md))
- Private NPM Registry: AWS CodeArtifact (see [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md))
- Infrastructure Automation: Docker Compose for local dev; AWS IaC in [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) (`templates/`, `tasks/`)
- Container Runtime Hosting: AWS, first target account `MentorHub-Dev`
- Container Orchestration: TBD; ECS/Fargate is the preferred first AWS runtime unless/until EKS is justified
- Monitoring: Prometheus, Grafana, ELK for application observability; AWS CloudTrail for AWS API audit logging; CloudWatch for AWS-native logs/metrics
- Runbook Automation: [stage0 runbooks](https://github.com/agile-learning-institute/stage0_runbooks)

## AWS Account and Identity Standards

### As-built AWS organization

MentorHub uses AWS Organizations with a separate management account and development workload account.

```text
AWS Organization
└── Root
    ├── Mike Storey
    │   └── Management account
    └── MentorHub-Dev
        └── Development workload account
```

Target model before CodeArtifact (see [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) Phase -1):

```text
AWS Organization
└── Root
    ├── Management
    ├── Shared-Services
    └── MentorHub-Dev
```

### Management account

The existing long-lived AWS account is the **Management Account**.

Purpose:
- AWS Organizations administration
- IAM Identity Center administration
- Account creation and governance
- Billing and payment ownership
- Emergency/root recovery path

Standards:
- Do not deploy MentorHub application workloads into the Management Account.
- Do not create routine development resources in the Management Account.
- Use the Management Account only for organization, identity, billing, and governance activities.
- Root user is emergency-only and protected by MFA/passkey.
- The legacy `flatballflyer` IAM user is retained as historical/legacy access pending later cleanup.
- The `mike-admin` IAM user is retained as a backup administrator while IAM Identity Center is being adopted.

### MentorHub-Dev account

The `MentorHub-Dev` member account is the first MentorHub workload account.

Purpose:
- Development deployments
- Team learning and apprentice experimentation
- Early Stage0/MentorHub AWS integration
- Future ECS/ECR/VPC/application infrastructure

Standards:
- MentorHub development resources belong in `MentorHub-Dev`, not the Management Account.
- The root user for `MentorHub-Dev` is protected by MFA/passkey and is emergency-only.
- Human access should come through IAM Identity Center, not account-local IAM users.
- Application and automation access should use IAM roles, not long-lived access keys.

### Shared-Services account

The `Shared-Services` member account hosts shared platform services (CodeArtifact first).

Purpose:
- Private npm and PyPI package registries
- GitHub Actions OIDC roles for package publish and read
- Future shared platform services that are not application workloads

Standards:
- Do not deploy MentorHub application containers or databases into `Shared-Services`.
- Enable CloudTrail and a monthly budget before turning on CodeArtifact.
- Root user follows the same emergency-only MFA/passkey standard as other accounts.

### IAM Identity Center

IAM Identity Center is enabled from the Management Account and is the standard for all human AWS access.

```text
Humans      -> IAM Identity Center users and groups
Automation  -> IAM roles / OIDC federation
Emergency   -> Root user and backup IAM admin only
```

Configured Identity Center groups:
- `Organization-Admin`
- `SRE`
- `Developer`

Configured permission sets:
- `Organization-Admin`
- `SRE`
- `Developer`

Account assignment standard:

| Account | Group | Permission Set | Purpose |
|---------|-------|----------------|---------|
| Management | Organization-Admin | Organization-Admin | Organization, identity, billing/governance administration |
| MentorHub-Dev | SRE | SRE | Infrastructure administration in development |
| MentorHub-Dev | Developer | Developer | Developer/apprentice access without IAM administration |
| Shared-Services | SRE | SRE | CodeArtifact administration, GitHub OIDC roles |
| Shared-Services | Developer | Developer (CodeArtifact read) | Local `pipenv`/`npm` installs; no console admin required |

The Developer permission set in `Shared-Services` must allow CodeArtifact read (`GetAuthorizationToken`, `ReadFromRepository`, `GetServiceBearerToken`). Customize the permission set or add a repository resource policy if the default Developer set is too broad.

User assignment standard:
- Mike belongs to `Organization-Admin` and `SRE`.
- SRE team members belong to `SRE`.
- Apprentices and application developers belong to `Developer`.

Access pattern:

```text
AWS Access Portal
  -> sign in as Identity Center user
  -> choose AWS account
  -> choose permission set / role
```

Recommended local AWS CLI profile names:
- `mentorhub-shared` — `Shared-Services` (CodeArtifact). **All developers** — configured by `make aws-setup`.
- `mentorhub-dev` — `MentorHub-Dev` (application infrastructure). **SRE/platform only** — not required for local Developer Edition.

Do not ask team members to use root-account sign-in or IAM-user sign-in for normal work.

### Root account standard

Each AWS account has its own root user. Root users are not shared across accounts.

```text
Management Account root       -> existing management account email
MentorHub-Dev Account root      -> mentorhub-dev@agile-learning.institute
Shared-Services Account root    -> shared-services@agile-learning.institute
Future Prod roots               -> account-specific aliases
```

Root-user requirements for every AWS account:
- Verify the account email alias works before account creation.
- Set a strong password and store it in the approved password manager.
- Enable MFA/passkey.
- Sign out and do not use root for daily work.

### IAM user standard

Do not create IAM users for team members.

Permitted IAM users:
- Legacy users retained temporarily for cleanup/migration.
- Backup administrative user during IAM Identity Center adoption.

Preferred alternatives:
- Human access: IAM Identity Center.
- GitHub Actions: AWS OIDC role assumption.
- Runtime services: IAM roles.
- Local developer CLI access: IAM Identity Center / AWS SSO profiles.

## AWS Audit and Security Baseline

### CloudTrail

`MentorHub-Dev` has a CloudTrail trail configured for AWS API audit logging.

Standard trail settings for workload and shared-service accounts:

| Account | Trail name | KMS alias |
|---------|------------|-----------|
| MentorHub-Dev | `mentorhub-dev-trail` | `alias/mentorhub-dev-cloudtrail` |
| Shared-Services | `shared-services-trail` | `alias/shared-services-cloudtrail` |

Common settings:
- Scope: multi-region trail when available
- Events: management events, read and write
- Data events: disabled by default unless specifically needed
- Insights events: disabled by default unless specifically needed
- Log encryption: AWS KMS

CloudTrail should be enabled before team members begin creating AWS resources in an account.

### Budgets

Every non-management account should have an AWS Budget before substantial service usage.

| Account | Monthly budget | Alerts |
|---------|----------------|--------|
| MentorHub-Dev | `$50` | 80%, 100% |
| Shared-Services | `$25` | 80%, 100% |

Recipients: Mike and appropriate SRE contacts.

### Regions

**Primary region (decided):** `us-east-1` (N. Virginia), recorded 2026-06-04 per [DEPENDENCY_MOVE.md Phase -1.5](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md#-15-record-primary-aws-region).

Canonical values: [Specifications/aws-platform.yaml](../../Specifications/aws-platform.yaml). Local shell defaults: [DeveloperEdition/aws-platform.env](../aws-platform.env) (installed to `~/.mentorhub/aws-platform.env` by `make update`).

All GitHub Actions, CodeArtifact repositories, ECR repositories, and developer setup instructions must use **`us-east-1`** unless a future platform decision documents otherwise.

## AWS Shared Service Placement

CodeArtifact is a shared platform service rather than an application workload. The preferred long-term placement is a dedicated `Shared-Services` AWS account.

Recommended account model before production:

```text
AWS Organization
└── Root
    ├── Management
    ├── Shared-Services
    └── MentorHub-Dev
```

If CodeArtifact is created before a `Shared-Services` account exists, treat that as temporary and document the migration path. Prefer creating `Shared-Services` first to avoid moving package registries later.

### CodeArtifact layout

Implementation details and rollout steps: [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md).

```text
AWS Account:     Shared-Services
CodeArtifact Domain:  mentor-forge
├── Repository: mentorhub-pypi   (internal packages + PyPI upstream)
└── Repository: mentorhub-npm    (internal packages + npmjs upstream)
```

Record for GitHub org variables and developer tooling:

```text
AWS_REGION=us-east-1
AWS_SHARED_SERVICES_ACCOUNT_ID=<shared-services-account-id>
CODEARTIFACT_DOMAIN=mentor-forge
CODEARTIFACT_PYPI_REPO=mentorhub-pypi
CODEARTIFACT_NPM_REPO=mentorhub-npm
```

**Container images** stay on GitHub Container Registry until ECR migration is explicitly planned. This migration changes **library** install sources only.

## Developer Experience

The `mh` Developer Edition CLI is how SRE provides a strong developer experience. It manages developer environment values (keys, secrets, JWT material for local tooling, AWS/CodeArtifact login helpers, etc.) and wraps the services configured in the system [docker-compose](../docker-compose.yaml) file. Developers can run the full stack on local hardware without using `docker compose` directly for normal workflows.

### CodeArtifact local authentication

After the dependency registry migration, developers refresh private package credentials with:

```sh
mh
```

Bare `mh` also runs automatically before `mh pull`, `mh up`, and during `make update`. Requires `~/.zshrc` from `make install` (`GITHUB_TOKEN`, `aws-platform.env`).

One-time AWS SSO: `make aws-setup` (writes `~/.aws/config` from platform env; browser login once).

| Item | Standard |
|------|----------|
| AWS profile | `mentorhub-shared` (override with `MH_AWS_PROFILE_SHARED` if needed) |
| SSO | Opens browser only when session expired |
| Token lifetime | ~12 hours; run `mh` before `pipenv install`, `npm ci`, or container builds if auth fails |
| Integration | `make update` runs bare `mh` after copying CLI files |

GitHub tokens remain required for git clone/push; they are **not** required for installing `api_utils` or `mentorhub_spa_utils` after migration.

## Authentication

See the [API Standards authentication](./api_standards.md#authentication) sections for core auth implementation details, and [SPA Standards authentication](./spa_standards.md#authentication-pattern) for the UI implementations.

Developer Edition CLI and compose uses a **stable `JWT_SECRET`** so SPAs and backends agree across restarts. The umbrella **developer sign-in page** (`login.html`) mints persona JWTs client-side; journey SPAs load tokens into `localStorage` via `bootstrapAuthFromUrl()` from shared SPA utilities before boot. **`IDP_LOGIN_URI`** / **`VITE_IDP_LOGIN_URI`** default to `http://127.0.0.1:8080/login.html` so unauthenticated guards, `401` handling, and logout send users to that page—not to a per-SPA `/login` route.

**Verifying the stack after compose or image changes** (from the product checkout root, for example the repo that contains `DeveloperEdition/`):

```sh
cd mentorhub
make update
mh up all
```

## Production alignment

**API gateway and commercial IdP:** In production, traffic is intended to sit behind an **API gateway** (or edge proxy) with **TLS**, routing to SPA static assets and API services. **Authentication** uses a **commercial IdP** (OAuth2/OIDC). Access tokens are issued by the IdP (or a BFF); applications do not use APIs as a substitute IdP. APIs validate JWTs (shared secret or JWKS) with the same claim expectations as in Developer Edition. SPAs redirect to the real IdP login/authorize entry via the configured login base URL—preserving a single auth story from the local welcome page through to production IdP.

## Continuous Integration

The developer workflow follows the feature branch pattern. A developer creates a branch to work on a feature and submits a pull request (PR) when the feature is ready to be deployed. When a PR is approved by a reviewer and **merged to `main`**, CI builds and pushes a new container with a `:latest` tag to the system's container registry. Those images are deployed to a cloud DEV environment and are available for developers to use locally.

### Current state (container publish only)

- **`.github/workflows/docker-push.yml`** runs on **`push` to `main` only** — not on feature-branch pushes or open PRs.
- Merging a PR to `main` produces a single `push` event; that triggers one publish run.
- Peer review and branch protection (soft phase) gate merges; automated test gates on PRs are not enabled yet.
- Existing container workflows publish to GitHub Container Registry until the ECR migration is explicitly planned.
- Journey API and SPA **container builds** install shared libraries from **CodeArtifact** via GitHub Actions OIDC — see [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) Phase 2.

Canonical workflow references:
- Pre-migration (git deps): [examples/docker-push.yml](./examples/docker-push.yml)
- Post-migration (CodeArtifact): [examples/docker-push-codeartifact.yml](./examples/docker-push-codeartifact.yml)

Apply the same `on:` pattern in every mentor-forge repo that publishes images.

### Future state (PR automated tests)

When automated tests should run before merge, add a separate **`.github/workflows/ci.yml`** that triggers on `pull_request` to `main` only. That workflow is distinct from `docker-push.yml`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` (future) | `pull_request` → `main` | Run tests on PR branches; required checks for hard/full branch protection |
| `docker-push.yml` | `push` → `main` | Build and publish container images after merge |

Do not add `pull_request` triggers to `docker-push.yml`. Do not add bare `push:` (all branches) triggers to either workflow.

Future PR CI should use the same CodeArtifact read OIDC role as Docker builds — not `GH_PAT` for dependency access.

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

Infrastructure provisioning and maintenance automation is not yet complete. Initial AWS deployment automation should target `MentorHub-Dev` first.

## API Reverse Proxy

All SPAs are served by NGINX with reverse proxy configuration for API endpoints. This allows for secure networking configurations that do not expose the API to external access, establishing a clear separation between the front end and back end networks.

### NGINX Configuration Pattern

SPA containers use an NGINX configuration template (`nginx.conf.template`) that is processed at container startup using `envsubst`. The template supports the following environment variables:

- **`API_HOST`**: Hostname of the API server (default: `localhost`)
- **`API_PORT`**: Port of the API server (default: `8083`)
- **`IDP_LOGIN_URI`**: Full URL for login redirect after logout, on `401`, or when the SPA is not authenticated (Developer Edition default: `http://127.0.0.1:8080/login.html`; production: IdP or gateway login entry)

Build-time SPA env (**`VITE_IDP_LOGIN_URI`**) should match the same logical URL so the client can redirect without relying on NGINX-only rewrites.

### Reverse Proxy Routes

The NGINX configuration proxies the following routes to the API server:

- **`/api/*`**: All API endpoints are proxied to `http://${API_HOST}:${API_PORT}/api/`

Proxy only **`/api/*`** (and static assets) through this SPA NGINX layer; do not expose ad-hoc authentication helper routes on the API reverse proxy.

### Authentication Redirect Pattern

Protected routes and the API client redirect the browser to the configured **login base URL** (`getIdpLoginBaseUrl()` / `VITE_IDP_LOGIN_URI`) when the user is unauthenticated or tokens are cleared:

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
- [ ] AWS account has CloudTrail enabled
- [ ] AWS budget alarms are configured
- [ ] Human access is through IAM Identity Center
- [ ] Automation uses IAM roles/OIDC, not static access keys

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

## Revision history

| Date | Change |
|------|--------|
| 2026-05-29 | Initial SRE standards |
| 2026-06-04 | AWS Organization, IAM Identity Center, MentorHub-Dev, CodeArtifact target, Shared-Services placement, CD promotion model |
