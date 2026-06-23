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

CodeArtifact is hosted in **Shared-Services** only. Do not create CodeArtifact in MentorHub-Dev.

Why Shared-Services:

- CodeArtifact will serve multiple repos and, later, multiple environments.
- Package registries are shared infrastructure, not MentorHub-Dev application resources.
- GitHub Actions assume read/publish roles in `Shared-Services` while deployments run in `MentorHub-Dev`.

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

## AWS and GitHub — concepts (read this first)

This section explains **what** you are configuring and **why**, before the step-by-step tasks. Canonical values live in [aws-platform.yaml](./aws-platform.yaml).

### The three AWS accounts

```text
Management account     → Organization, IAM Identity Center, billing (no app workloads)
Shared-Services        → CodeArtifact, GitHub OIDC roles (no app containers/DBs)
MentorHub-Dev            → Application infrastructure (ECS, VPC, etc.)
```

**Rule of thumb:** If it is a **shared package registry** or **CI authentication to AWS**, it belongs in **Shared-Services**. If it is a **running MentorHub service**, it belongs in **MentorHub-Dev**.

### Two kinds of “region” (both correct)

| Name | Value | When you use it |
| ---- | ----- | --------------- |
| **SSO region** | `us-east-2` | Only for `aws configure sso` and `aws sso login` (IAM Identity Center home region) |
| **Workload region** | `us-east-1` | CodeArtifact, `--region` on CLI commands, GitHub `AWS_REGION`, future ECS/ECR |

Do not change Identity Center to `us-east-1` to “match” CodeArtifact. They are independent settings.

### Two kinds of human access

| Path | Used for | Avoid for |
| ---- | -------- | --------- |
| **IAM Identity Center** (AWS access portal + `aws sso login`) | Daily work, local `pip`/`npm`, SRE CLI | — |
| **Root user / IAM users** | Emergency only | Normal development |

Local CLI profiles (see Phase -1.6):

```text
mentorhub-shared  →  Shared-Services account  (CodeArtifact — all developers via make aws-setup)
mentorhub-dev     →  MentorHub-Dev account    (SRE/platform only — not required for local dev)
```

### Two kinds of automation access (GitHub Actions)

GitHub Actions use **OIDC** to assume IAM roles in Shared-Services — no long-lived AWS access keys in GitHub.

---

## How to use this plan

1. Do **one step** at a time — only the step labeled with the number you are on.
2. Run **Validate** at the end of that step.
3. Follow **Next step** — do not act on later phases until you reach them.

GitHub workflow YAML, consumer repo migrations, and `GH_PAT` removal are documented in later phases. They are not part of the step you are on until that phase begins.

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

**Next step:** -1.2

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
- Developers do not need console admin in `Shared-Services`. They need package read for local `pipenv install` and `npm ci` (Developer Edition tooling in Phase 3).

**Next step:** -1.3

### -1.3 Create budget for Shared-Services

Create a monthly budget before enabling CodeArtifact.

Initial standard:

```text
Monthly budget: $25
Alerts: 80%, 100%
Recipients: Mike and SRE contacts
```

**Next step:** -1.4

### -1.4 Enable CloudTrail in Shared-Services

Create a trail for shared-service audit logging.

Recommended values:

```text
Trail name: shared-services-trail
KMS alias:  alias/shared-services-cloudtrail
Events:     management events, read/write
Regions:    multi-region when available
```

**Next step:** -1.5

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
| GitHub org variable `AWS_REGION`                                          | Set in step 0.3                                                                                            |


#### Two AWS regions (do not conflate)

MentorHub uses **two different regions** for different purposes. Both are correct; they are not interchangeable.

| Setting | Region | Used for |
| ------- | ------ | -------- |
| `sso_region` (in `[sso-session]` in `~/.aws/config`) | **`us-east-2`** | IAM Identity Center sign-in only (`aws sso login`, `aws configure sso`) |
| `AWS_REGION` / profile `region` / `--region` on CLI commands | **`us-east-1`** | CodeArtifact, GitHub Actions, and future application infrastructure |

**How to find each:**

- **SSO region:** Management account → **IAM Identity Center → Settings** (home region of the Identity Center instance). As-built: `us-east-2`.
- **Workload region:** Platform decision recorded in Phase -1.5: `us-east-1`.

**Example `~/.aws/config`:**

```ini
[profile mentorhub-shared]
sso_session = mentor-forge
sso_account_id = <shared-services-account-id>
sso_role_name = Developer-Packages
region = us-east-1

[sso-session mentor-forge]
sso_start_url = https://d-906780e571.awsapps.com/start
sso_region = us-east-2
sso_registration_scopes = sso:account:access
```

Sign-in talks to Identity Center in `us-east-2`. After login, CodeArtifact and other service calls use `us-east-1` (from profile `region` or explicit `--region us-east-1`).

**Next step:** -1.6

