# A004 – Remove AWS assumptions from the welcome runtime and deployment configuration

**Status**: Pending

**Type**: Feature

**Depends On**: A003

**Description**: Remove active AWS dependencies and coordinate GitHub-hosted utils migration — remove aws assumptions from the welcome runtime and deployment configuration.

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
- `DeveloperEdition/docker-compose.yaml`
- `DeveloperEdition/mh`
- `login.html`
- `welcome-auth.js`
- `nginx.conf`
- `Research/local_dev_mocks.md`
- `tests/welcome-auth.test.js`

Source issue is authoritative for this migration. The agreed migration supersedes old CodeArtifact-auth prerequisites only in the paths explicitly migrated by these tasks; do not rewrite unrelated framework rules.

## Goals

- After the recorded production identity/hosting decision, configure the welcome/runtime entry and Developer Edition compose without active Cognito/AWS service calls. Preserve local persona login, hash bootstrap, roles, stable local JWT secret and journey prefixes.
- Inventory cognito-local and mocks before changing compose: local emulation/history is not proof of an AWS network dependency. Retain or retire each with documented rationale and preserve non-AWS Stripe/mail integrations.
- Document non-AWS production IdP endpoint, claims/signing configuration, provisioning handoff to Admin, data/DNS/TLS transition and rollback. Do not mint production credentials in domain APIs or use the local dev secret in production.
- Do not expand output paths or remove persisted identities/data automatically; any new schema requirements are explicit follow-on work outside excluded utility repos. Stop if the approved runtime decision cannot be implemented within these outputs.

### Craftsmanship Expectations

Keep package, auth and deployment ownership in the existing shared modules. Preserve APIs and runtime contracts unless the recorded migration decision explicitly requires a change; remove obsolete AWS auth knowledge rather than duplicate it. Keep every dependency reference reproducible.

## Testing Expectations

These checks are for future execution; none were run while creating this plan.

- Gate this task on maintainer approval of the recorded runtime decision and Admin/provider readiness. Validate login/logout/401 redirects, claims, registration handoff and existing welcome tests; use non-AWS staging credentials, not live production cutover. Check compose configuration and no live AWS endpoints.

## Outputs

- `DeveloperEdition/docker-compose.yaml`
- `DeveloperEdition/mh`
- `login.html`
- `welcome-auth.js`
- `nginx.conf`
- `Research/local_dev_mocks.md`
- `Research/aws_exit_plan.md`
- `tests/welcome-auth.test.js`
- `tests/provider-neutral-runtime.test.js`

Only these implementation files may change. The orchestrator may also update/rename this task record under the established lifecycle.

## Execution boundary

This is a reviewable plan, not an execution record. Execute only this task's listed outputs when orchestration is separately authorized. Do not touch excluded MongoDB/Runbook utility repos, publish packages/tags, mutate issue/project state, or delete/provision AWS resources as a side effect. Future workflow publication happens only through the reviewed maintainer release path.

Where a task requires an unpublished release, an undecided production contract, unavailable live schema or operator evidence, stop execution at that prerequisite and report it; do not guess values or substitute the unrelated PyPI api-utils package. Pending status describes the plan's review state, not proof that external execution gates are satisfied.

## External prerequisites

Publisher readiness is tracked in https://github.com/mentor-forge/mentorhub_api_utils/issues/36 and https://github.com/mentor-forge/mentorhub_spa_utils/issues/43; AWS inventory/teardown readiness in https://github.com/mentor-forge/mentorhub_cloudformation/issues/12. Track all consumer issues in the source issue checklist. Do not make sibling file changes from this task.

## Execution Notes

Reserved for the execution agent. No implementation, tests, service changes or publication have been performed.
