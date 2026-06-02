# Dependency Registry Migration: GitHub → AWS CodeArtifact

## Executive summary

Move **`mentorhub_api_utils`** (Python/PyPI) and **`mentorhub_spa_utils`** (npm) from **git-based installs** to **versioned packages in AWS CodeArtifact**, then update all consuming repos, Dockerfiles, local developer tooling, and GitHub Actions so builds no longer clone private GitHub repos at install time.

This aligns with the post-launch roadmap in [README.md](../README.md) and [Architecture Principles](../DeveloperEdition/standards/ArchitecturePrinciples.md): shared libraries published to private npm/PyPI registries. Container registry migration (ECR) is a separate initiative.

---

## Current state

### Shared libraries

| Repo | Package identity | Version | Publish today | Consumers |
|------|------------------|---------|---------------|-----------|
| `mentorhub_api_utils` | PyPI name: `api_utils` ([pyproject.toml](../../mentorhub_api_utils/pyproject.toml)) | `0.1.0` | **No-op** (`publish-package` echoes no-op) | 4 domain APIs |
| `mentorhub_spa_utils` | npm: `@mentor-forge/mentorhub_spa_utils` | `0.1.0` | **No-op** (`publish-package` exits 0) | 4 domain SPAs |

Both repos have build tooling (`python -m build` / `npm run build`) but **nothing publishes artifacts** on merge to `main`.

### How consumers install today

**Python (all 4 domain APIs — identical pattern):**

```toml
# mentorhub_*_api/Pipfile
api-utils = {editable = false, git = "https://github.com/mentor-forge/mentorhub_api_utils.git", ref = "main"}
```

- Tracks **`main` branch tip**, not semver — builds are non-reproducible across time.
- Comment documents a real hazard: public PyPI package **`api-utils`** is unrelated; a bare `*` would break Config/auth.

**Node (all 4 domain SPAs — identical pattern):**

```json
"@mentor-forge/mentorhub_spa_utils": "github:mentor-forge/mentorhub_spa_utils#main"
```

- `package-lock.json` pins a git commit, but `#main` in `package.json` still allows drift on lock refresh.
- Dockerfiles install **git**, rewrite URLs, and optionally pass `GITHUB_TOKEN`.

### Docker / CI impact today

| Layer | APIs | SPAs |
|-------|------|------|
| Dockerfile | `apt install git`, `GITHUB_TOKEN` build-arg, `git config url.rewrite`, `pipenv install` | `apk add git`, token rewrite, `npm ci` / `npm install` |
| GitHub Actions | `docker-push.yml` passes `GH_PAT` | `docker-push.yml` passes `GITHUB_TOKEN` |
| Secrets | Org secret **`GH_PAT`** required for API image builds | Token only needed if spa_utils repo is private |

**Not in scope for utils consumption:** `mentorhub_mongodb_api`, `mentorhub_runbook_api`, `mentorhub` (welcome page) — no Pipfile/package.json dependency on utils.

### Related documentation

- [branch_protection_standards.md](../DeveloperEdition/standards/branch_protection_standards.md): future PR CI needs `GH_PAT` for git deps — **goes away** after CodeArtifact.
- [CONTRIBUTING.md](../CONTRIBUTING.md): tokens live in `~/.mentorhub/` — extend for CodeArtifact auth.
- [architecture.yaml](./architecture.yaml): `common_code` domain `publish: pipenv` / `publish: npm`.

---

## Target state

### AWS CodeArtifact layout (recommended)

```
CodeArtifact Domain:   mentor-forge          (one per org/account)
├── Repository:        mentorhub-pypi        (internal packages + upstream PyPI)
└── Repository:        mentorhub-npm         (internal packages + upstream npmjs)
```

Use **upstream repositories** on both repos so `pip`/`npm` can resolve public deps (Flask, Vue, etc.) through CodeArtifact without split config.

### Package coordinates after migration

| Package | Registry | Install spec (example) |
|---------|----------|------------------------|
| `api_utils` | CodeArtifact PyPI | `api-utils = "==0.2.0"` in Pipfile (pin exact version in lock) |
| `@mentor-forge/mentorhub_spa_utils` | CodeArtifact npm | `"@mentor-forge/mentorhub_spa_utils": "0.2.0"` in package.json |