### -1.6 Configure local AWS SSO profiles

Before testing CodeArtifact, each SRE/developer should be able to use AWS CLI with IAM Identity Center.

**Developers:** After `make install`, run `make aws-setup` once ([CONTRIBUTING.md](../CONTRIBUTING.md)). This configures only `mentorhub-shared` (Shared-Services / `Developer-Packages`) for CodeArtifact — not MentorHub-Dev.

**SRE:** Also configure `mentorhub-dev` for MentorHub-Dev account access via `aws configure sso --profile mentorhub-dev` (reuse SSO session `mentor-forge`). Values from [aws-platform.yaml](./aws-platform.yaml) `identity_center` block.

```bash
aws configure sso --profile mentorhub-shared
```

Answer the prompts:

| Prompt | Value | Notes |
| ------ | ----- | ----- |
| SSO session name | `mentor-forge` | Reuse for both profiles |
| SSO start URL | From `identity_center.sso_start_url` in aws-platform.yaml | Also in Management account → IAM Identity Center → Settings → **AWS access portal URL** |
| SSO region | `us-east-2` | Identity Center **home** region — not `us-east-1` |
| SSO registration scopes | `sso:account:access` | Press Enter for default |
| CLI profile name | `mentorhub-shared` | Often pre-filled from `--profile` flag |
| CLI default client Region | `us-east-1` | Workload region for CodeArtifact API calls |
| CLI default output format | `json` |

The wizard opens a browser. Sign in, then select:

- **Account:** `Shared-Services`
- **Role:** `Developer-Packages` for developers; `SRE` for platform setup

**Second profile (`mentorhub-dev`):** Run `aws configure sso --profile mentorhub-dev` again. Reuse SSO session `mentor-forge` (same URL, SSO region, scopes). Select account **MentorHub-Dev** and role **Developer** (developers) or **SRE** (platform team).

**Verify:**

```bash
aws sso login --profile mentorhub-shared   # only needed when session expires
aws sts get-caller-identity --profile mentorhub-shared
# "Account" should be Shared-Services (560167829275). "Arn" should show your permission set role.
```

`aws configure sso` may perform an initial login; you still run `aws sso login` later when the session expires (typically after several hours).

**Next step:** -1.8

### -1.8 Create `Developer-Packages` permission set

Before any developer or consumer repo migrates off git deps, create and assign the `Developer-Packages` permission set in the **Management account** (IAM Identity Center is always administered from there).

**Console path:** Management account → **IAM Identity Center** → **Permission sets** → **Create permission set**

**Create permission set:** `Developer-Packages`

