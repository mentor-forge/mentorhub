# Plan: GitHub CLI branch protection script for mentor-forge

> **Status:** Phase 0 implemented (`audit`); `apply` / `plan` / `verify` pending  
> **Relates to:** [branch_protection_standards.md](./branch_protection_standards.md)

This document describes how to build a bash script that uses the [GitHub CLI](https://cli.github.com/) (`gh`) to apply mentor-forge branch protection policy at org scale. The script configures **GitHub rulesets**; it does **not** create PR CI workflows (`ci.yml`). Those are a prerequisite for the “hard” phase.

---

## Goals

| In scope | Out of scope |
|----------|--------------|
| Apply org-wide ruleset for shared `main` branch policy | Authoring or merging `ci.yml` into each repo |
| Apply per-repo required status checks (phase 3) | Replacing or modifying `docker-push.yml` |
| Audit current protection state | Terraform / GitHub App |
| Dry-run and verify modes | Non-`main` branches |

---

## Architecture

Use a **two-layer** model. One org ruleset cannot express per-repo CI differences cleanly if check names diverge, but mentor-forge standardizes on workflow name `CI` and jobs `test` / `lint` / `validate` / `verify`, so check names like `CI / test` are consistent across repos.

```
┌─────────────────────────────────────────────────────────────┐
│  Org ruleset (mentor-forge)                                 │
│  Target: repository_name ~ mentorhub_*                      │
│  Branch: refs/heads/main                                    │
│  Rules: PR + 1 approval, stale dismiss, no force-push,      │
│         no delete, (optional) strict update                  │
│  Bypass: OrganizationAdmin only                             │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   repo ruleset          repo ruleset        repo ruleset
   (hard phase)           (hard phase)        (hard phase)
   required_status_      required_status_    ...
   checks: CI / test     checks: CI / test
```

### Recommended split

| Phase | What the script applies | Status checks |
|-------|-------------------------|---------------|
| **Soft** | Org ruleset only | None |
| **Hard** | Org ruleset unchanged + per-repo ruleset **or** org ruleset updated | `CI / test` (then `CI / lint` per repo when ready) |

**Why per-repo rulesets for checks (hard phase):** Safer phased rollout — enable `CI / lint` on domain APIs only after formatting baselines pass, without blocking repos that are not ready.

Alternative: single org ruleset with only `CI / test` once **all** repos have green CI (big-bang).

---

## Script location and layout

```
mentorhub/
  DeveloperEdition/
    scripts/
      branch-protection/
        configure-branch-protection.sh   # main entrypoint
        lib/
          common.sh                      # logging, gh auth, json helpers
          audit.sh                       # read current state
          org-ruleset.sh                 # create/update org ruleset
          repo-ruleset.sh                # per-repo status-check rulesets
          verify.sh                      # post-apply checks
        config/
          repos.json                     # repo inventory + check names
          org-ruleset.base.json          # org ruleset payload template
          repo-ruleset.checks.json       # per-repo checks payload template
        README.md                        # operator runbook
```

Add a `make` target or document invocation from `CONTRIBUTING.md` after implementation:

```bash
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase soft --dry-run
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase soft
```

---

## Prerequisites

### Operator

- [ ] `gh` installed (`gh --version`)
- [ ] `gh auth login` with **org admin** scope (`admin:org`, `repo`)
- [ ] `jq` installed
- [ ] Organization: `mentor-forge` (or override via `--org`)

### Policy decisions (document before first `apply`)

- [ ] Rollout: **phased** (soft → hard per repo) vs **big-bang**
- [ ] Bypass: **OrganizationAdmin** only
- [ ] Require branches up to date: **yes**
- [ ] Require conversation resolution: **yes** (recommended)

### CI prerequisites (before `--phase hard`)

Each repo must have `.github/workflows/ci.yml` on `main`, and at least one successful PR run so GitHub registers check names.

| Repo group | CI jobs | Notes |
|------------|---------|-------|
| 4 domain APIs | `test`, `lint` | `GH_PAT` for `mentorhub_api_utils` git dep |
| `mentorhub_api_utils` | `test`, `lint` | MongoDB service container |
| `mentorhub_spa_utils` | `test`, `lint` | — |
| 4 SPAs | `test`, (`build`) | Token for `mentorhub_spa_utils` install |
| `mentorhub_mongodb_api` | `validate` | e.g. `make container` |
| `mentorhub_runbook_api` | `validate` | e.g. `make container` |
| `mentorhub` | `verify` | e.g. `make verify` |

The script **`audit`** subcommand should warn when required checks are not yet observed on a repo.

---

## Configuration file: `config/repos.json`

Single source of truth for repo names and required checks per phase.

```json
{
  "organization": "mentor-forge",
  "default_branch": "main",
  "repository_name_pattern": "mentorhub_*",
  "repos": [
    {
      "name": "mentorhub_customer_api",
      "group": "domain_api",
      "checks_soft": [],
      "checks_hard": ["CI / test"],
      "checks_full": ["CI / test", "CI / lint"]
    },
    {
      "name": "mentorhub_api_utils",
      "group": "api_utils",
      "checks_soft": [],
      "checks_hard": ["CI / test"],
      "checks_full": ["CI / test", "CI / lint"]
    }
  ]
}
```

Script flags:

- `--phase soft|hard|full` — maps to `checks_soft`, `checks_hard`, `checks_full`
- `--repo mentorhub_customer_api` — limit to one repo
- `--group domain_api` — limit to a group
- `--dry-run` — print `gh api` payloads, do not POST/PUT
- `--force` — update existing ruleset by name (idempotent apply)

---

## GitHub API mapping (`gh api`)

All mutations go through `gh api` (ruleset create/update are not fully exposed as `gh ruleset` subcommands beyond list/view/check).

### Auth and org verification

```bash
gh auth status
gh api user -q .login
gh api orgs/mentor-forge -q .login
```

### Audit commands

```bash
# Org rulesets
gh api orgs/mentor-forge/rulesets

# Per-repo rulesets
gh api repos/mentor-forge/mentorhub_customer_api/rulesets

# Legacy branch protection (if present — script should report and optionally migrate)
gh api repos/mentor-forge/mentorhub_customer_api/branches/main/protection 2>/dev/null || true

# Recent check runs on default branch (discover actual check names)
gh api repos/mentor-forge/mentorhub_customer_api/commits/main/check-runs --paginate \
  -q '.check_runs[] | select(.name | startswith("CI /")) | .name' | sort -u

# List org repos matching pattern
gh repo list mentor-forge --limit 200 --json name -q '.[].name' | grep '^mentorhub'
```

### Create org ruleset (soft phase)

`POST /orgs/{org}/rulesets`

Payload template (`config/org-ruleset.base.json`):

```json
{
  "name": "mentor-forge main (base)",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "repository_name": {
      "include": ["mentorhub_*"],
      "exclude": []
    },
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "deletion"
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "update",
      "parameters": {
        "update_allows_fetch_and_merge": false
      }
    }
  ],
  "bypass_actors": [
    {
      "actor_type": "OrganizationAdmin",
      "bypass_mode": "always"
    }
  ]
}
```

Apply:

```bash
gh api --method POST orgs/mentor-forge/rulesets --input config/org-ruleset.base.json
```

**Idempotency:** `GET orgs/mentor-forge/rulesets`, find by `name`, then `PUT orgs/mentor-forge/rulesets/{id}` if exists.

### Create per-repo ruleset (hard phase)

`POST /repos/{owner}/{repo}/rulesets`

```json
{
  "name": "mentor-forge main (required checks)",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "CI / test" }
        ]
      }
    }
  ],
  "bypass_actors": [
    {
      "actor_type": "OrganizationAdmin",
      "bypass_mode": "always"
    }
  ]
}
```

Build `required_status_checks` array dynamically from `repos.json` for the selected `--phase`.

### Ruleset evaluation (verify)

```bash
gh ruleset check main --repo mentor-forge/mentorhub_customer_api
```

---

## Script subcommands

### `audit`

1. Confirm `gh` auth and org admin capability.
2. List all repos in `repos.json`; flag missing repos or extras in org.
3. For each repo:
   - List rulesets and summarize enforced rules.
   - List legacy branch protection if any.
   - Query latest `CI / *` check names on `main` or latest PR.
4. Print table: repo | rulesets | checks found | checks required (config) | ready for hard?
5. Exit non-zero if `--strict` and any repo is not ready.

### `apply --phase soft`

1. Load `org-ruleset.base.json`.
2. Create or update org ruleset `mentor-forge main (base)`.
3. Do **not** add `required_status_checks`.
4. Print summary and `verify` hints.

### `apply --phase hard|full`

1. Run `audit --strict` (optional flag `--skip-audit` for emergencies).
2. For each selected repo, create or update repo ruleset `mentor-forge main (required checks)` with checks from config.
3. Do not remove org base ruleset.

### `apply --phase full`

Same as hard but use `checks_full` (includes `CI / lint`).

### `verify`

1. For each repo, run `gh ruleset check main --repo mentor-forge/$repo`.
2. Optionally open a probe PR via `gh pr create` in a test branch (manual doc step).
3. Print pass/fail checklist from [branch_protection_standards.md](./branch_protection_standards.md#verification).

### `plan`

Print what would be applied (human-readable diff vs current state). Default for `--dry-run`.

---

## Implementation phases

### Phase 0 — Script skeleton (1 PR)

- [ ] Add directory layout under `DeveloperEdition/scripts/branch-protection/`
- [ ] `common.sh`: `die`, `info`, `require_cmd`, `gh_org`, `load_config`
- [ ] `configure-branch-protection.sh` argument parsing (`audit`, `apply`, `verify`, `plan`)
- [ ] `config/repos.json` with all 13 repos
- [ ] `README.md` operator runbook
- [ ] `audit` read-only against live org (safe to run immediately)

### Phase 1 — Org soft protection (1 PR + admin run)

- [ ] Implement `org-ruleset.sh` create/update idempotently
- [ ] `apply --phase soft --dry-run` reviewed by org admin
- [ ] `apply --phase soft` executed in production
- [ ] `verify` confirms PR required, direct push blocked

### Phase 2 — PR CI workflows (13 PRs, separate from script)

Tracked in repo work, not in this script:

- [ ] Add `ci.yml` per repo type (see standards doc)
- [ ] Confirm `CI / test` green on a test PR in each repo
- [ ] `audit` shows all repos “ready for hard”

### Phase 3 — Hard protection (script + admin run)

- [ ] Implement `repo-ruleset.sh`
- [ ] `apply --phase hard --dry-run`
- [ ] `apply --phase hard` per repo or `--group` rollout
- [ ] `verify` on each repo

### Phase 4 — Full checks (optional)

- [ ] Formatting/build baselines merged where needed
- [ ] `apply --phase full` for `CI / lint` / `CI / build`

---

## Idempotency and safety

| Concern | Approach |
|---------|----------|
| Re-running script | Upsert by ruleset `name`; never duplicate rulesets |
| Wrong org | Require `--org` default from `repos.json`; confirm prompt unless `--yes` |
| Missing checks | `audit --strict` blocks hard apply |
| Dry-run | No `POST`/`PUT`; print JSON and curl/gh equivalents |
| Rollback | `DELETE /orgs/{org}/rulesets/{id}` or set `enforcement: disabled` — document in README |
| Legacy branch protection | `audit` reports; optionally `DELETE` legacy rule if conflicting |

---

## Bash implementation notes

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config/repos.json — load via jq, not source
source "${SCRIPT_DIR}/lib/common.sh"

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    audit)   audit_main "$@" ;;
    apply)   apply_main "$@" ;;
    verify)  verify_main "$@" ;;
    plan)    plan_main "$@" ;;
    *)       usage ;;
  esac
}
```

- Use `jq` for all JSON assembly; avoid heredoc JSON in bash for complex payloads.
- `ruleset_upsert_org()` / `ruleset_upsert_repo()`: GET list → filter by name → PUT or POST.
- Log all API calls to stderr; write optional `--log-file` for audit trail.

---

## Testing the script

| Test | Method |
|------|--------|
| Unit | ShellCheck on all `*.sh` in CI for `mentorhub` repo |
| Dry-run | `apply --dry-run` produces valid JSON (validate with `jq`) |
| Integration | Run `audit` against mentor-forge (read-only) |
| Staging | If org has a test repo `mentorhub_sandbox`, apply soft rules there first |
| Regression | `verify` after apply on one pilot repo (`mentorhub_customer_api`) |

---

## Operator runbook (summary)

```bash
cd mentorhub/DeveloperEdition/scripts/branch-protection