Keep PyPI distribution name **`api_utils`** / pip install **`api-utils`** — do not rename; only change **source**, not the public-name collision story.

### Versioning policy

1. **Semver** for both libraries (`MAJOR.MINOR.PATCH`).
2. **Publish on git tag** (`v0.2.0`) — prefer tag-driven releases over implicit main-branch publishes.
3. **Domain repos pin exact versions** (`==0.2.0` / `"0.2.0"`), not `main` or `*`.
4. **Bump utils first, then consumers** in separate PRs (utils publish → consumer version bump → image rebuild).

---

## Phase 0 — AWS foundation (infra / platform)

**Owner:** Platform / SRE  
**Prerequisites:** AWS account, IAM admin

### 0.1 Create CodeArtifact domain and repositories

```bash
aws codeartifact create-domain --domain mentor-forge
aws codeartifact create-repository --domain mentor-forge --repository mentorhub-pypi \
  --description "Mentor Hub internal PyPI + PyPI upstream"
aws codeartifact create-repository --domain mentor-forge --repository mentorhub-npm \
  --description "Mentor Hub internal npm + npmjs upstream"

aws codeartifact associate-external-connection \
  --domain mentor-forge --repository mentorhub-pypi \
  --external-connection public:pypi
aws codeartifact associate-external-connection \
  --domain mentor-forge --repository mentorhub-npm \
  --external-connection public:npmjs
```

Record for all repos (store in org-level doc / SSM Parameter Store):

- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `CODEARTIFACT_DOMAIN=mentor-forge`
- `CODEARTIFACT_PYPI_REPO=mentorhub-pypi`
- `CODEARTIFACT_NPM_REPO=mentorhub-npm`

### 0.2 IAM for GitHub Actions (OIDC)

1. Create IAM OIDC provider for `token.actions.githubusercontent.com` (if not present).
2. Role `GitHubActionsCodeArtifactPublish` — trust policy scoped to `mentor-forge/*` utils repos.
3. Role `GitHubActionsCodeArtifactRead` — read-only for consumer repo Docker builds.
4. Permissions: `codeartifact:GetAuthorizationToken`, `codeartifact:PublishPackageVersion`, `codeartifact:PutPackageMetadata`, `codeartifact:ReadFromRepository`, `sts:GetServiceBearerToken`.

### 0.3 GitHub org secrets / variables

| Name | Scope | Purpose |
|------|-------|---------|
| `AWS_ROLE_ARN_PUBLISH` | utils repos | OIDC assume role for publish |
| `AWS_ROLE_ARN_READ` | API/SPA repos | OIDC assume role for Docker build |
| `AWS_REGION` | org variable | e.g. `us-east-1` |
| `CODEARTIFACT_DOMAIN` | org variable | `mentor-forge` |
| `CODEARTIFACT_PYPI_REPO` | org variable | `mentorhub-pypi` |
| `CODEARTIFACT_NPM_REPO` | org variable | `mentorhub-npm` |

**Deprecate after migration:** reduce reliance on `GH_PAT` for dependency installs.

### 0.4 Local developer auth (`~/.mentorhub/`)

Extend Developer Edition token setup ([CONTRIBUTING.md](../CONTRIBUTING.md)):

```bash
aws codeartifact login --tool pip --domain mentor-forge --repository mentorhub-pypi
aws codeartifact login --tool npm --domain mentor-forge --repository mentorhub-npm
```

Add `mh codeartifact login` (or hook into `make update`) to refresh tokens (~12h TTL).

Document required IAM for developers: `codeartifact:GetAuthorizationToken`, `codeartifact:ReadFromRepository`.

---

## Phase 1 — Publish pipelines for utils repos

### 1.1 `mentorhub_api_utils`

**Files to add/change:**

| File | Change |
|------|--------|
| `pyproject.toml` | Confirm `name = "api_utils"`, bump version on release |
| `Pipfile` | Replace no-op `publish-package` with twine/CodeArtifact upload |
| `.github/workflows/publish-package.yml` | New: tag → build wheel/sdist → upload |
| `README.md` | Document install from CodeArtifact |

