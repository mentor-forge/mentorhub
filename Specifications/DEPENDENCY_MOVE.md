# Dependency Registry Migration: GitHub → AWS CodeArtifact

## Executive summary

Move `**mentorhub_api_utils**` (Python/PyPI) and `**mentorhub_spa_utils**` (npm) from **git-based installs** to **versioned packages in AWS CodeArtifact**, then update all consuming repos, Dockerfiles, local developer tooling, and GitHub Actions so builds no longer clone private GitHub repos at install time.

This aligns with the post-launch roadmap in [README.md](../README.md) and [Architecture Principles](../DeveloperEdition/standards/ArchitecturePrinciples.md): shared libraries should be published to private npm/PyPI registries. Container registry migration to ECR is related but remains a separate initiative.

## As-built AWS foundation

The following AWS foundation is now in place and should be treated as the baseline for this migration:

```text
AWS Organization
└── Root
    ├── Mike Storey
    │   └── Management account
    └── MentorHub-Dev
        └── Development workload account
```

Identity and access:

- IAM Identity Center is enabled from the Management Account.
- Human users are created in IAM Identity Center, not as IAM users.
- Groups: `Organization-Admin`, `SRE`, `Developer`.
- Permission sets (today): `Organization-Admin`, `SRE`, `Developer`.
- Account assignments (today):
  - `Organization-Admin` → Management Account.
  - `SRE` → `MentorHub-Dev`.
  - `Developer` → `MentorHub-Dev`.