# 1. Read-only assessment
./configure-branch-protection.sh audit

# 2. Preview org rules
./configure-branch-protection.sh plan --phase soft

# 3. Apply review-only protection (no CI gates yet)
./configure-branch-protection.sh apply --phase soft --dry-run
./configure-branch-protection.sh apply --phase soft

# 4. After all ci.yml PRs merged and green
./configure-branch-protection.sh audit --strict
./configure-branch-protection.sh apply --phase hard --dry-run
./configure-branch-protection.sh apply --phase hard

# 5. Confirm
./configure-branch-protection.sh verify
```

---

## Open questions

| Question | Default recommendation |
|----------|------------------------|
| Org ruleset vs 13 repo rulesets for PR rules? | **Org ruleset** for shared rules |
| Per-repo rulesets for checks vs one org check rule? | **Per-repo** for phased lint rollout |
| Remove legacy branch protection? | **Report only** in v1; add `--migrate` in v2 |
| `repository_name` pattern `mentorhub_*` | Confirm in audit; fall back to explicit repo list in config |
| GitHub Enterprise vs github.com | Add `--hostname` flag if needed later |

---

## Success criteria

- [ ] One command applies soft protection to all `mentorhub_*` repos
- [ ] One command applies hard protection per repo or group with config-driven checks
- [ ] `audit` clearly shows drift and CI readiness
- [ ] Script is idempotent and safe to re-run
- [ ] Operator README requires no knowledge of raw GitHub API payloads
- [ ] Aligns with [branch_protection_standards.md](./branch_protection_standards.md)

---

## Revision history

| Date | Change |
|------|--------|
| 2026-05-29 | Initial plan |
