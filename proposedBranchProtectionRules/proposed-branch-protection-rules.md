# Proposed Branch Protection Rules for mentor-forge

> **Status:** Proposal — not enforced  
> **Organization:** [mentor-forge](https://github.com/mentor-forge)  
> **Date:** 2026-05-29

This document describes proposed branch protection rules for all mentor-forge repositories, how they align with the existing developer workflow, and how a bash script using the GitHub CLI (`gh`) would apply them at org scale.

---

## 1. Background

Mentor-forge already documents the intended workflow in [CONTRIBUTING.md](../CONTRIBUTING.md) and [SRE Standards](../DeveloperEdition/standards/sre_standards.md):

- Work happens on feature branches.
- Changes merge to `main` via pull request (PR).
- A peer reviews and approves before merge.
- Tests pass before merge.
- Merge to `main` triggers existing `docker-push.yml` workflows that build and publish container images.

Today these expectations are **documented but not enforced**. Direct pushes to `main` are still possible, and there are no required CI checks on open PRs (existing workflows run primarily **after** merge).

Branch protection rules would turn this workflow into a technical gate in GitHub.

---

## 2. Proposed rules for `main`

These rules would apply to the `main` branch in every repository listed in [Section 4](#4-repository-scope).

### Pull requests

| Rule | Setting | Rationale |
|------|---------|-----------|
| Require pull request before merging | Yes | Matches CONTRIBUTING; blocks direct commits |
| Required approving reviews | **1** | Matches documented peer-review expectation |
| Dismiss stale approvals | Yes | New commits require fresh review |
| Require conversation resolution | Yes (recommended) | Review threads must be resolved before merge |

### Branch integrity

| Rule | Setting |
|------|---------|
| Block force pushes | Yes |
| Block branch deletion | Yes |
| Require branch up to date before merging | Yes (recommended) |

### Status checks

| Rule | Setting |
|------|---------|
| Require status checks to pass | Yes — per repository (see [Section 5](#5-pr-ci-prerequisites)) |
| Check naming convention | `CI / <job_name>` (e.g. `CI / test`, `CI / lint`) |

Status checks can only be required **after** a PR CI workflow has run at least once and GitHub has registered the check names. Existing `docker-push.yml` workflows are post-merge and cannot serve as merge gates.

### Bypass

| Rule | Setting |
|------|---------|
| Who can bypass | **Organization admins only** |
| When | Documented emergencies (hotfix) |
| Follow-up | Retrospective PR if normal gates were skipped |

---

## 3. Architecture: org ruleset + per-repo checks

At org scale, configuration is split into two layers rather than editing 13 repositories by hand.

```
┌──────────────────────────────────────────────────────────────┐
│  Organization ruleset (mentor-forge)                         │
│  Name: "mentor-forge main (base)"                            │
│  Targets: repository_name ~ mentorhub_*                      │
│  Branch: refs/heads/main                                     │
│                                                              │
│  Rules:                                                      │
│    • Pull request + 1 approval + stale dismiss               │
│    • Block force push and deletion                           │
│    • Require branch up to date                               │
│    • Bypass: OrganizationAdmin only                          │
└──────────────────────────────────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         ▼                     ▼                     ▼
  Repo ruleset            Repo ruleset           Repo ruleset
  "mentor-forge main      (one per repo)         ...
   (required checks)"
  Rules:
    • required_status_checks: CI / test, ...
```

**Why two layers?**

- **Org ruleset** — one place for shared PR and review policy across all `mentorhub_*` repos.
- **Per-repo rulesets** — required status checks can be rolled out gradually (e.g. add `CI / lint` only after formatting baselines pass).

---

## 4. Repository scope

All 13 mentor-forge repositories on `main`:

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

---

## 5. PR CI prerequisites

Branch protection cannot require checks that do not exist. Each repo needs a **separate** `.github/workflows/ci.yml` that runs on open PRs. Post-merge `docker-push.yml` stays unchanged.

| Repo group | Count | Proposed PR checks | Notes |
|------------|-------|-------------------|-------|
| Domain APIs | 4 | `pipenv run test`, `pipenv run lint` | Mongo mocked in tests; no DB service in CI |
| `mentorhub_api_utils` | 1 | `test`, `lint` | MongoDB service container in CI |
| Domain SPAs | 4 | `npm test`; optionally `npm run build` | Needs token to install `mentorhub_spa_utils` from GitHub |
| `mentorhub_spa_utils` | 1 | `npm test`, `npm run lint` | Upstream dependency for SPAs |
| `mentorhub_mongodb_api` | 1 | e.g. `make container` | Validate configs / image build |
| `mentorhub_runbook_api` | 1 | e.g. `make container` | Make-based validation |
| `mentorhub` | 1 | e.g. `make verify` | Umbrella compose / tooling check |

### Target required checks (hard → full rollout)

| Repository | Phase: hard | Phase: full |
|------------|-------------|-------------|
| Domain APIs (×4) | `CI / test` | `CI / test`, `CI / lint` |
| `mentorhub_api_utils` | `CI / test` | `CI / test`, `CI / lint` |
| `mentorhub_spa_utils` | `CI / test` | `CI / test`, `CI / lint` |
| Domain SPAs (×4) | `CI / test` | `CI / test`, `CI / build` (optional) |
| `mentorhub_mongodb_api` | `CI / validate` | `CI / validate` |
| `mentorhub_runbook_api` | `CI / validate` | `CI / validate` |
| `mentorhub` | `CI / verify` | `CI / verify` |

---

## 6. Bash script approach (GitHub CLI)

Rather than configuring each repository manually in the GitHub UI, mentor-forge would use a **bash script** that calls the GitHub API through [`gh`](https://cli.github.com/).

### Why bash + `gh`?

| Benefit | Explanation |
|---------|-------------|
| Repeatable | Same policy applied consistently across 13 repos |
| Auditable | `audit` mode reports current state before any change |
| Idempotent | Re-runs update existing rulesets by name instead of duplicating |
| Phased | `--phase soft` vs `--phase hard` supports gradual rollout |
| Operator-friendly | No raw JSON editing in the GitHub UI for every repo |

### Script location

```
mentorhub/DeveloperEdition/scripts/branch-protection/
  configure-branch-protection.sh    # entrypoint
  lib/
    common.sh                       # logging, config, gh helpers
    audit.sh                        # read-only state report
    org-ruleset.sh                  # org ruleset apply (planned)
    repo-ruleset.sh                 # per-repo checks apply (planned)
    verify.sh                       # post-apply validation (planned)
  config/
    repos.json                      # repo inventory + checks per phase
    org-ruleset.base.json           # org ruleset payload template
    repo-ruleset.checks.json        # per-repo checks payload template
  README.md
```

### Subcommands (planned)

| Command | Purpose | Status |
|---------|---------|--------|
| `audit` | Read-only report: rulesets, `ci.yml` presence, observed checks, readiness | **Implemented** |
| `plan` | Show what would change (`--dry-run`) | Planned |
| `apply --phase soft` | Create org ruleset (PR + review, no CI gates) | Planned |
| `apply --phase hard` | Add per-repo required checks (`CI / test`) | Planned |
| `apply --phase full` | Add lint/build checks where configured | Planned |
| `verify` | Confirm rules are active after apply | Planned |

### Example usage

From the `mentorhub` repository root:

```bash
# Read-only assessment (safe to run now)
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit

# One repo or group
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit --repo mentorhub_customer_api
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit --group domain_api

# Fail if repos are not ready for hard protection
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit --phase hard --strict

# Future: apply soft protection (org admin)
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase soft --dry-run
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase soft
```

### Prerequisites for operators

```bash
gh auth login          # org admin recommended
gh auth status
# also required: jq
```

Configuration is driven by `config/repos.json` (organization name, all 13 repos, and check names per rollout phase).

### Audit output (current state as of 2026-05-29)

A live `audit --phase soft` run reported:

- Org ruleset `mentor-forge main (base)`: **not present**
- All 13 repos: **no `ci.yml`**, **no rulesets**, **no legacy branch protection**
- Soft-phase readiness: **yes** (no CI checks required in soft phase)

---

## 7. Proposed rollout

| Phase | Action | Branch protection |
|-------|--------|-------------------|
| **0** | Build script; run `audit` | None |
| **1** | `apply --phase soft` | Org ruleset: PR + 1 review, no force-push |
| **2** | Add `ci.yml` to each repo (separate PRs) | Unchanged |
| **3** | `apply --phase hard` | Per-repo `CI / test` required |
| **4** | `apply --phase full` | Add `CI / lint` / `CI / build` where ready |

Suggested CI implementation order: domain APIs → `api_utils` → `spa_utils` → SPAs → make-based repos.

---

## 8. Verification checklist

After rules are applied, each repository should satisfy:

- [ ] Direct `git push origin main` is rejected for non-admins.
- [ ] A PR without approval cannot merge.
- [ ] A PR with a failing required check cannot merge (hard phase onward).
- [ ] An approved PR with passing checks merges successfully.
- [ ] `docker-push.yml` still runs and publishes images after merge to `main`.

The script's future `verify` subcommand would automate checks where possible (`gh ruleset check main --repo mentor-forge/<repo>`).

---

## 9. Open decisions

Before enforcement, org admins should confirm:

- [ ] Phased rollout vs big-bang across all repos
- [ ] Org ruleset vs per-repo configuration for shared PR rules (**recommend org ruleset**)
- [ ] Whether to require `CI / lint` on day one or after formatting baselines
- [ ] Whether to add `CODEOWNERS` for automatic reviewer assignment
- [ ] Documented hotfix procedure when admin bypass is used

---

## 10. Related material

| Document | Location |
|----------|----------|
| Branch protection standards (draft) | `DeveloperEdition/standards/branch_protection_standards.md` |
| GH CLI implementation plan | `DeveloperEdition/standards/branch_protection_gh_cli_plan.md` |
| Branch protection script | `DeveloperEdition/scripts/branch-protection/` |
| Contributor workflow | `CONTRIBUTING.md` |

---

## 11. Summary

The proposal is to enforce mentor-forge's existing PR-and-review workflow on `main` across all 13 repositories using **GitHub organization and repository rulesets**, applied by a **bash script** that uses `gh api`. Shared review rules live in one org ruleset; required CI checks are added per repo after PR workflows exist. Rollout is intentionally phased: review gates first, then test gates, then lint/build gates.

Nothing in this proposal is active until org admins run `apply` and CI workflows are merged to each repository.
