# A004 – Make local compose and integration configuration cloud agnostic

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

- Audit COGNITO_* variables currently on Customer API and Admin API and the mock_cognito service. Determine which are used by executable local paths versus placeholders. Remove unused mandatory provider settings; preserve optional local emulator compatibility when useful without requiring AWS accounts/credentials/endpoints.
- Keep local JWT/persona login, configured IDP_LOGIN_URI, tenant/role claims, service profiles, journey base paths and non-AWS mocks working. Reuse existing runtime configuration rather than build an identity provider or per-SPA adapters.
- Coordinate only demonstrated Admin API integration requirements through existing provider-neutral service contracts. Do not alter Customer API code or excluded utility repos merely because compose carries unused variables.
- Put AWS-specific backing-service endpoints, role/secret requirements, identity-provider mapping and deployment overlay guidance under the AWS infrastructure repo. Document future provider repo extension points without creating them.
- No production hosting/IdP selection, live user/data migration, DNS cutover or new schema is required for this local task. If an actual compatibility issue requires more scope, document it for review rather than invent a production implementation.

## Testing Expectations

- During future execution, validate compose configuration and each affected local service profile. Exercise existing local persona login, bootstrap, 401/logout and registration parity flows without live AWS access.
- Use existing welcome-auth tests and the planned provider-neutral-runtime regression test. Verify no aws CLI/account/network dependency and no accidental change to Stripe/mail mocks or MongoDB/Runbook utility behavior.
- Confirm provider-specific deployment configuration is documented as infrastructure-owned, not a required developer setting. Do not wait for a production provider choice.

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
