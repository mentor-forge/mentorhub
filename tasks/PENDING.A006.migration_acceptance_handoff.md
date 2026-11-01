# A006 – Record coordinated cutover, rollback and infrastructure handoff

**Status**: Pending

**Type**: Feature

**Depends On**: A005

**Description**: Remove active AWS dependencies and coordinate GitHub-hosted utils migration — record coordinated cutover, rollback and infrastructure handoff.

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
- `Specifications/roadmap.yaml`

Source issue is authoritative for this migration. The agreed migration supersedes old CodeArtifact-auth prerequisites only in the paths explicitly migrated by these tasks; do not rewrite unrelated framework rules.

## Goals

- Collect verified package asset names/versions/hashes, consumer lock versions, clean Docker/CI evidence and non-AWS runtime/auth evidence for each in-scope repo; record unresolved items instead of declaring them complete.
- Confirm all five API/five SPA migrations and both publishers are ready before retiring shared auth helpers permanently. Existing unrelated pending tasks are not part of this feature.
- Require I-S01 inventory and backup/restore validation, approved replacement service cutover and separate teardown approval before infrastructure retirement. Preserve AWS provisioning reference and CodeArtifact future bootstrap.
- Describe rollback to prior pinned GitHub-hosted packages/images and runtime routing; explicitly identify irreversible identity/data boundaries. Keep GitHub issues/project statuses unchanged unless separately authorized.

### Craftsmanship Expectations

Keep package, auth and deployment ownership in the existing shared modules. Preserve APIs and runtime contracts unless the recorded migration decision explicitly requires a change; remove obsolete AWS auth knowledge rather than duplicate it. Keep every dependency reference reproducible.

## Testing Expectations

These checks are for future execution; none were run while creating this plan.

- Review checklist against all linked issues. From the platform root plan make update / mh up all and cross-journey smoke tests on the approved non-AWS environment; do not execute production cutover or AWS deletion. Verify MongoDB/Runbook repos remain untouched.

## Outputs

- `Research/aws_exit_plan.md`
- `Specifications/roadmap.yaml`

Only these implementation files may change. The orchestrator may also update/rename this task record under the established lifecycle.

## Execution boundary

This is a reviewable plan, not an execution record. Execute only this task's listed outputs when orchestration is separately authorized. Do not touch excluded MongoDB/Runbook utility repos, publish packages/tags, mutate issue/project state, or delete/provision AWS resources as a side effect. Future workflow publication happens only through the reviewed maintainer release path.

Where a task requires an unpublished release, an undecided production contract, unavailable live schema or operator evidence, stop execution at that prerequisite and report it; do not guess values or substitute the unrelated PyPI api-utils package. Pending status describes the plan's review state, not proof that external execution gates are satisfied.

## External prerequisites

Publisher readiness is tracked in https://github.com/mentor-forge/mentorhub_api_utils/issues/36 and https://github.com/mentor-forge/mentorhub_spa_utils/issues/43; AWS inventory/teardown readiness in https://github.com/mentor-forge/mentorhub_cloudformation/issues/12. Track all consumer issues in the source issue checklist. Do not make sibling file changes from this task.

## Execution Notes

Reserved for the execution agent. No implementation, tests, service changes or publication have been performed.
