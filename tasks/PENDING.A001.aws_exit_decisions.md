# A001 – Record the AWS exit inventory, decisions and rollout gates

**Status**: Pending

**Type**: Feature

**Depends On**: none

**Description**: Remove active AWS dependencies and coordinate GitHub-hosted utils migration — record the aws exit inventory, decisions and rollout gates.

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

Source issue is authoritative for this migration. The agreed migration supersedes old CodeArtifact-auth prerequisites only in the paths explicitly migrated by these tasks; do not rewrite unrelated framework rules.

## Goals

- Create a repo-owned inventory distinguishing active runtime AWS requirements, local emulators/history, deferred AWS design and package/build coupling. Use current local code, issue descriptions and operator evidence; do not treat the CloudFormation target architecture as proof that a service is deployed.
- Record the agreed Python GitHub Release wheel / GitHub npm split, independent permanent SemVer tags, exact pins and GHCR retention. Mark MongoDB API and Runbook API explicitly out of scope.
- Define the non-AWS production identity/hosting decision gate: issuer/audience/claims and signing, registration/invites, logout, identity preservation, data/DNS/TLS/secrets/observability, owner and rollback. Do not select a provider without a recorded maintainer decision. Development persona tokens are not a production IdP.
- Track all 13 linked migration issues, publisher-before-consumer order, package-only versus runtime cutover gates, evidence and rollback; defer AWS deployment work to I-S01.

### Craftsmanship Expectations

Keep package, auth and deployment ownership in the existing shared modules. Preserve APIs and runtime contracts unless the recorded migration decision explicitly requires a change; remove obsolete AWS auth knowledge rather than duplicate it. Keep every dependency reference reproducible.

## Testing Expectations

These checks are for future execution; none were run while creating this plan.

- Review issue coverage and ownership; distinguish facts from open decisions and require explicit approvals/evidence before runtime cutover or infrastructure deletion.

## Outputs

- `Research/aws_exit_plan.md`

Only these implementation files may change. The orchestrator may also update/rename this task record under the established lifecycle.

## Execution boundary

This is a reviewable plan, not an execution record. Execute only this task's listed outputs when orchestration is separately authorized. Do not touch excluded MongoDB/Runbook utility repos, publish packages/tags, mutate issue/project state, or delete/provision AWS resources as a side effect. Future workflow publication happens only through the reviewed maintainer release path.

Where a task requires an unpublished release, an undecided production contract, unavailable live schema or operator evidence, stop execution at that prerequisite and report it; do not guess values or substitute the unrelated PyPI api-utils package. Pending status describes the plan's review state, not proof that external execution gates are satisfied.

## External prerequisites

Publisher readiness is tracked in https://github.com/mentor-forge/mentorhub_api_utils/issues/36 and https://github.com/mentor-forge/mentorhub_spa_utils/issues/43; AWS inventory/teardown readiness in https://github.com/mentor-forge/mentorhub_cloudformation/issues/12. Track all consumer issues in the source issue checklist. Do not make sibling file changes from this task.

## Execution Notes

Reserved for the execution agent. No implementation, tests, service changes or publication have been performed.