**Example publish workflow:**

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
      - run: pip install pipenv && pipenv install --dev && pipenv run build
      - run: |
          aws codeartifact login --tool twine \
            --domain ${{ vars.CODEARTIFACT_DOMAIN }} \
            --repository ${{ vars.CODEARTIFACT_PYPI_REPO }}
          pipenv run twine upload --repository codeartifact dist/*
```

### 1.2 `mentorhub_spa_utils`

**Files to add/change:**

| File | Change |
|------|--------|
| `package.json` | Implement real `publish-package` |
| `.npmrc` (committed template) | Scope `@mentor-forge` → CodeArtifact registry URL |
| `.github/workflows/publish-package.yml` | New: tag → build → `npm publish` |
| `CONTRIBUTING.md` | Remove "no registry publish" note |

CI must run `aws codeartifact login --tool npm ...` before publish.

### 1.3 Initial release

1. Tag and publish **`api_utils@0.2.0`**.
2. Tag and publish **`@mentor-forge/mentorhub_spa_utils@0.2.0`**.
3. Verify install from a clean machine using only CodeArtifact auth.

---

## Phase 2 — Update consumer repos

### 2.1 Domain APIs (4 repos)

**Repos:** `mentorhub_coordinator_api`, `mentorhub_craftsperson_api`, `mentorhub_customer_api`, `mentorhub_mentor_api`

**Pipfile — replace git dep:**

```toml
[[source]]
url = "https://<account>.d.codeartifact.<region>.amazonaws.com/pypi/mentorhub-pypi/simple/"
verify_ssl = true
name = "codeartifact"

[packages]
api-utils = {version = "==0.2.0", index = "codeartifact"}
```

> Pipenv does not expand env vars in `[[source]]` URLs by default. Options: commit URL with account/region as org constants, or run `aws codeartifact login --tool pip` and use `PIP_INDEX_URL` before `pipenv lock`.

**Dockerfile — simplified build stage:**

```dockerfile
# REMOVE: apt-get install git, git config, GITHUB_TOKEN
FROM python:3.12-slim AS build
WORKDIR /app
RUN pip install --no-cache-dir pipenv awscli
RUN aws codeartifact login --tool pip --domain "$CODEARTIFACT_DOMAIN" --repository "$CODEARTIFACT_PYPI_REPO"
COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy --system
```

**docker-push.yml:** Replace `GITHUB_TOKEN=${{ secrets.GH_PAT }}` with AWS OIDC credentials for CodeArtifact login inside the build.

### 2.2 Domain SPAs (4 repos)

**Repos:** `mentorhub_coordinator_spa`, `mentorhub_craftsperson_spa`, `mentorhub_customer_spa`, `mentorhub_mentor_spa`

**package.json:**

```json
"@mentor-forge/mentorhub_spa_utils": "0.2.0"
```

**`.npmrc` (committed, token injected at build time):**

```ini
@mentor-forge:registry=https://<account>.d.codeartifact.<region>.amazonaws.com/npm/mentorhub-npm/
always-auth=true
```

**Dockerfile:**

```dockerfile
# REMOVE: apk add git, git config, GITHUB_TOKEN rewrite
ARG CODEARTIFACT_AUTH_TOKEN
RUN echo "//...amazonaws.com/npm/.../:_authToken=${CODEARTIFACT_AUTH_TOKEN}" >> .npmrc
RUN npm ci
```

**Regenerate `package-lock.json`** — entries should resolve to CodeArtifact tarball URLs, not `git+ssh://`.

### 2.3 Future PR CI (`ci.yml`)

When adding PR workflows per [branch_protection_standards.md](../DeveloperEdition/standards/branch_protection_standards.md):

- Use same CodeArtifact auth as Docker builds.
- **Remove** `GH_PAT` requirement for dependency install.

---

## Phase 3 — Developer Edition / CLI updates

**Repo:** `mentorhub`

| Area | Change |
|------|--------|
| `CONTRIBUTING.md` | CodeArtifact setup alongside `GITHUB_TOKEN` |
| `make verify` | Check `aws` CLI + optional CodeArtifact reachability |
| `mh` CLI | `mh codeartifact login` refreshes pip + npm credentials |
| `DeveloperEdition/standards/branch_protection_standards.md` | Update dependency prerequisites |
| `README.md` Post-Launch TODO | Check off CodeArtifact items |

Local workflow after migration:

```bash
mh codeartifact login
cd mentorhub_coordinator_api && pipenv install --dev
cd mentorhub_coordinator_spa && npm ci
pipenv run container    # no GITHUB_TOKEN for deps
npm run container
```

---

## Phase 4 — Rollout sequence

| Step | Action | Validation |
|------|--------|------------|
| 1 | Phase 0 infra + IAM + org secrets | `aws codeartifact list-packages` |
| 2 | Publish utils `0.2.0` to CodeArtifact | Manual pip/npm install test |
| 3 | Migrate **one** API (`coordinator_api`) | `pipenv run test`, Docker build in CI |
| 4 | Migrate **one** SPA (`coordinator_spa`) | `npm test`, Docker build in CI |
| 5 | Roll remaining 3 APIs + 3 SPAs | All `docker-push` green |
| 6 | Update docs, deprecate git install paths | New dev onboarding test |
| 7 | Remove `GH_PAT` from API docker-push if unused | Secret audit |

**Do not** change all 10 repos in one PR — utils publish must land first.

---

## Phase 5 — Cleanup

- Remove `git` from API/SPA Dockerfiles.
- Remove git URL rewrite logic and `GITHUB_TOKEN` build-args for deps.
- Update READMEs in domain repos (currently reference git spa_utils).
- Consider retention policy on CodeArtifact for old package versions.
- Optional: Dependabot/Renovate configured against CodeArtifact for automated bump PRs.

---

## Risk register

| Risk | Mitigation |
|------|------------|
| Wrong PyPI package (`api-utils` on public PyPI) | Always install from CodeArtifact index; keep Pipfile comment |
| CodeArtifact token expiry mid-build | Refresh in Dockerfile RUN; 12h token; retry in CI |
| Non-reproducible builds during transition | Pin exact versions; single migration PR per consumer |
| Local dev friction (AWS auth) | `mh codeartifact login`, document SSO profile |
| Multi-arch Docker + QEMU slow builds | Keep existing GHA cache mounts; removing git clone helps |

---

## Files checklist (by repo)

### `mentorhub_api_utils`
- [ ] `.github/workflows/publish-package.yml`
- [ ] `Pipfile` (`publish-package` script)
- [ ] `README.md`

### `mentorhub_spa_utils`
- [ ] `.github/workflows/publish-package.yml`
- [ ] `package.json` (`publish-package`)
- [ ] `.npmrc` template
- [ ] `CONTRIBUTING.md`

### Each `mentorhub_*_api` (×4)
- [ ] `Pipfile` / `Pipfile.lock`
- [ ] `Dockerfile`
- [ ] `.github/workflows/docker-push.yml`
- [ ] `Pipfile` `container` script

### Each `mentorhub_*_spa` (×4)
- [ ] `package.json` / `package-lock.json`
- [ ] `.npmrc`
- [ ] `Dockerfile`
- [ ] `.github/workflows/docker-push.yml`
- [ ] `package.json` `container` script

### `mentorhub`
- [ ] `CONTRIBUTING.md`
- [ ] Developer Edition scripts / `make verify`
- [ ] Standards docs

---

## Success criteria

1. **`api_utils` and `@mentor-forge/mentorhub_spa_utils` are published to CodeArtifact** on tagged releases.
2. **All 4 APIs and 4 SPAs** install utils from CodeArtifact with **pinned semver**, no git deps.
3. **Docker builds** succeed in GitHub Actions **without `GH_PAT` for dependency access**.
4. **Local builds** documented via `mh codeartifact login` + standard `pipenv`/`npm` commands.
5. **Lockfiles** (`Pipfile.lock`, `package-lock.json`) committed and reproducible.

---

## References

- [AWS CodeArtifact — Python](https://docs.aws.amazon.com/codeartifact/latest/ug/using-python.html)
- [AWS CodeArtifact — npm](https://docs.aws.amazon.com/codeartifact/latest/ug/npm-auth.html)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- Internal: [architecture.yaml](./architecture.yaml), [SRE Standards](../DeveloperEdition/standards/sre_standards.md)

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-01 | Initial plan |
