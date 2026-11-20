# MentorHub AWS exit plan

[I-WE01](https://github.com/mentor-forge/mentorhub/issues/80) covers Developer Edition, dependency distribution and CI. MentorHub owns provider-neutral application contracts and local Compose. [MentorHub CloudFormation](https://github.com/mentor-forge/mentorhub_cloudformation) owns AWS provisioning, backing-service configuration, identity wiring, IAM, secrets and deployment overlays, including reproducible CodeArtifact provisioning. This work leaves production provider selection, production identity/data migration and DNS cutover for future infrastructure work.

## Dependency inventory

| Area | Current coupling | Planned change |
| --- | --- | --- |
| Developer tooling | The Makefile verifies AWS CLI/CodeArtifact, installs the platform env and shared Python auth helper, and exposes `aws-setup`. The `mh` registry path calls AWS STS, SSO and CodeArtifact before container commands. | A002 removes active AWS onboarding and auth. Keep GitHub Container Registry login and use scoped GitHub npm authentication. Preserve existing user-managed credentials and configuration. |
| Package installs and CI | In-scope journeys use CodeArtifact-backed Python or npm dependencies and the standards describe AWS authentication and OIDC. | Publisher issues release GitHub-hosted packages first. Consumers replace private registry prerequisites, regenerate locks, and validate clean installs and builds. A003 updates active standards and onboarding. |
| Welcome build | The current publishing workflow uses GitHub Container Registry and passes a GitHub token as a build argument. | A005 audits and removes the unused argument while retaining multi-platform publishing on pushes to main. Validate PRs separately without publishing. A007 verifies the patched packaged Nginx image on both architectures. |
| Local identity | Compose sets `COGNITO_*` values for Customer and Admin APIs and starts `mock_cognito` in several profiles. The checked Customer and Admin API source has no reads of those variables or outbound Cognito SDK calls. Admin has an inbound Cognito webhook and Developer Edition registration uses a persisted provider label through shared identity provisioning. | A004 removed the unused API variables and moved the emulator into the opt-in `cognito-mock` profile. The core profiles use the Welcome persona login. Keep Admin registration, inbound webhook compatibility, persona JWT claims, configured login redirects and journey paths. Coordinate Admin integration only where an actual executable dependency is found. |
| Documentation and history | Onboarding and active examples require AWS auth. Research and shipped records describe prior AWS work. | Update active guidance in A003. Preserve historical records and point current AWS-specific deployment guidance to CloudFormation. |

## Rollout and acceptance

1. Complete the umbrella setup, documentation, local configuration and Welcome CI changes (A002–A005). Validate the owned tooling and runtime changes without AWS CLI, credentials or live endpoints. Capture local results and rollback steps in A006. A007 can follow A005 independently of cross-repo sign-off.
2. Publish, validate and record permanent version-matched artifacts in the two publisher repos before updating consumers. API Utils publishes a public GitHub Release wheel and source archive. Pin the direct versioned wheel asset in Pipfile and regenerate Pipfile.lock. SPA Utils publishes `@mentor-forge/mentorhub_spa_utils` in GitHub Packages. Use an exact version and regenerate package-lock.json. Keep other dependencies on public PyPI/npm and preserve GHCR for containers.
3. Keep package credentials limited to their purpose. Public Python Release downloads require no credentials. GitHub npm requires package read access even for the public package. Use an environment-variable reference scoped to the GitHub npm host and the Mentor Forge scope. Consumer CI uses least-privilege package access and passes authentication to Docker via BuildKit secrets. Maintainers merge and tag matching versions. Publisher workflows check package contents and version agreement before publishing. Fix releases with new versions.
4. Upgrade all five API and five SPA journey consumers. Require clean installs from committed locks, tests, Docker builds and CI. A008 collects actual artifacts, consumer pins and lockfiles, and confirms combined local acceptance, including Developer Edition startup, persona login, registration and cross-journey smoke tests.
5. Roll back a failing release with a reviewed revert to the previous working package and lockfile, container pin or local configuration. If the previous pins require CodeArtifact, keep their supporting infrastructure available until rollback is no longer needed. Keep inventory, backup/restore evidence and separately approved AWS teardown under I-S01. Teardown follows consumer cutover and recovery verification.

## Migration issues

| Role | Tracking |
| --- | --- |
| Umbrella | [Local deployment and coordination](https://github.com/mentor-forge/mentorhub/issues/80) |
| Publishers | [API Utils](https://github.com/mentor-forge/mentorhub_api_utils/issues/36), [SPA Utils](https://github.com/mentor-forge/mentorhub_spa_utils/issues/43) |
| API consumers | [Mentor](https://github.com/mentor-forge/mentorhub_mentor_api/issues/43), [Mentee](https://github.com/mentor-forge/mentorhub_mentee_api/issues/34), [Discovery](https://github.com/mentor-forge/mentorhub_discovery_api/issues/18), [Customer](https://github.com/mentor-forge/mentorhub_customer_api/issues/23), [Admin](https://github.com/mentor-forge/mentorhub_admin_api/issues/12) |
| SPA consumers | [Mentor](https://github.com/mentor-forge/mentorhub_mentor_spa/issues/45), [Mentee](https://github.com/mentor-forge/mentorhub_mentee_spa/issues/38), [Customer](https://github.com/mentor-forge/mentorhub_customer_spa/issues/23), [Discovery](https://github.com/mentor-forge/mentorhub_discovery_spa/issues/20), [Admin](https://github.com/mentor-forge/mentorhub_admin_spa/issues/11) |
| AWS infrastructure | [I-S01 inventory and restoration](https://github.com/mentor-forge/mentorhub_cloudformation/issues/12) |

MongoDB API and Runbook API are outside the dependency cutover because neither consumes these shared packages. Future provider-specific infrastructure can use the same application contracts.
