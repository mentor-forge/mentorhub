# A002 – Make Developer Edition installation and registry auth AWS independent

**Status**: Pending

**Type**: Feature

**Depends On**: A001

**Description**: Remove active AWS dependencies and coordinate GitHub-hosted utils migration — make developer edition installation and registry auth aws independent.

**Issue**: [I-WE01](https://github.com/mentor-forge/mentorhub/issues/80)

## Path anchoring

All output paths are relative to this repository root. Sibling references are read-only context permitted by the repo planning guide.

## Context

- `README.md`
- `tasks/_PLANNING.md`
- `tasks/_ORCHESTRATE.md`
- `../mentorhub/DeveloperEdition/standards/ArchitecturePrinciples.md`
- `../mentorhub/DeveloperEdition/standards/sre_standards.md`
- `CONTRIBUTING.md`
- `CHAT_BEST_PRACTICES.md`
- `Workshops/README.md`
- `../mentorhub_api_utils/README.md`
- `../mentorhub_spa_utils/README.md`
- `Makefile`
- `DeveloperEdition/mh`
- `scripts/install-prereqs.sh`
- `DeveloperEdition/aws-sso-setup.sh`
- `DeveloperEdition/aws-platform.env`
- `DeveloperEdition/scripts/codeartifact-pypi-auth.sh`

Source issue is authoritative for this migration. The agreed migration supersedes old CodeArtifact-auth prerequisites only in the paths explicitly migrated by these tasks; do not rewrite unrelated framework rules.

## Goals

- Remove AWS CLI prerequisite installation, aws-setup, AWS env sourcing/copying and CodeArtifact auth/helper installation from active Makefile and mh paths. Preserve user-managed files and unrelated shell configuration; do not delete ~/.aws or ~/.mentorhub credentials.
- Reuse GITHUB_TOKEN onboarding for GHCR and npm.pkg.github.com with read:packages. Provide host-scoped npm auth via an environment-variable reference, scope only @mentor-forge, retain public npm and preserve GHCR login. Do not write token values into repo files or logs.
- Keep bare mh, make verify/install/update, mh pull/up and clone/build commands usable without AWS CLI, SSO or AWS environment files. Missing GitHub credentials must produce an actionable error, not AWS fallback.
- Retire active DeveloperEdition/aws-sso-setup.sh, DeveloperEdition/aws-platform.env and DeveloperEdition/scripts/codeartifact-pypi-auth.sh only after all consumers stop calling them; retain future AWS instructions through the deferred infrastructure repo, not active bootstrap.

### Craftsmanship Expectations

Keep package, auth and deployment ownership in the existing shared modules. Preserve APIs and runtime contracts unless the recorded migration decision explicitly requires a change; remove obsolete AWS auth knowledge rather than duplicate it. Keep every dependency reference reproducible.

## Testing Expectations

These checks are for future execution; none were run while creating this plan.

- Use shell syntax checks and the new regression test with stubbed external commands and a temporary HOME. Verify no aws invocation, token disclosure or modification of unrelated user files. Test GitHub auth missing/present cases and preserve the existing npm registry for unscoped packages. Do not run installer tests against the real home directory.

## Outputs

- `Makefile`
- `DeveloperEdition/mh`
- `scripts/install-prereqs.sh`
- `DeveloperEdition/aws-sso-setup.sh`
- `DeveloperEdition/aws-platform.env`
- `DeveloperEdition/scripts/codeartifact-pypi-auth.sh`
- `tests/developer-registry-auth.test.js`

Only these implementation files may change. The orchestrator may also update/rename this task record under the established lifecycle.

## Execution boundary

This is a reviewable plan, not an execution record. Execute only this task's listed outputs when orchestration is separately authorized. Do not touch excluded MongoDB/Runbook utility repos, publish packages/tags, mutate issue/project state, or delete/provision AWS resources as a side effect. Future workflow publication happens only through the reviewed maintainer release path.

Where a task requires an unpublished release, an undecided production contract, unavailable live schema or operator evidence, stop execution at that prerequisite and report it; do not guess values or substitute the unrelated PyPI api-utils package. Pending status describes the plan's review state, not proof that external execution gates are satisfied.

## External prerequisites

Publisher readiness is tracked in https://github.com/mentor-forge/mentorhub_api_utils/issues/36 and https://github.com/mentor-forge/mentorhub_spa_utils/issues/43; AWS inventory/teardown readiness in https://github.com/mentor-forge/mentorhub_cloudformation/issues/12. Track all consumer issues in the source issue checklist. Do not make sibling file changes from this task.

## Execution Notes

Reserved for the execution agent. No implementation, tests, service changes or publication have been performed.
