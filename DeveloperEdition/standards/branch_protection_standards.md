# Branch Protection Standards (Draft)

> **Status:** Draft — not yet enforced. Configure in GitHub org/repo settings after PR CI workflows exist.

This document defines how mentor-forge protects the `main` branch across repositories. It implements the workflow described in [CONTRIBUTING.md](../../CONTRIBUTING.md) and [SRE Standards](./sre_standards.md#continuous-integration).

## Purpose

| Today (documented) | With branch protection (enforced) |
|--------------------|----------------------------------|
| Feature branches and PRs to `main` | Same, but direct pushes to `main` are blocked |
| Peer review before merge | At least one approval required |
| Tests passing before merge | Required CI checks must pass on the PR |
| Merge to `main` triggers `docker-push` | Unchanged — post-merge publishing stays as-is |

Branch protection is configured in **GitHub** (org rulesets or per-repo settings). It is not stored in application source code.

## Scope

Applies to all mentor-forge repositories on the `main` branch:

| Repository | Type |
|------------|------|
| `mentorhub` | Umbrella / Developer Edition |
| `mentorhub_api_utils` | Shared Python library |
| `mentorhub_customer_api` | Domain API |
| `mentorhub_coordinator_api` | Domain API |
| `mentorhub_mentor_api` | Domain API |
| `mentorhub_craftsperson_api` | Domain API |
| `mentorhub_spa_utils` | Shared SPA library |
| `mentorhub_customer_spa` | Domain SPA |
| `mentorhub_coordinator_spa` | Domain SPA |
| `mentorhub_mentor_spa` | Domain SPA |
| `mentorhub_craftsperson_spa` | Domain SPA |
| `mentorhub_mongodb_api` | Data / configurator |
| `mentorhub_runbook_api` | Runbook API |

## Standard rules for `main`

These rules apply to every repository in scope.

### Pull requests

- **Require a pull request before merging** — no direct commits to `main`.
- **Required approving reviews:** 1.
- **Dismiss stale approvals** when new commits are pushed to the PR branch.
- **Require conversation resolution** before merging (recommended).

### Branch integrity

- **Block force pushes** to `main`.
- **Block deletion** of `main`.
- **Require branches to be up to date** before merging (recommended).

### Status checks

- **Require status checks to pass** before merging.
- Required check names are **per repository** (see [Required CI checks](#required-ci-checks)).
- Enable checks only after the corresponding workflow has run successfully on at least one PR.

### Bypass

- **Do not allow bypassing** the above settings, or limit bypass to **organization admins** for documented emergencies only.
- Emergency merges should be rare; follow up with a retrospective PR if code skipped the normal gate.

## Required CI checks

Branch protection can only require checks that run on **open** pull requests. Existing `docker-push.yml` workflows run after merge and are **not** sufficient as merge gates.

### Target checks (once PR CI exists)

| Repository | Required checks (initial) | Follow-up checks |
|------------|---------------------------|------------------|
| `mentorhub_api_utils` | `CI / test` | `CI / lint` |
| `mentorhub_customer_api` | `CI / test` | `CI / lint` |
| `mentorhub_coordinator_api` | `CI / test` | `CI / lint` |
| `mentorhub_mentor_api` | `CI / test` | `CI / lint` |
| `mentorhub_craftsperson_api` | `CI / test` | `CI / lint` |
| `mentorhub_spa_utils` | `CI / test` | `CI / lint` |
| `mentorhub_customer_spa` | `CI / test` | `CI / build` (optional) |
| `mentorhub_coordinator_spa` | `CI / test` | `CI / build` (optional) |
| `mentorhub_mentor_spa` | `CI / test` | `CI / build` (optional) |
| `mentorhub_craftsperson_spa` | `CI / test` | `CI / build` (optional) |
| `mentorhub_mongodb_api` | TBD (e.g. `CI / validate`) | — |
| `mentorhub_runbook_api` | TBD (e.g. `CI / validate`) | — |
| `mentorhub` | TBD (e.g. `CI / verify`) | — |

Check names appear in GitHub as **`CI / <job_name>`** after a workflow named `CI` runs on a PR.

### PR CI prerequisites (not branch protection itself)

Before enabling required checks, each repo needs a `.github/workflows/ci.yml` that:

1. Triggers on `pull_request` and `push` to `main`.
2. Runs the same commands developers use locally (e.g. `pipenv run test`, `npm test`).
3. Does **not** replace `docker-push.yml` — keep post-merge image publishing separate.

**Dependencies:**

- **Python domain APIs** install `api-utils` from `mentorhub_api_utils` via git — CI needs org secret `GH_PAT` (same as container builds).
- **SPAs** install `mentorhub_spa_utils` from GitHub — CI needs token access to that repo.
- **`mentorhub_api_utils`** integration tests need a MongoDB service container in CI; locally use `pipenv run db` and `MONGO_CONNECTION_STRING=mongodb://127.0.0.1:27017` on WSL if `mongodb` does not resolve.

## Configuration options

### Option A — Organization ruleset (recommended)

Use for shared PR and review rules across all `mentorhub_*` repos.

1. **Organization → Settings → Rules → Rulesets → New ruleset**
2. **Target:** repositories matching `mentorhub_*` (or an explicit list).
3. **Branch rules:** apply [Standard rules for `main`](#standard-rules-for-main), except per-repo required status checks.
4. **Required checks:** still configured per repository (check names differ by stack).

### Option B — Per-repository branch protection

Use when rolling out one repo at a time or when org rulesets are unavailable.

1. **Repository → Settings → Branches** (or **Rules → Rulesets**).
2. Add rule for branch name pattern `main`.
3. Apply the same settings as the standard rules above.

## Rollout plan

### Phase 1 — PR CI workflows

Add `ci.yml` to each repository. Verify `CI / test` passes on a test PR before requiring it.

Suggested order: domain APIs → `api_utils` → `spa_utils` → SPAs → make-based repos (`mongodb_api`, `runbook_api`, `mentorhub`).

### Phase 2 — Soft protection

Enable PR + 1 approval on `main` without required status checks yet. Confirms review workflow without blocking on CI gaps.

### Phase 3 — Hard protection

Add required status checks per repo as CI stabilizes. Start with `CI / test` only; add lint/build checks after formatting or build baselines are green.

### Phase 4 — Org ruleset

Consolidate shared rules under one organization ruleset; audit quarterly for drift.

## Verification

After enabling rules on a repository:

- [ ] `git push origin main` is rejected for non-admins.
- [ ] A PR without approval cannot merge.
- [ ] A PR with a failing required check cannot merge.
- [ ] An approved PR with passing checks merges successfully.
- [ ] `docker-push` still runs and publishes images after merge to `main`.

## Roles and responsibilities

| Role | Responsibility |
|------|----------------|
| **Org admin** | Create rulesets, enable protection, grant bypass only when necessary |
| **Repo maintainers** | Add and maintain PR CI workflows; keep required check names documented |
| **Contributors** | Use feature branches and PRs; ensure local tests pass before requesting review |
| **Reviewers** | Approve only when CI is green and changes meet [CONTRIBUTING.md](../../CONTRIBUTING.md) |

## Related standards

- [Branch protection GH CLI implementation plan](./branch_protection_gh_cli_plan.md) — bash script design using `gh api`
- [CONTRIBUTING.md](../../CONTRIBUTING.md) — developer workflow and review expectations
- [SRE Standards](./sre_standards.md) — CI/CD and developer experience
- [API Standards](./api_standards.md) — Python API conventions
- [SPA Standards](./spa_standards.md) — frontend conventions

## Open decisions

Record answers here before enforcement:

- [ ] Org ruleset vs per-repo configuration
- [ ] Phased rollout vs all repos at once
- [ ] Whether to require `CI / lint` on day one or after formatting baselines
- [ ] Whether to add `CODEOWNERS` for automatic reviewer assignment
- [ ] Hotfix procedure when admin bypass is used

## Revision history

| Date | Change |
|------|--------|
| 2026-05-29 | Initial draft |
