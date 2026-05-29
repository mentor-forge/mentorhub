# Branch protection CLI (mentor-forge)

Bash tooling to audit, apply, and verify GitHub rulesets for mentor-forge repositories.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated with **org admin** access to `mentor-forge`
- `jq`

```bash
gh auth login
gh auth status
```

## Commands

| Command | Description |
|---------|-------------|
| `audit` | Read-only state report |
| `plan --phase <phase>` | Preview ruleset changes (dry-run) |
| `apply --phase <phase>` | Create or update rulesets |
| `verify` | Confirm rulesets are active |

### Phases

| Phase | What it applies |
|-------|-----------------|
| `soft` | Org ruleset: PR + 1 approval, stale dismiss, no force-push/delete |
| `hard` | Per-repo rulesets requiring `checks_hard` (e.g. `CI / test`) |
| `full` | Per-repo rulesets requiring `checks_full` (e.g. `CI / lint`) |

## Quick start

From the `mentorhub` repository root:

```bash
# Assess current state
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit

# Preview soft protection (org-wide review gates)
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh plan --phase soft

# Apply soft protection
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase soft --yes

# After PR ci.yml exists in each repo and checks are green
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit --phase hard --strict
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase hard --yes

# Confirm rules are active
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh verify
```

Filter to one repo or group:

```bash
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh apply --phase hard --repo mentorhub_customer_api --yes
./DeveloperEdition/scripts/branch-protection/configure-branch-protection.sh audit --group domain_api
```

## Options

| Flag | Commands | Purpose |
|------|----------|---------|
| `--phase` | plan, apply | `soft`, `hard`, or `full` (required) |
| `--dry-run` | apply | Print payloads without calling GitHub API |
| `--yes` | apply | Skip confirmation prompt |
| `--skip-audit` | apply | Skip pre-apply readiness check (hard/full) |
| `--strict` | audit | Exit non-zero if repos are not ready |
| `--group` | all | Limit to a repo group in `config/repos.json` |
| `--repo` | all | Limit to a single repository |
| `--org` | all | Override organization (default: `mentor-forge`) |

## Configuration

| File | Purpose |
|------|---------|
| `config/repos.json` | All 13 repos, groups, and required checks per phase |
| `config/org-ruleset.base.json` | Org-wide soft protection payload |
| `config/repo-ruleset.checks.json` | Per-repo required-checks payload template |

## Architecture

1. **Org ruleset** (`mentor-forge main (base)`) — shared PR and review rules on all `mentorhub*` repos (including the `mentorhub` umbrella).
2. **Per-repo rulesets** (`mentor-forge main (required checks)`) — required CI status checks for hard/full phases.

The script is idempotent: re-running `apply` updates existing rulesets by name.

## Related docs

- [Proposed branch protection rules](../../../proposedBranchProtectionRules/proposed-branch-protection-rules.md)
- [Branch protection standards](../../standards/branch_protection_standards.md)
- [GH CLI implementation plan](../../standards/branch_protection_gh_cli_plan.md)
