# A003 – Document the new package, release, CI and onboarding standards

**Status**: Pending

**Type**: Feature

**Depends On**: A002

**Description**: Remove active AWS dependencies and coordinate GitHub-hosted utils migration — document the new package, release, ci and onboarding standards.

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
- `DeveloperEdition/standards/ArchitecturePrinciples.md`
- `DeveloperEdition/standards/api_standards.md`
- `DeveloperEdition/standards/spa_standards.md`
- `DeveloperEdition/standards/sre_standards.md`
- `DeveloperEdition/standards/system_tour.md`
- `DeveloperEdition/standards/examples/docker-push.yml`
- `DeveloperEdition/standards/examples/docker-push-codeartifact.yml`

Source issue is authoritative for this migration. The agreed migration supersedes old CodeArtifact-auth prerequisites only in the paths explicitly migrated by these tasks; do not rewrite unrelated framework rules.

## Goals

- Replace active CodeArtifact/SSO dependency instructions with exact Release-wheel Pipfile examples and GitHub npm exact-version examples. Public Python wheel downloads need no token; npm downloads need read:packages.
- Define maintainer merge/tag/release gates, immutable tags/artifacts, version agreement, package contents, consumer locks and rollback. Preserve the warning about unrelated public PyPI api-utils.
- Provide AWS-free journey workflow examples with correct GitHub permissions and BuildKit npm secrets. Keep image publishing push-to-main only; PR validation, where added, is separate and never publishes. Remove obsolete AWS OIDC/id-token permissions from active examples, not GHCR publishing.
- Make production requirements provider-neutral while pointing deferred AWS-specific design/provisioning, including CodeArtifact, to I-S01. Preserve historical research/task records and the current issue-naming conventions.

### Craftsmanship Expectations

Keep package, auth and deployment ownership in the existing shared modules. Preserve APIs and runtime contracts unless the recorded migration decision explicitly requires a change; remove obsolete AWS auth knowledge rather than duplicate it. Keep every dependency reference reproducible.

## Testing Expectations

These checks are for future execution; none were run while creating this plan.

- Review links, examples, workflow syntax and least-privilege scopes. Search active docs for stale mandatory AWS auth; allow explicitly deferred/history references. Only update the dependency-auth section of _PLANNING.md, not run-specific framework content.

## Outputs

- `CONTRIBUTING.md`
- `README.md`
- `DeveloperEdition/standards/ArchitecturePrinciples.md`
- `DeveloperEdition/standards/api_standards.md`
- `DeveloperEdition/standards/spa_standards.md`
- `DeveloperEdition/standards/sre_standards.md`
- `DeveloperEdition/standards/system_tour.md`
- `DeveloperEdition/standards/examples/docker-push.yml`
- `DeveloperEdition/standards/examples/docker-push-codeartifact.yml`
- `tasks/_PLANNING.md`

Only these implementation files may change. The orchestrator may also update/rename this task record under the established lifecycle.

## Execution boundary

This is a reviewable plan, not an execution record. Execute only this task's listed outputs when orchestration is separately authorized. Do not touch excluded MongoDB/Runbook utility repos, publish packages/tags, mutate issue/project state, or delete/provision AWS resources as a side effect. Future workflow publication happens only through the reviewed maintainer release path.

Where a task requires an unpublished release, unavailable live schema or operator evidence, stop execution at that prerequisite and report it; do not guess values or substitute the unrelated PyPI api-utils package. Pending status describes the plan's review state, not proof that external execution gates are satisfied.

## External prerequisites

Publisher readiness is tracked in https://github.com/mentor-forge/mentorhub_api_utils/issues/36 and https://github.com/mentor-forge/mentorhub_spa_utils/issues/43; AWS inventory/teardown readiness in https://github.com/mentor-forge/mentorhub_cloudformation/issues/12. Track all consumer issues in the source issue checklist. Do not make sibling file changes from this task.

## Cloud-agnostic deployment boundary

The deliverable is a cloud-agnostic **local** deployment plus the agreed GitHub dependency/build migration. Existing identity/hosting implementations are largely placeholders: audit actual executable dependencies before proposing changes. Selecting, implementing or migrating to a production IdP/hosting provider is not a prerequisite for library releases, journey package/build/CI changes or local acceptance.

Keep application-facing backing-service contracts and environment settings provider neutral. Concentrate necessary integration changes in Admin API and DeveloperEdition/docker-compose.yaml where inspection proves coupling; preserve the existing shared JWT/redirect contracts and local persona/mocked-service behavior. Do not create per-journey provider adapters, new identity schemas or a general multi-cloud framework speculatively.

Cloud-specific provisioning, backing-service configuration, identity-provider wiring, roles/secrets and deployment overlays belong to the relevant infrastructure repo: mentorhub_cloudformation owns AWS, including future CodeArtifact provisioning. Future separate repos may implement Google, Microsoft/Azure, IBM or Red Hat platforms against the same contracts; do not create or implement them in this effort. Core compose must not require AWS accounts, credentials or endpoints. A locally optional emulator is not a live AWS dependency; retain it only if useful without making it a required cloud-specific integration.

AWS inventory, secure backup/restore evidence and separately approved decommissioning remain I-S01 responsibilities. Production provider selection or a live production cutover is future infrastructure/integration work, not an acceptance gate for the cloud-agnostic local stack.

## Execution Notes

Reserved for the execution agent. No implementation, tests, service changes or publication have been performed.