**Permissions:** Attach an **inline policy** on the permission set, scoped to the `mentor-forge` domain and repos:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codeartifact:GetAuthorizationToken",
        "codeartifact:GetRepositoryEndpoint",
        "codeartifact:ReadFromRepository"
      ],
      "Resource": [
        "arn:aws:codeartifact:us-east-1:560167829275:domain/mentor-forge",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-pypi",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-npm",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-pypi/*",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-npm/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "sts:GetServiceBearerToken",
      "Resource": "*"
    }
  ]
}
```

Do not attach the broad `Developer` permission set to Shared-Services. Do not use account-wide managed policies such as `AWSCodeArtifactReadOnlyAccess` for this permission set.

**Assign the permission set (console):**

1. IAM Identity Center → **AWS accounts**
2. Select **Shared-Services**
3. **Assign users or groups**
4. Group: **Developer**
5. Permission set: **Developer-Packages**
6. Confirm

Also ensure **SRE** group has **SRE** permission set on Shared-Services (for domain creation and OIDC setup).

**Validate:**

```bash
aws sso login --profile mentorhub-shared
aws sts get-caller-identity --profile mentorhub-shared
# Expect Shared-Services account; role Developer-Packages (or SRE while you are setting up)
```

**Next step:** Phase 0.1

## Phase 0 — CodeArtifact infrastructure

**Owner:** Platform / SRE  
**Account:** `Shared-Services`

### 0.1 Create CodeArtifact domain and repositories

**Who:** SRE with **SRE** permission set on Shared-Services (Developer-Packages is read-only — not enough to create domains).

**Before you run commands:**

```bash
aws sso login --profile mentorhub-shared
aws sts get-caller-identity --profile mentorhub-shared
# Confirm Account = 560167829275 (Shared-Services)
```

**What you are creating:**

| AWS object | Name | Purpose |
| -------- | ---- | ------- |
| Domain | `mentor-forge` | Container for all MentorHub package repos |
| Repository | `mentorhub-pypi` | Private PyPI + upstream to public PyPI |
| Repository | `mentorhub-npm` | Private npm + upstream to npmjs |
| External connection | `public:pypi` / `public:npmjs` | Lets pip/npm resolve public packages through CodeArtifact |

**Run (all in `us-east-1`):**

```bash
aws codeartifact create-domain \
  --domain mentor-forge \
  --profile mentorhub-shared \
  --region us-east-1

aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --description "MentorHub internal PyPI + PyPI upstream" \
  --profile mentorhub-shared \
  --region us-east-1

aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --description "MentorHub internal npm + npmjs upstream" \
  --profile mentorhub-shared \
  --region us-east-1

aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --external-connection public:pypi \
  --profile mentorhub-shared \
  --region us-east-1

aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --external-connection public:npmjs \
  --profile mentorhub-shared \
  --region us-east-1
```

**Validate:**

```bash
aws codeartifact list-domains --profile mentorhub-shared --region us-east-1
aws codeartifact list-repositories --profile mentorhub-shared --region us-east-1
# Expect domain mentor-forge and repos mentorhub-pypi, mentorhub-npm
```

**Record values:**

1. Update [aws-platform.yaml](./aws-platform.yaml) `codeartifact` and `github_org_variables`.
2. Update [DeveloperEdition/aws-platform.env](../DeveloperEdition/aws-platform.env), then run `make update` on each developer machine.

**Next step:** 0.2

### 0.2 IAM for GitHub Actions via OIDC

**Account:** Sign into **Shared-Services** as **SRE** (access portal or `mentorhub-shared` profile with SRE role).

Create two IAM roles in this account:

```text
GitHubActionsCodeArtifactPublish
GitHubActionsCodeArtifactRead
```

Do not put these roles in the Management account or MentorHub-Dev. Do not create IAM users with access keys for GitHub.

#### Step 0.2.1 — Create the GitHub OIDC identity provider (once per account)

**Console:** Shared-Services → **IAM** → **Identity providers** → **Add provider**

| Field | Value |
| ----- | ----- |
| Provider type | OpenID Connect |
| Provider URL | `https://token.actions.githubusercontent.com` |
| Audience | `sts.amazonaws.com` |

**Next step:** 0.2.2

#### Step 0.2.2 — Create role `GitHubActionsCodeArtifactPublish`

**Account:** Shared-Services, signed in as **SRE** (not Developer-Packages).

The console splits this into a **permissions policy** and a **role**. Trust relationships are edited on the **role**, not on the policy page.

**A. Create permissions policy** (IAM → **Policies** → **Create policy** → **JSON**):

Policy name: `CodeArtifactPublish`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codeartifact:GetAuthorizationToken",
        "codeartifact:GetRepositoryEndpoint",
        "codeartifact:PublishPackageVersion",
        "codeartifact:PutPackageMetadata",
        "codeartifact:ReadFromRepository"
      ],
      "Resource": [
        "arn:aws:codeartifact:us-east-1:560167829275:domain/mentor-forge",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-pypi",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-npm",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-pypi/*",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-npm/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "sts:GetServiceBearerToken",
      "Resource": "*"
    }
  ]
}
```

**B. Create role** (IAM → **Roles** → **Create role** → **Web identity** → GitHub OIDC provider):

- Audience: `sts.amazonaws.com`
- Organization: `mentor-forge` (repo/branch `*` in the wizard is OK temporarily)
- Role name: `GitHubActionsCodeArtifactPublish`
- Skip permissions in the wizard (attach policy in step C)

**C. Attach policy:** Role → **Permissions** → **Add permissions** → **Attach policies** → select `CodeArtifactPublish`.

**D. Edit trust policy** (Role → **Trust relationships** → **Edit trust policy** — this is not on the policy create page):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::560167829275:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:mentor-forge/mentorhub_api_utils:ref:refs/tags/v*",
            "repo:mentor-forge/mentorhub_spa_utils:ref:refs/tags/v*"
          ]
        }
      }
    }
  ]
}
```

**E. Copy the role ARN** from the role summary (e.g. `arn:aws:iam::560167829275:role/GitHubActionsCodeArtifactPublish`). Keep it for step 0.3.

**Next step:** 0.2.3

#### Step 0.2.3 — Create role `GitHubActionsCodeArtifactRead`

**Account:** Shared-Services, signed in as **SRE**.

**A. Create permissions policy** (IAM → **Policies** → **Create policy** → **JSON**):

Policy name: `CodeArtifactRead`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codeartifact:GetAuthorizationToken",
        "codeartifact:GetRepositoryEndpoint",
        "codeartifact:ReadFromRepository"
      ],
      "Resource": [
        "arn:aws:codeartifact:us-east-1:560167829275:domain/mentor-forge",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-pypi",
        "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-npm",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-pypi/*",
        "arn:aws:codeartifact:us-east-1:560167829275:package/mentor-forge/mentorhub-npm/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "sts:GetServiceBearerToken",
      "Resource": "*"
    }
  ]
}
```

**B. Create role** (IAM → **Roles** → **Create role** → **Web identity** → GitHub OIDC provider):

- Audience: `sts.amazonaws.com`
- Organization: `mentor-forge` (repo/branch `*` in the wizard is OK temporarily)
- Role name: `GitHubActionsCodeArtifactRead`
- Skip permissions in the wizard (attach policy in step C)

**C. Attach policy:** Role → **Permissions** → **Add permissions** → **Attach policies** → select `CodeArtifactRead`.

**D. Edit trust policy** (Role → **Trust relationships** → **Edit trust policy**):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::560167829275:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:mentor-forge/mentorhub_coordinator_api:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_customer_api:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_mentee_api:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_mentor_api:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_coordinator_spa:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_customer_spa:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_mentee_spa:ref:refs/heads/main",
            "repo:mentor-forge/mentorhub_mentor_spa:ref:refs/heads/main"
          ]
        }
      }
    }
  ]
}
```

**E. Copy the role ARN** from the role summary. Keep both role ARNs for step 0.3.

**Next step:** 0.3

### 0.3 GitHub organization secrets and variables

Open https://github.com/organizations/mentor-forge/settings/secrets/actions

#### Organization variables

**Variables** tab — create each row (visibility **All repositories**):

| Name | Value |
| ---- | ----- |
| `AWS_REGION` | `us-east-1` |
| `AWS_SHARED_SERVICES_ACCOUNT_ID` | `560167829275` |
| `CODEARTIFACT_DOMAIN` | `mentor-forge` |
| `CODEARTIFACT_PYPI_REPO` | `mentorhub-pypi` |
| `CODEARTIFACT_NPM_REPO` | `mentorhub-npm` |

#### Organization secrets

**Secrets** tab — create each row (visibility **All repositories**):

| Name | Value |
| ---- | ----- |
| `AWS_ROLE_ARN_PUBLISH` | ARN from step 0.2.2 |
| `AWS_ROLE_ARN_READ` | ARN from step 0.2.3 |

**Validate:** In GitHub org settings, confirm all five variables and both secrets are listed.

**Next step:** Phase 1

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

**Next step:** Phase 2

---

## Phase 2 — Update consumer repos

### Rollout order (coordinator-first)

Prove the pattern on **coordinator** (one API + one SPA), then migrate the remaining three journeys in a fixed order. One repo per PR; do not batch.

| Step | Repo | Section | Status |
| ---- | ---- | ------- | ------ |
| 1 | `mentorhub_coordinator_api` | [§2.1](#21-domain-apis) | **Done** — merged; CodeArtifact `api-utils==0.2.1`, install/lock scripts, OIDC Docker CI |
| 2 | `mentorhub_coordinator_spa` | [§2.2](#22-domain-spas) | **Done** — merged; `spa_utils@0.2.2`, BuildKit npm secret, unit-test setup |
| 3 | `mentorhub_customer_api` | §2.1 | **Done** — PR merged or ready |
| 4 | `mentorhub_customer_spa` | §2.2 | **Done** — PR merged or ready |
| 5 | `mentorhub_mentee_api` | §2.1 | **Done** — PR merged or ready |
| 6 | `mentorhub_mentee_spa` | §2.2 | **Done** — PR merged or ready |
| 7 | `mentorhub_mentor_api` | [§2.4](#24-mentor-journey--final-phase-2-repos) | **Done** — CodeArtifact `api-utils==0.2.1`, install/lock/build scripts, OIDC Docker CI |
| 8 | `mentorhub_mentor_spa` | §2.4 | **Done** — `spa_utils@0.2.2`, BuildKit npm secret, unit-test setup |

**Phase 2 gate:** Complete — steps 7–8 merged; confirm `docker-push` is green on `main` for both mentor repos before [Phase 3](#phase-3--developer-edition--cli-updates).

**Why mentor last:** `mentorhub_mentor_api` and `mentorhub_mentor_spa` have active feature branches from other engineers. Luke owns the CodeArtifact migration; feature owners re-base onto updated `main` after each mentor repo merges (see [§2.4](#24-mentor-journey--final-phase-2-repos)).

**Per-repo validation (each step):** local install after `mh` → unit tests → Docker build (`npm run container` / `pipenv run container`) → merge to `main` → `docker-push` workflow green (trigger is `push` to `main` only — merge creates that event; see [§2.3](#23-future-pr-ci)).

**Next step:** [Phase 3](#phase-3--developer-edition--cli-updates) — Developer Edition / CLI updates

### CodeArtifact repository URLs

Repository endpoints use **`{domain}-{account-id}.d.codeartifact.{region}.amazonaws.com`**, not `{account-id}.d.codeartifact...` alone. If the domain prefix is omitted, npm/pip auth tokens will not match the registry URL and installs or publishes fail.

Confirm with:

```bash
aws codeartifact get-repository-endpoint --domain mentor-forge --domain-owner 560167829275 \
  --repository mentorhub-npm --format npm --region us-east-1 --profile mentorhub-shared
```

As-built (Shared-Services, `us-east-1`):

```text
npm:  https://mentor-forge-560167829275.d.codeartifact.us-east-1.amazonaws.com/npm/mentorhub-npm/
pypi: https://mentor-forge-560167829275.d.codeartifact.us-east-1.amazonaws.com/pypi/mentorhub-pypi/simple/
```

### 2.1 Domain APIs

Repos (per [architecture.yaml](./architecture.yaml)):

- `mentorhub_coordinator_api` — **pilot complete**
- `mentorhub_customer_api` — **done**
- `mentorhub_mentee_api` — **done**
- `mentorhub_mentor_api` — **done** ([§2.4](#24-mentor-journey--final-phase-2-repos))

All domain APIs migrated.

Pipfile replacement (single CodeArtifact source with PyPI upstream — public deps and `api-utils` resolve from one index):

```toml
[[source]]
url = "https://<codeartifact-domain>-<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/pypi/mentorhub-pypi/simple/"
verify_ssl = true
name = "codeartifact"

[packages]
flask = "*"
pymongo = "*"
pyjwt = "*"
# Must use codeartifact index: PyPI package "api-utils" is unrelated; wrong index breaks Config/auth.
api-utils = {version = "==0.2.1", index = "codeartifact"}
```

Important notes:

- Use **one** `[[source]]` pointing at `mentorhub-pypi` with PyPI upstream configured (Phase 0.1). Do not maintain separate `pypi.org` and CodeArtifact sources.
- Pipenv does not reliably expand environment variables in `[[source]]` URLs — commit the account/region URL as an organization constant, or set `PIP_INDEX_URL` before `pipenv lock`.
- Keep the comment warning that public PyPI `api-utils` is unrelated.
- **Coordinator pilot as-built:** `scripts/pipenv-install.sh`, `scripts/pipenv-lock.sh`, `scripts/docker-build.sh`, `pipenv run install`; CI assumes `GitHubActionsCodeArtifactRead` on `push` to `main` only (not `pull_request` — OIDC `sub` differs).

Dockerfile and CI changes: see [Reference implementation — domain API](#reference-implementation--domain-api) and [examples/docker-push-codeartifact.yml](../DeveloperEdition/standards/examples/docker-push-codeartifact.yml).

Remove from Dockerfile: `apt-get install git`, git URL rewrites, `GITHUB_TOKEN` build-arg for deps.

Remove from `docker-push.yml`: `GH_PAT` build-arg. Use OIDC + `PIP_INDEX_URL` build-arg (token embedded in URL, short-lived in CI only). Trigger on `push` to `main` only.

Remove from Pipfile `container` script: `--build-arg GITHUB_TOKEN=...` (local Docker builds use `mh codeartifact login` + `PIP_INDEX_URL` or documented equivalent).

**Next step:** [Phase 3](#phase-3--developer-edition--cli-updates)

### 2.2 Domain SPAs

Repos (per [architecture.yaml](./architecture.yaml)):

- `mentorhub_coordinator_spa` — **pilot complete**
- `mentorhub_customer_spa` — **done**
- `mentorhub_mentee_spa` — **done**
- `mentorhub_mentor_spa` — **done** ([§2.4](#24-mentor-journey--final-phase-2-repos))

All domain SPAs migrated.

`package.json`:

```json
"@mentor-forge/mentorhub_spa_utils": "0.2.2"
```

`.npmrc` (committed — registry URL only; auth token injected at build time or by `mh` locally):

```ini
@mentor-forge:registry=https://<codeartifact-domain>-<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/
```

Do not use `always-auth` in project `.npmrc` (deprecated in npm 11). Inject `//…/:_authToken=` at Docker build time or rely on `mh` for local installs.

Dockerfile and CI changes: see [Reference implementation — domain SPA](#reference-implementation--domain-spa).

Remove from Dockerfile: `apk add git`, git URL rewrites, `GITHUB_TOKEN` for spa_utils clone.

Remove from `docker-push.yml`: dependency-related `GITHUB_TOKEN` build-arg. Use OIDC + BuildKit secret for npm token.

Remove from `package.json` `container` script: `--build-arg GITHUB_TOKEN=...`.

Remove `pull_request` trigger from `docker-push.yml` if present — merged PRs already fire `push` to `main`; `pull_request` OIDC subjects do not match the CodeArtifactRead trust policy.

Regenerate and commit `package-lock.json`. Lockfile entries should resolve to CodeArtifact tarball URLs, not GitHub git URLs.

**Coordinator SPA pilot checklist** (complete on coordinator; repeat pattern for mentor):

- [x] `.npmrc` with CodeArtifact registry URL (no `always-auth`)
- [x] `package.json` pins `@mentor-forge/mentorhub_spa_utils` SemVer (not `github:…`)
- [x] `package-lock.json` regenerated after `mh` + `npm ci`
- [x] Dockerfile uses BuildKit secret for `_authToken` (no git clone of `spa_utils`)
- [x] `docker-push.yml` OIDC + npm token secret; `push` to `main` only
- [x] `tests/setup.ts` for Node 24 `localStorage`; `client.test.ts` mocks `redirectToIdpLogin`
- [x] `npm test` / `npm run build` / local `npm run container` green

**Next step:** [Phase 3](#phase-3--developer-edition--cli-updates)

### 2.3 Future PR CI

When adding PR workflows per [branch_protection_standards.md](../DeveloperEdition/standards/branch_protection_standards.md):

- Use the same CodeArtifact read auth as Docker builds.
- Remove `GH_PAT` requirement for dependency install.
- Keep package publish workflows tag-triggered, not PR-triggered.

---

### 2.4 Mentor journey — final Phase 2 repos

**Status:** **Done** (2026-06-15)  
**Owner:** Luke  
**Repos:** `mentorhub_mentor_api` (step 7), `mentorhub_mentor_spa` (step 8)  
**Unblocks:** [Phase 3](#phase-3--developer-edition--cli-updates)

These are the last consumer repos still on git-based `api-utils` / `spa_utils` installs. All other journey APIs and SPAs have been migrated using the coordinator pilots as reference.

#### Reference implementations (copy from `main`)

| Role | API | SPA |
| ---- | --- | --- |
| Pilot (canonical) | `mentorhub_coordinator_api` | `mentorhub_coordinator_spa` |
| Same pattern, recent | `mentorhub_customer_api`, `mentorhub_mentee_api` | `mentorhub_customer_spa`, `mentorhub_mentee_spa` |

**Pinned versions (as of 2026-06-11):**

- PyPI: `api-utils==0.2.1` from CodeArtifact `mentorhub-pypi`
- npm: `@mentor-forge/mentorhub_spa_utils@0.2.2` from CodeArtifact `mentorhub-npm`

**Mentor-specific constants:**

| Repo | GHCR image | API port (Dockerfile `EXPOSE` / gunicorn) | SPA dev port |
| ---- | ---------- | ----------------------------------------- | ------------ |
| `mentorhub_mentor_api` | `ghcr.io/mentor-forge/mentorhub_mentor_api:latest` | `8391` | — |
| `mentorhub_mentor_spa` | `ghcr.io/mentor-forge/mentorhub_mentor_spa:latest` | nginx → `mentorhub_mentor_api:8391` | `8392` |

#### Branch coordination (Luke + feature owners)

Luke should **announce in team chat** before starting each mentor repo migration:

1. **Freeze window:** Ask engineers with open PRs or long-lived branches in that repo to note their branch names.
2. **Luke merges migration first:** One PR per repo on branch `feature/codeartifact-deps` — dependency migration only; no unrelated feature work.
3. **Feature owners re-base:** After each migration merges to `main`, owners of open branches **re-base (or merge `main`)** and resolve conflicts before continuing feature work.
4. **Order matters:** Complete and merge `mentorhub_mentor_api` before starting `mentorhub_mentor_spa`. SPA owners re-base after API merge; SPA migration may touch overlapping CI/Docker paths.
5. **Conflict hotspots:** `Pipfile`, `Pipfile.lock`, `Dockerfile`, `.github/workflows/docker-push.yml`, `package.json`, `package-lock.json`, `.npmrc`, `scripts/`, `README.md`. Prefer keeping Luke’s CodeArtifact versions and re-applying feature changes on top.
6. **Do not** fold CodeArtifact migration into feature PRs — keeps review and rollback simple.

**Suggested owner message (copy/adapt):**

```text
MentorHub CodeArtifact migration landing on mentor_<api|spa> main this week.
Branch: feature/codeartifact-deps (Luke). After merge, please re-base your open branches onto main.
Expect conflicts in Pipfile/lock, Dockerfile, docker-push.yml, and (SPA) package.json/lock.
Questions: DEPENDENCY_MOVE.md §2.4 or Luke.
```

#### Luke — Cursor chat starter prompt

Open a **new Cursor chat** in the mentor repo workspace (or multi-root with `mentorhub_mentor_api` / `mentorhub_mentor_spa`). Paste the block below; run **API first**, then **SPA** in a separate chat or sequential turns.

```markdown
Execute Phase 2.1 (API) or 2.2 (SPA) CodeArtifact migration for the mentor journey repo,
following Specifications/DEPENDENCY_MOVE.md §2.4 and copying the as-built pattern from
mentorhub_coordinator_api + mentorhub_customer_api (API) or mentorhub_coordinator_spa +
mentorhub_customer_spa (SPA) on main.

Repo: mentorhub_mentor_api OR mentorhub_mentor_spa (one repo per PR)

API checklist (mentorhub_mentor_api):
- Pipfile: single CodeArtifact [[source]], api-utils==0.2.1 with index = "codeartifact"
- scripts/: pipenv-install.sh, pipenv-lock.sh, docker-build.sh (image mentorhub_mentor_api)
- Pipfile scripts: install, container → scripts; build-publish uses pipenv run install
- Dockerfile: PIP_INDEX_URL build-arg, no git/GITHUB_TOKEN; EXPOSE/CMD port 8391
- docker-push.yml: OIDC + PIP_INDEX_URL, push to main only (no pull_request trigger)
- .gitignore: .pipenv-requirements.txt
- README: pipenv run install after mh; e2e_auth doc refresh if stale
- Regenerate Pipfile.lock via scripts/pipenv-lock.sh after mh
- Validate: pipenv run install, pipenv run test, pipenv run container
- Branch feature/codeartifact-deps, open PR

SPA checklist (mentorhub_mentor_spa):
- .npmrc: CodeArtifact registry URL only (no always-auth)
- package.json: @mentor-forge/mentorhub_spa_utils 0.2.2, container → scripts/docker-build.sh
- scripts/docker-build.sh (image mentorhub_mentor_spa), BuildKit secret
- Dockerfile: .npmrc + codeartifact_token secret, no git/GITHUB_TOKEN; API_HOST=mentorhub_mentor_api, API_PORT=8391
- docker-push.yml: OIDC + npm BuildKit secret, push to main only
- tests/setup.ts (Node 24 localStorage); client.test.ts mocks redirectToIdpLogin from spa_utils
- vitest.config.ts: setupFiles ./tests/setup.ts
- README: mh then npm ci
- Regenerate package-lock.json after mh + npm install (CodeArtifact tarball URLs, not git)
- Validate: npm run test, npm run build, npm run container
- Branch feature/codeartifact-deps, open PR

Do not mix feature changes. After merge, notify engineers with open branches to re-base onto main.
```

#### Validation checklist (Luke, before merge)

**`mentorhub_mentor_api`**

```bash
source ~/.zshrc && mh
cd mentorhub_mentor_api
pipenv run install
pipenv run test
pipenv run db # start database
pipenv run dev # start local dev server
pipenv run e2e # end to end testing
pipenv run container   # optional local Docker
pipenv run api # start containers
pipenv run e2e # (against container runtime)
```

**`mentorhub_mentor_spa`**

```bash
source ~/.zshrc && mh
cd mentorhub_mentor_spa
npm ci                 # or npm install if lockfile regenerated
npm run test
npm run build
npm run api # start backing services
npm run dev # dev server
npm run cypress:run # e2e tests
npm run container      # optional local Docker
npm run service # start all containers
npm run cypress:run # e2e against container runtime
```

After each merge: confirm GitHub Actions `docker-push` workflow succeeds on `push` to `main`.

**Next step:** [Phase 3](#phase-3--developer-edition--cli-updates) — Developer Edition / CLI updates

---

## Phase 3 — Developer Edition / CLI updates

**Prerequisite:** Phase 2 complete — all eight consumer repos (including mentor API + SPA) migrated and CI green.

Repo: `mentorhub`

### 3.1 Local registry auth (`mh`)

`mh` with **no command** silently refreshes GHCR and CodeArtifact credentials (SSO login opens only when the session expired):

```bash
mh
```

Also runs automatically before `mh pull`, `mh up`, and during `make update`. Requires `~/.zshrc` from `make install` (sources `GITHUB_TOKEN` and `aws-platform.env`).

**Validate:** `pipenv run install` (API repos) and `npm ci` (SPA repos) succeed in a utils consumer repo after `mh`.

**Next step:** 3.2

### 3.2 Documentation and tooling


| Area                                                               | Change                                                               |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `CONTRIBUTING.md`                                                  | Add AWS SSO + CodeArtifact setup alongside GitHub token notes        |
| `make verify`                                                      | Check `aws` CLI, SSO profile, and optional CodeArtifact reachability |
| `mh` CLI                                                           | Silent registry auth on bare `mh`, `mh pull`, `mh up`, and `make update` |
| `DeveloperEdition/standards/sre_standards.md`                      | Revise to match as-implemented AWS (after Phase -1 / Phase 0)        |
| `DeveloperEdition/standards/api_standards.md`                      | Update Dependency Management section                                 |
| `DeveloperEdition/standards/branch_protection_standards.md`        | Update PR CI dependency prerequisites                                |
| `DeveloperEdition/standards/examples/docker-push-codeartifact.yml` | Canonical post-migration workflow                                    |
| `README.md` Post-Launch TODO                                       | Check off CodeArtifact items after rollout                           |


**Next step:** Phase 4

---

## Phase 4 — Rollout sequence


| Step | Action                                                                                                   | Validation                                              |
| ---- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 0    | Create `Shared-Services`, budget, CloudTrail, Identity Center assignments including `Developer-Packages` | SRE and Developer can access Shared-Services via portal |
| 1    | Create CodeArtifact domain/repos and upstreams                                                           | `aws codeartifact list-repositories`                    |
| 2    | Configure GitHub OIDC roles and org variables                                                            | Test `aws sts get-caller-identity` in workflow          |
| 3    | Publish utils to CodeArtifact (`api-utils`, `@mentor-forge/mentorhub_spa_utils`)                       | Manual pip/npm install test                             |
| 4    | Migrate `coordinator_api` (§2.1 pilot)                                                                   | **Done**                                                |
| 5    | Migrate `coordinator_spa` (§2.2 pilot)                                                                     | **Done**                                                |
| 6    | Migrate `customer_api` + `customer_spa`                                                                  | **Done**                                                |
| 7    | Migrate `mentee_api` + `mentee_spa`                                                                      | **Done**                                                |
| 8    | Migrate `mentor_api` + `mentor_spa` ([§2.4](#24-mentor-journey--final-phase-2-repos); Luke)               | **Done**                                                |
| 9    | Update docs and onboarding (Phase 3)                                                                       | **In progress** ([R106](../Tasks/AS_NEEDED.R106.codeartifact_phase3_de_onboarding.md)) |
| 10   | Remove obsolete git dependency logic (Phase 5)                                                             | After step 9                                            |


Do not change all repos in one PR. Utility publish must happen first, then the [coordinator-first rollout table](#rollout-order-coordinator-first). **Phase 2 complete — proceed with Phase 3 (step 9).**

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
| Shared package registry created in wrong account | Create `Shared-Services` before CodeArtifact |
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

Copy patterns from the **coordinator pilots** (`mentorhub_coordinator_api` — done; `mentorhub_coordinator_spa` — next), then replicate journey-by-journey: customer → mentee → mentor (mentor SPA last).

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
RUN pipenv requirements | grep -v '^-i ' > requirements.txt && \
    pip install --no-cache-dir --index-url "${PIP_INDEX_URL}" -r requirements.txt && \
    pip install --no-cache-dir gunicorn

COPY src/ ./src/
COPY docs/ ./docs/
RUN python -m compileall -b -f -q src/
```

Use `pip install` with `pipenv requirements` (not `pipenv install`) so the authenticated `PIP_INDEX_URL` is honored. `pipenv lock` still needs `pipenv lock --pypi-mirror "$AUTH_URL"` locally.

Production stage unchanged — no git, no AWS CLI, no tokens in final image layers.

`**.github/workflows/docker-push.yml**` — use [docker-push-codeartifact.yml](../DeveloperEdition/standards/examples/docker-push-codeartifact.yml) `build_push_api` job. Replace `REPLACE_ME_API` with the repo image name.

**Local container build** (after `mh`):

```bash
pipenv run container   # scripts/docker-build.sh passes PIP_INDEX_URL
```

**Local dev install** (after `mh`):

```bash
sh scripts/pipenv-install.sh   # or: pipenv run install
sh scripts/pipenv-lock.sh        # regenerate Pipfile.lock after dependency changes
```

### Reference implementation — domain SPA

`**.npmrc**` (committed):

```ini
@mentor-forge:registry=https://<codeartifact-domain>-<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/
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
    sh -c 'echo "//<codeartifact-domain>-<shared-services-account-id>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/:_authToken=$(cat /run/secrets/codeartifact_token)" >> .npmrc && \
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
6. CodeArtifact is hosted in `Shared-Services`.
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
| 2026-06-10 | AWS/GitHub primer; expanded SSO, OIDC, and GitHub variables/secrets walkthroughs; SSO region `us-east-2` vs workload `us-east-1`                       |
| 2026-06-10 | Single best-practice path: scoped custom policies, console-only OIDC setup, Shared-Services only, org-wide GitHub secrets/variables                     |
| 2026-06-10 | Phase 2: CodeArtifact URLs use `{domain}-{account-id}` host prefix; drop deprecated npm `always-auth` in consumer `.npmrc` examples                    |
| 2026-06-10 | One-step-at-a-time structure: Validate + Next step per section; removed forward references from Phase 0                        |
| 2026-06-11 | Phase 2 rollout: coordinator-first (`coordinator_api` done, `coordinator_spa` next); customer → mentee → mentor; fix API/SPA repo lists (`mentee` not `craftsperson`); mentor SPA deferred with conflict note; OIDC trust includes mentee repos; docker-push `push`-only CI note |
| 2026-06-11 | Phase 2 status: coordinator/customer/mentee APIs+SPAs done; §2.4 mentor handoff for Luke (Cursor prompt, branch re-base coordination); Phase 3 gated on mentor repos |
| 2026-06-15 | Phase 2 complete: `mentorhub_mentor_api` and `mentorhub_mentor_spa` migrated to CodeArtifact (§2.4); Phase 3 unblocked |