- **Target (Phase -1):** add `Shared-Services` account and `Developer-Packages` permission set — see [Identity Center assignments](#-12-assign-iam-identity-center-access).
- Team accounts have been created in IAM Identity Center.
- Root users for the Management Account and `MentorHub-Dev` are MFA/passkey protected and emergency-only.
- `mike-admin` remains as a backup IAM administrator during transition.

> **Standards docs:** Revise [sre_standards.md](../DeveloperEdition/standards/sre_standards.md) to match as-implemented AWS configuration after Phase -1 and Phase 0 are complete. This migration plan is the source of truth until then.

Audit baseline:

- `MentorHub-Dev` CloudTrail trail has been created.
- Recommended trail name: `mentorhub-dev-trail`.
- KMS alias used for CloudTrail encryption: `alias/mentorhub-dev-cloudtrail`.

## Recommended change before CodeArtifact

CodeArtifact is a **shared platform service**, not an application workload. The cleanest long-term placement is a new member account:

```text
Shared-Services
```

Recommended target account model before creating CodeArtifact:

```text
AWS Organization
└── Root
    ├── Management
    ├── Shared-Services
    └── MentorHub-Dev
```

Why this change is recommended now:

- CodeArtifact will serve multiple repos and, later, multiple environments.
- Package registries are shared infrastructure, not MentorHub-Dev application resources.
- Creating CodeArtifact in `Shared-Services` avoids later migration from `MentorHub-Dev`.
- GitHub Actions can assume read/publish roles in `Shared-Services` while deployments happen in `MentorHub-Dev`.

If the team chooses not to create `Shared-Services` yet, create CodeArtifact in `MentorHub-Dev` and explicitly mark that as temporary. The rest of this plan assumes the recommended `Shared-Services` account exists.

## Current state

### Shared libraries


| Repo                  | Package identity                                                                    | Version | Publish today                              | Consumers     |
| --------------------- | ----------------------------------------------------------------------------------- | ------- | ------------------------------------------ | ------------- |
| `mentorhub_api_utils` | PyPI name: `api_utils` ([pyproject.toml](../../mentorhub_api_utils/pyproject.toml)) | `0.1.0` | **No-op** (`publish-package` echoes no-op) | 4 domain APIs |
| `mentorhub_spa_utils` | npm: `@mentor-forge/mentorhub_spa_utils`                                            | `0.1.0` | **No-op** (`publish-package` exits 0)      | 4 domain SPAs |


Both repos have build tooling (`python -m build` / `npm run build`) but **nothing publishes artifacts** on merge or tag.

### How consumers install today

**Python — all 4 domain APIs:**

```toml
# mentorhub_*_api/Pipfile
api-utils = {editable = false, git = "https://github.com/mentor-forge/mentorhub_api_utils.git", ref = "main"}
```

Problems:

- Tracks `main` branch tip, not semver.
- Builds are non-reproducible across time.
- Public PyPI package `api-utils` is unrelated; a bare `*` or wrong source could install the wrong package.

**Node — all 4 domain SPAs:**

```json
"@mentor-forge/mentorhub_spa_utils": "github:mentor-forge/mentorhub_spa_utils#main"
```

Problems:

- `package-lock.json` pins a git commit, but `#main` in `package.json` allows drift on lock refresh.
- Dockerfiles install git and use token-based URL rewrites.

### Docker / CI impact today


| Layer          | APIs                                                                                    | SPAs                                                   |
| -------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| Dockerfile     | `apt install git`, `GITHUB_TOKEN` build-arg, `git config url.rewrite`, `pipenv install` | `apk add git`, token rewrite, `npm ci` / `npm install` |
| GitHub Actions | `docker-push.yml` passes `GH_PAT`                                                       | `docker-push.yml` passes `GITHUB_TOKEN`                |
| Secrets        | Org secret `GH_PAT` required for API image builds                                       | Token only needed if spa_utils repo is private         |


**Not in scope for utils consumption:** `mentorhub_mongodb_api`, `mentorhub_runbook_api`, `mentorhub` welcome page — no Pipfile/package.json dependency on utils.

---

## Target state

### AWS CodeArtifact layout

Recommended placement:

```text
AWS Account:            Shared-Services
AWS Region:             us-east-1
CodeArtifact Domain:    mentor-forge
├── Repository:         mentorhub-pypi
└── Repository:         mentorhub-npm
```

Repository upstreams:

- `mentorhub-pypi` should have an external connection to public PyPI.
- `mentorhub-npm` should have an external connection to npmjs.

Use upstream repositories so `pip` and `npm` can resolve public dependencies through CodeArtifact without split configuration.

### Package coordinates after migration


| Package                             | Registry          | Install spec                                                   |
| ----------------------------------- | ----------------- | -------------------------------------------------------------- |
| `api_utils`                         | CodeArtifact PyPI | `api-utils = "==0.2.0"` in Pipfile                             |
| `@mentor-forge/mentorhub_spa_utils` | CodeArtifact npm  | `"@mentor-forge/mentorhub_spa_utils": "0.2.0"` in package.json |


Keep PyPI distribution name `api_utils` and pip install name `api-utils`. Do not rename the package during this migration; change the source and versioning behavior only.

### Versioning policy

1. Use SemVer for both libraries: `MAJOR.MINOR.PATCH`.
2. Publish on git tag, for example `v0.2.0`.
3. Domain repos pin exact versions: `==0.2.0` / `"0.2.0"`.
4. Publish utility packages first, then update consumers in separate PRs.
5. Do not publish mutable `latest-main` style package versions.

---

## Phase -1 — Complete AWS prerequisites before CodeArtifact

**Owner:** Platform / SRE  
**Goal:** Avoid creating shared package infrastructure in the wrong account or without cost/audit guardrails.

### -1.1 Create `Shared-Services` account

Create a new AWS account in the existing organization.

Recommended values:

```text
Account name: Shared-Services
Email alias:  shared-services@agile-learning.institute
IAM role:     OrganizationAccountAccessRole
```

Root-user standard:

- Confirm email alias receives mail.
- Reset/set root password.
- Enable MFA/passkey.
- Store credentials in password manager.
- Sign out and do not use root for daily access.

### -1.2 Assign IAM Identity Center access

Use **one `Developer` group** for all application developers. Do not create a separate group for package access. Use **account assignments and permission sets** to scope what each group can do in each account.

Target assignments after `Shared-Services` exists:


| Account         | Group     | Permission Set         | Purpose                                                   |
| --------------- | --------- | ---------------------- | --------------------------------------------------------- |
| Shared-Services | SRE       | SRE                    | CodeArtifact administration, GitHub OIDC roles            |
| Shared-Services | Developer | **Developer-Packages** | CodeArtifact read — permanent floor for all developers    |
| MentorHub-Dev   | SRE       | SRE                    | Workload infrastructure (unchanged)                       |
| MentorHub-Dev   | Developer | Developer              | Application/workload access (unchanged; may narrow later) |


**Why a separate `Developer-Packages` permission set**

IAM Identity Center applies the same permission set policy bundle in every account where it is assigned. The `Developer` permission set for `MentorHub-Dev` will likely include broader workload access than you want in `Shared-Services`. A dedicated `Developer-Packages` set assigned only in `Shared-Services` gives every developer CodeArtifact read without granting unrelated services in that account.

Principles:

- **All developers** in the `Developer` group receive `Developer-Packages` on `Shared-Services`. This access is not optional and should not be removed when other permissions are tightened.
- `**Developer`** on `MentorHub-Dev` may be restricted over time; `**Developer-Packages**` stays stable.
- Developers do not need console admin in `Shared-Services`. They need package read for `mh codeartifact login`, `pipenv install`, and `npm ci`.

See Phase -1.8 to create the `Developer-Packages` permission set.

### -1.3 Create budget for Shared-Services

Create a monthly budget before enabling CodeArtifact.

Initial standard:

```text
Monthly budget: $25
Alerts: 80%, 100%
Recipients: Mike and SRE contacts
```

### -1.4 Enable CloudTrail in Shared-Services

Create a trail for shared-service audit logging.

Recommended values:

```text
Trail name: shared-services-trail
KMS alias:  alias/shared-services-cloudtrail
Events:     management events, read/write
Regions:    multi-region when available
```

### -1.5 Record primary AWS region

**Decided:** `us-east-1` (N. Virginia), recorded 2026-06-04.

```text
AWS_REGION=us-east-1
```

Recorded in:


| Location                                                                  | Status                                                                                                     |
| ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [Specifications/aws-platform.yaml](./aws-platform.yaml)                   | Done — platform and GitHub org variable reference                                                          |
| [CONTRIBUTING.md](../CONTRIBUTING.md)                                     | Done — developer onboarding                                                                                |
| [DeveloperEdition/aws-platform.env](../DeveloperEdition/aws-platform.env) | Done — `mh` defaults via `~/.mentorhub/aws-platform.env`                                                   |
| [sre_standards.md](../DeveloperEdition/standards/sre_standards.md)        | Done — primary region                                                                                      |
| GitHub org variable `AWS_REGION`                                          | **Manual** — set to `us-east-1` in `mentor-forge` → Settings → Secrets and variables → Actions → Variables |


Remaining CodeArtifact org variables (`AWS_SHARED_SERVICES_ACCOUNT_ID`, `CODEARTIFACT_`*) are documented in [aws-platform.yaml](./aws-platform.yaml) and set in GitHub when Phase 0 infrastructure exists.

### -1.6 Configure local AWS SSO profiles

Before testing CodeArtifact, each SRE/developer should be able to use AWS CLI with IAM Identity Center.

Recommended profile names:

```text
mentorhub-shared   # SSO into Shared-Services with Developer-Packages
mentorhub-dev      # SSO into MentorHub-Dev with Developer
```

When configuring `mentorhub-shared`, select account **Shared-Services** and permission set **Developer-Packages** at the AWS access portal.

Example setup:

```bash
aws configure sso --profile mentorhub-shared
aws sso login --profile mentorhub-shared
aws sts get-caller-identity --profile mentorhub-shared
```

### -1.7 GitHub OIDC planning

Before writing package workflows, decide the AWS account and role names for GitHub Actions.

Recommended role placement:

```text
Shared-Services
├── GitHubActionsCodeArtifactPublish
└── GitHubActionsCodeArtifactRead
```

These roles should use GitHub OIDC, not static AWS access keys.

### -1.8 Create `Developer-Packages` permission set

Before any developer or consumer repo migrates off git deps, create and assign the `Developer-Packages` permission set in the Management Account (IAM Identity Center).

**Create permission set:** `Developer-Packages`

Attach an inline policy (or customer-managed policy) with at least:

```text
codeartifact:GetAuthorizationToken
codeartifact:GetRepositoryEndpoint
codeartifact:ReadFromRepository
sts:GetServiceBearerToken
```

Scope resources to the `Shared-Services` account, for example:

```text
arn:aws:codeartifact:<region>:<shared-services-account-id>:domain/mentor-forge
arn:aws:codeartifact:<region>:<shared-services-account-id>:repository/mentor-forge/mentorhub-pypi
arn:aws:codeartifact:<region>:<shared-services-account-id>:repository/mentor-forge/mentorhub-npm
```

**Assign:** `Developer` group → `Shared-Services` account → `Developer-Packages` permission set.

Do not fold these permissions into the `Developer` permission set unless that set is already scoped so narrowly that assigning it to `Shared-Services` would not grant unwanted access there.

**Optional — repository resource policy:** For cross-account automation that does not use Identity Center (unusual for human devs), a CodeArtifact repository resource policy can grant read to the `MentorHub-Dev` account or specific IAM roles. GitHub Actions should use OIDC roles in `Shared-Services` (Phase 0.2), not developer permission sets.

Validation (run as a user in the `Developer` group):

```bash
aws sso login --profile mentorhub-shared
aws codeartifact list-packages \
  --domain mentor-forge \
  --domain-owner <shared-services-account-id> \
  --repository mentorhub-pypi \
  --profile mentorhub-shared
```

Succeeds after utils packages are published (Phase 1.3). Fails with `AccessDenied` if assignment or policy is wrong — fix before migrating consumer repos.

Document the as-built permission set name, policy, and assignments in `sre_standards.md` when Phase -1 is complete.

## Phase 0 — CodeArtifact infrastructure

**Owner:** Platform / SRE  
**Account:** `Shared-Services` recommended

### 0.1 Create CodeArtifact domain and repositories

```bash
aws codeartifact create-domain \
  --domain mentor-forge \
  --profile mentorhub-shared

aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --description "MentorHub internal PyPI + PyPI upstream" \
  --profile mentorhub-shared

aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --description "MentorHub internal npm + npmjs upstream" \
  --profile mentorhub-shared

aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --external-connection public:pypi \
  --profile mentorhub-shared

aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --external-connection public:npmjs \
  --profile mentorhub-shared
```

Record for all repos:

```text
AWS_REGION=us-east-1
AWS_SHARED_SERVICES_ACCOUNT_ID=<shared-services-account-id>
CODEARTIFACT_DOMAIN=mentor-forge
CODEARTIFACT_DOMAIN_OWNER=<shared-services-account-id>
CODEARTIFACT_PYPI_REPO=mentorhub-pypi
CODEARTIFACT_NPM_REPO=mentorhub-npm
```

See [aws-platform.yaml](./aws-platform.yaml) for the canonical platform record.

For cross-account usage, include `--domain-owner <shared-services-account-id>` in login and repository endpoint commands when needed.

### 0.2 IAM for GitHub Actions via OIDC

Create or verify the IAM OIDC provider for:

```text
token.actions.githubusercontent.com
```

Create roles in `Shared-Services`:

#### `GitHubActionsCodeArtifactPublish`

Trust policy scope:

- `mentor-forge/mentorhub_api_utils`
- `mentor-forge/mentorhub_spa_utils`
- `**refs/tags/v***` only for publish workflows (required — do not allow publish from arbitrary branches)

Permissions:

- `codeartifact:GetAuthorizationToken`
- `codeartifact:GetRepositoryEndpoint`
- `codeartifact:PublishPackageVersion`
- `codeartifact:PutPackageMetadata`
- `codeartifact:ReadFromRepository`
- `sts:GetServiceBearerToken`

#### `GitHubActionsCodeArtifactRead`

Trust policy scope:

- Consumer repos that build APIs/SPAs

Permissions:

- `codeartifact:GetAuthorizationToken`
- `codeartifact:GetRepositoryEndpoint`
- `codeartifact:ReadFromRepository`
- `sts:GetServiceBearerToken`

Avoid broad `repo:*` trust policies if a narrower organization/repository/ref condition can be used.

### 0.3 GitHub organization secrets and variables


| Name                             | Scope         | Purpose                                     |
| -------------------------------- | ------------- | ------------------------------------------- |
| `AWS_ROLE_ARN_PUBLISH`           | utils repos   | OIDC role for publish                       |
| `AWS_ROLE_ARN_READ`              | API/SPA repos | OIDC role for dependency read during builds |
| `AWS_REGION`                     | org variable  | selected AWS region                         |
| `AWS_SHARED_SERVICES_ACCOUNT_ID` | org variable  | CodeArtifact account owner                  |
| `CODEARTIFACT_DOMAIN`            | org variable  | `mentor-forge`                              |
| `CODEARTIFACT_PYPI_REPO`         | org variable  | `mentorhub-pypi`                            |
| `CODEARTIFACT_NPM_REPO`          | org variable  | `mentorhub-npm`                             |


Deprecate `GH_PAT` for dependency installs after migration. It may still be needed for other GitHub operations until separately removed.

### 0.4 Local developer auth

Extend Developer Edition token setup ([CONTRIBUTING.md](../CONTRIBUTING.md)):

```bash
aws sso login --profile mentorhub-shared
aws codeartifact login \
  --tool pip \
  --domain mentor-forge \
  --domain-owner <shared-services-account-id> \
  --repository mentorhub-pypi \
  --profile mentorhub-shared
aws codeartifact login \
  --tool npm \
  --domain mentor-forge \
  --domain-owner <shared-services-account-id> \
  --repository mentorhub-npm \
  --profile mentorhub-shared
```

Add:

```bash
mh codeartifact login
```

or hook CodeArtifact refresh into `make update`.

Document that CodeArtifact auth tokens expire (~12 hours) and must be refreshed periodically.

#### `mh codeartifact login` specification


| Item          | Value                                                                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| AWS profile   | `mentorhub-shared` (override: `MH_AWS_PROFILE`)                                                                                       |
| SSO target    | Account `Shared-Services`, permission set `Developer-Packages`                                                                        |
| pip           | `aws codeartifact login --tool pip --domain mentor-forge --domain-owner <account-id> --repository mentorhub-pypi --profile <profile>` |
| npm           | `aws codeartifact login --tool npm --domain mentor-forge --domain-owner <account-id> --repository mentorhub-npm --profile <profile>`  |
| Prerequisites | Valid SSO session (`aws sso login --profile mentorhub-shared`)                                                                        |
| Failure mode  | Print actionable message if SSO session expired or `Developer-Packages` assignment missing                                            |
| Integration   | Called from `make update`; document in `CONTRIBUTING.md`                                                                              |


GitHub tokens remain required for git operations; they are not used for shared library installs after migration.

---

## Phase 1 — Publish pipelines for utility repos

### 1.1 `mentorhub_api_utils`

Files to add/change:


| File                                    | Change                                                  |
| --------------------------------------- | ------------------------------------------------------- |
| `pyproject.toml`                        | Confirm `name = "api_utils"`; bump version on release   |
| `Pipfile`                               | Replace no-op `publish-package` with build/twine upload |
| `.github/workflows/publish-package.yml` | New: tag → build wheel/sdist → upload                   |
| `README.md`                             | Document install from CodeArtifact                      |


Example publish workflow:

```yaml
on:
  push:
    tags: ['v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PUBLISH }}
          aws-region: ${{ vars.AWS_REGION }}
      - run: pip install pipenv twine build
      - run: pipenv install --dev
      - run: pipenv run build
      - run: |
          aws codeartifact login --tool twine \
            --domain ${{ vars.CODEARTIFACT_DOMAIN }} \
            --domain-owner ${{ vars.AWS_SHARED_SERVICES_ACCOUNT_ID }} \
            --repository ${{ vars.CODEARTIFACT_PYPI_REPO }}
          pipenv run twine upload --repository codeartifact dist/*
```

### 1.2 `mentorhub_spa_utils`

Files to add/change:


| File                                    | Change                                             |
| --------------------------------------- | -------------------------------------------------- |
| `package.json`                          | Implement real `publish-package`                   |
| `.npmrc` template                       | Scope `@mentor-forge` to CodeArtifact registry URL |
| `.github/workflows/publish-package.yml` | New: tag → build → `npm publish`                   |
| `CONTRIBUTING.md`                       | Remove or update “no registry publish” note        |


CI must run CodeArtifact npm login before `npm publish`.

Example publish workflow:

```yaml
on:
  push:
    tags: ['v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PUBLISH }}
          aws-region: ${{ vars.AWS_REGION }}
      - uses: actions/setup-node@v4
        with:
          node-version: '24'
      - run: npm ci
      - run: npm run build
      - run: |
          aws codeartifact login --tool npm \
            --domain ${{ vars.CODEARTIFACT_DOMAIN }} \
            --domain-owner ${{ vars.AWS_SHARED_SERVICES_ACCOUNT_ID }} \
            --repository ${{ vars.CODEARTIFACT_NPM_REPO }}
          npm publish
```

### 1.3 Initial release

1. Tag and publish `api_utils@0.2.0`.
2. Tag and publish `@mentor-forge/mentorhub_spa_utils@0.2.0`.
3. Verify install from a clean environment using only AWS SSO/CodeArtifact auth.

---

## Phase 2 — Update consumer repos

### 2.1 Domain APIs

Repos:

- `mentorhub_coordinator_api`
- `mentorhub_craftsperson_api`
- `mentorhub_customer_api`
- `mentorhub_mentor_api`

Pipfile replacement (single CodeArtifact source with PyPI upstream — public deps and `api-utils` resolve from one index):

```toml
[[source]]
url = "https://<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/pypi/mentorhub-pypi/simple/"
verify_ssl = true
name = "codeartifact"

[packages]
flask = "*"
pymongo = "*"
pyjwt = "*"
# Must use codeartifact index: PyPI package "api-utils" is unrelated; wrong index breaks Config/auth.
api-utils = {version = "==0.2.0", index = "codeartifact"}
```

Important notes:

- Use **one** `[[source]]` pointing at `mentorhub-pypi` with PyPI upstream configured (Phase 0.1). Do not maintain separate `pypi.org` and CodeArtifact sources.
- Pipenv does not reliably expand environment variables in `[[source]]` URLs — commit the account/region URL as an organization constant, or set `PIP_INDEX_URL` before `pipenv lock`.
- Keep the comment warning that public PyPI `api-utils` is unrelated.

Dockerfile and CI changes: see [Reference implementation — domain API](#reference-implementation--domain-api) and [examples/docker-push-codeartifact.yml](../DeveloperEdition/standards/examples/docker-push-codeartifact.yml).

Remove from Dockerfile: `apt-get install git`, git URL rewrites, `GITHUB_TOKEN` build-arg for deps.

Remove from `docker-push.yml`: `GH_PAT` build-arg. Use OIDC + `PIP_INDEX_URL` build-arg (token embedded in URL, short-lived in CI only).

Remove from Pipfile `container` script: `--build-arg GITHUB_TOKEN=...` (local Docker builds use `mh codeartifact login` + `PIP_INDEX_URL` or documented equivalent).

### 2.2 Domain SPAs

Repos:

- `mentorhub_coordinator_spa`
- `mentorhub_craftsperson_spa`
- `mentorhub_customer_spa`
- `mentorhub_mentor_spa`

`package.json`:

```json
"@mentor-forge/mentorhub_spa_utils": "0.2.0"
```

`.npmrc` (committed — registry URL only; auth token injected at build time or by `mh codeartifact login` locally):

```ini
@mentor-forge:registry=https://<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/
always-auth=true
```

Dockerfile and CI changes: see [Reference implementation — domain SPA](#reference-implementation--domain-spa).

Remove from Dockerfile: `apk add git`, git URL rewrites, `GITHUB_TOKEN` for spa_utils clone.

Remove from `docker-push.yml`: dependency-related `GITHUB_TOKEN` build-arg. Use OIDC + BuildKit secret for npm token.

Remove from `package.json` `container` script: `--build-arg GITHUB_TOKEN=...`.

Regenerate and commit `package-lock.json`. Lockfile entries should resolve to CodeArtifact tarball URLs, not GitHub git URLs.

### 2.3 Future PR CI

When adding PR workflows per [branch_protection_standards.md](../DeveloperEdition/standards/branch_protection_standards.md):

- Use the same CodeArtifact read auth as Docker builds.
- Remove `GH_PAT` requirement for dependency install.
- Keep package publish workflows tag-triggered, not PR-triggered.

---

## Phase 3 — Developer Edition / CLI updates

Repo: `mentorhub`


| Area                                                               | Change                                                               |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `CONTRIBUTING.md`                                                  | Add AWS SSO + CodeArtifact setup alongside GitHub token notes        |
| `make verify`                                                      | Check `aws` CLI, SSO profile, and optional CodeArtifact reachability |
| `mh` CLI                                                           | Add `mh codeartifact login` for pip + npm credentials                |
| `DeveloperEdition/standards/sre_standards.md`                      | Revise to match as-implemented AWS (after Phase -1 / Phase 0)        |
| `DeveloperEdition/standards/api_standards.md`                      | Update Dependency Management section                                 |
| `DeveloperEdition/standards/branch_protection_standards.md`        | Update PR CI dependency prerequisites                                |
| `DeveloperEdition/standards/examples/docker-push-codeartifact.yml` | Canonical post-migration workflow                                    |
| `README.md` Post-Launch TODO                                       | Check off CodeArtifact items after rollout                           |


Local workflow after migration:

```bash
mh codeartifact login
cd mentorhub_coordinator_api && pipenv install --dev
cd mentorhub_coordinator_spa && npm ci
pipenv run container
npm run container
```

No GitHub token should be required for shared utility dependency installation after migration.

---

## Phase 4 — Rollout sequence


| Step | Action                                                                                                   | Validation                                              |
| ---- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 0    | Create `Shared-Services`, budget, CloudTrail, Identity Center assignments including `Developer-Packages` | SRE and Developer can access Shared-Services via portal |
| 1    | Create CodeArtifact domain/repos and upstreams                                                           | `aws codeartifact list-repositories`                    |
| 2    | Configure GitHub OIDC roles and org variables                                                            | Test `aws sts get-caller-identity` in workflow          |
| 3    | Publish utils `0.2.0` to CodeArtifact                                                                    | Manual pip/npm install test                             |
| 4    | Migrate one API (`coordinator_api`)                                                                      | `pipenv run test`, Docker build in CI                   |
| 5    | Migrate one SPA (`coordinator_spa`)                                                                      | `npm test`, Docker build in CI                          |
| 6    | Roll remaining 3 APIs + 3 SPAs                                                                           | All `docker-push` workflows green                       |
| 7    | Update docs and onboarding                                                                               | New developer can build without `GH_PAT` for deps       |
| 8    | Remove obsolete git dependency logic                                                                     | Secret audit confirms dependency `GH_PAT` removed       |


Do not change all repos in one PR. Utility publish must happen first, then one API and one SPA should prove the pattern.

---

## Phase 5 — Cleanup

- Remove `git` from API/SPA Dockerfiles where it was only used for dependency installs.
- Remove GitHub URL rewrite logic and dependency-related `GITHUB_TOKEN`/`GH_PAT` build args.
- Update READMEs in domain repos.
- Consider CodeArtifact package retention policy for old package versions.
- Consider Dependabot/Renovate configured against CodeArtifact for automated bump PRs.
- Review whether `flatballflyer` legacy IAM access key can be disabled after the new platform workflow is stable.

---

## Risk register


| Risk                                             | Mitigation                                                                   |
| ------------------------------------------------ | ---------------------------------------------------------------------------- |
| Wrong PyPI package (`api-utils` on public PyPI)  | Always install from CodeArtifact index; keep Pipfile warning comment         |
| CodeArtifact token expiry mid-build              | Refresh token in workflow; keep builds short; retry auth on failure          |
| Shared package registry created in wrong account | Create `Shared-Services` before CodeArtifact or document temporary placement |
| Overbroad GitHub OIDC trust                      | Scope trust to repos and branches/tags where practical                       |
| Non-reproducible builds during transition        | Pin exact versions; single migration PR per consumer                         |
| Local dev friction                               | Add `mh codeartifact login`; document AWS SSO profile setup                  |
| Cross-account CodeArtifact confusion             | Always record and use `CODEARTIFACT_DOMAIN_OWNER`                            |
| Accidental AWS spend                             | Budgets before service rollout; avoid compute until needed                   |


---

## Files checklist by repo

### `mentorhub_api_utils`

- `.github/workflows/publish-package.yml`
- `Pipfile` (`publish-package` script)
- `README.md`
- Version bump/tag process documented

### `mentorhub_spa_utils`

- `.github/workflows/publish-package.yml`
- `package.json` (`publish-package`)
- `.npmrc` template
- `CONTRIBUTING.md`
- Version bump/tag process documented

### Each `mentorhub_*_api` (×4)

- `Pipfile` / `Pipfile.lock`
- `Dockerfile`
- `.github/workflows/docker-push.yml`
- `Pipfile` `container` script if dependency auth is embedded there

### Each `mentorhub_*_spa` (×4)

- `package.json` / `package-lock.json`
- `.npmrc`
- `Dockerfile`
- `.github/workflows/docker-push.yml`
- `package.json` `container` script if dependency auth is embedded there

### `mentorhub`

- `CONTRIBUTING.md`
- Developer Edition scripts / `make verify`
- `mh codeartifact login`
- `Developer-Packages` permission set created and assigned (Phase -1.8)
- `DeveloperEdition/standards/sre_standards.md` (revise as-implemented)
- `DeveloperEdition/standards/api_standards.md`
- `DeveloperEdition/standards/branch_protection_standards.md`
- `DeveloperEdition/standards/examples/docker-push-codeartifact.yml`

---

## Reference implementation appendix

Copy patterns from here into the coordinator pilot repos, then replicate to the remaining APIs/SPAs.

**Scope reminder:** Container images continue publishing to **GHCR**. Only shared **library** install sources change.

### Reference implementation — domain API

**Pipfile** — see Phase 2.1 (single CodeArtifact source + PyPI upstream).

**Dockerfile** (build stage excerpt):

```dockerfile
FROM python:3.12-slim AS build

WORKDIR /app

RUN pip install --no-cache-dir pipenv

COPY Pipfile Pipfile.lock ./

ARG PIP_INDEX_URL
ENV PIP_INDEX_URL=${PIP_INDEX_URL}

RUN pipenv install --deploy --system && \
    pip install --no-cache-dir gunicorn

COPY src/ ./src/
COPY docs/ ./docs/
RUN pipenv run build
```

Production stage unchanged — no git, no AWS CLI, no tokens in final image layers.

`**.github/workflows/docker-push.yml**` — use [docker-push-codeartifact.yml](../DeveloperEdition/standards/examples/docker-push-codeartifact.yml) `build_push_api` job. Replace `REPLACE_ME_API` with the repo image name.

**Local container build** (after `mh codeartifact login`):

```bash
# Export index URL from active pip credentials, or construct from CodeArtifact login output
pipenv run container   # container script passes PIP_INDEX_URL instead of GITHUB_TOKEN
```

### Reference implementation — domain SPA

`**.npmrc**` (committed):

```ini
@mentor-forge:registry=https://<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/
always-auth=true
```

**Dockerfile** (build stage excerpt):

```dockerfile
FROM node:24-alpine AS build

ENV NPM_CONFIG_UPDATE_NOTIFIER=false

WORKDIR /app

COPY package*.json .npmrc ./

ARG VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/
ENV VITE_IDP_LOGIN_URI=$VITE_IDP_LOGIN_URI

RUN --mount=type=secret,id=codeartifact_token \
    --mount=type=cache,target=/root/.npm \
    sh -c 'echo "//<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/:_authToken=$(cat /run/secrets/codeartifact_token)" >> .npmrc && \
    if [ -f package-lock.json ]; then npm ci; else npm install; fi'

COPY . .
RUN --mount=type=cache,target=/app/node_modules/.vite \
    npm run build
```

`**.github/workflows/docker-push.yml**` — use [docker-push-codeartifact.yml](../DeveloperEdition/standards/examples/docker-push-codeartifact.yml) `build_push_spa` job. Pass `secrets: codeartifact_token=...` to BuildKit.

**Local container build:** run `mh codeartifact login` first so `~/.npmrc` has a valid token; local `npm run container` can use default npm auth without BuildKit secrets.

### Secret surface after migration


| Secret / variable                                                         | Used for                                          |
| ------------------------------------------------------------------------- | ------------------------------------------------- |
| `AWS_ROLE_ARN_PUBLISH`                                                    | Utils repos — tag publish to CodeArtifact         |
| `AWS_ROLE_ARN_READ`                                                       | API/SPA repos — Docker build dependency auth      |
| `GITHUB_TOKEN` (workflow)                                                 | GHCR login only — not shared library deps         |
| `GH_PAT`                                                                  | **Remove** from API docker builds after migration |
| Org vars `AWS_REGION`, `CODEARTIFACT_`*, `AWS_SHARED_SERVICES_ACCOUNT_ID` | All CodeArtifact workflows                        |


---

## Success criteria

1. `api_utils` and `@mentor-forge/mentorhub_spa_utils` are published to CodeArtifact on tagged releases.
2. All 4 APIs and 4 SPAs install utils from CodeArtifact with pinned SemVer versions.
3. Docker builds succeed in GitHub Actions without `GH_PAT` for dependency access.
4. Local builds are documented through AWS SSO + `mh codeartifact login`.
5. Lockfiles are committed and reproducible.
6. CodeArtifact is hosted in `Shared-Services` or explicitly documented as temporary if hosted elsewhere.
7. Every user in the `Developer` group has `Developer-Packages` on `Shared-Services` and can run `mh codeartifact login` successfully.

---

## References

- [AWS CodeArtifact — Python](https://docs.aws.amazon.com/codeartifact/latest/ug/using-python.html)
- [AWS CodeArtifact — npm](https://docs.aws.amazon.com/codeartifact/latest/ug/npm-auth.html)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- Internal: [architecture.yaml](./architecture.yaml), [aws-platform.yaml](./aws-platform.yaml), [SRE Standards](../DeveloperEdition/standards/sre_standards.md)

---

## Revision history


| Date       | Change                                                                                                                                                 |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-06-01 | Initial plan                                                                                                                                           |
| 2026-06-04 | Updated for as-built AWS Organization, IAM Identity Center, MentorHub-Dev, CloudTrail/KMS, and recommended Shared-Services account before CodeArtifact |
| 2026-06-04 | Phase -1.8 developer read access; reference implementation appendix; promoted sre_standards; concrete Dockerfile/CI patterns                           |
| 2026-06-04 | `Developer-Packages` permission set strategy; sre_standards deferred to as-implemented revision                                                        |
| 2026-06-04 | Phase -1.5: primary region `us-east-1` recorded in aws-platform.yaml, CONTRIBUTING, mh defaults                                                        |


