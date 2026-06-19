# CloudFormation Implementation Checklist — MentorHub

Tactical index for MentorHub AWS CloudFormation. **Strategic context, milestones, and governance:** [CLOUDFORMATION_PLAN.md](./CLOUDFORMATION_PLAN.md).

**Discrete implementation tasks** live in the dedicated repo:

**[mentor-forge/mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)** — CloudFormation templates, parameters, deploy scripts, and SRE task workflow (`tasks/README.md`).

Use with these specification inputs:

- [architecture.yaml](./architecture.yaml) — Architecture and Infrastructure intent (work in progress)
- [InfrastructureDiagram.svg](./InfrastructureDiagram.svg) — platform / account view (Shared-Services + Dev/Staging/Prod)
- [ArchitectureDiagram.dev.svg](./ArchitectureDiagram.dev.svg) — application services inside Dev
- [INFO.md](./INFO.md) — **as-built** CodeArtifact commands (Shared-Services `560167829275`)
- [aws-platform.yaml](./aws-platform.yaml) — canonical region, account IDs, org variables
- [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) — OIDC roles, CodeArtifact URLs, CI patterns
- [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) — Dev runtime tasks

**Region:** `us-east-1` (workloads). **SSO:** `us-east-2` (Identity Center only).

**Accounts:**

| Account | ID / profile | Purpose |
|---------|----------------|---------|
| Shared-Services | `560167829275` / `mentorhub-shared` | CodeArtifact, ECR, GitHub OIDC, Shared CloudTrail |
| MentorHub-Dev | TBD / `mentorhub-dev` | VPC, ECS, DocumentDB, Cognito, API Gateway |

**Rules:** One stack per PR. Validate every section before starting the next. Do **not** delete and recreate CodeArtifact — **import** existing resources from [INFO.md](./INFO.md).

**Why a separate repo?** CloudFormation GitHub Actions (`cfn-lint`, future deploy workflows) stay isolated from the main `mentorhub` CI that builds developer welcome/login pages.

---

## Task index

Execute in order per [`tasks/README.md`](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/README.md).

| Task | Phase | Focus | Repo file |
|------|-------|-------|-----------|
| R010 | 0 | Repo and tooling bootstrap (shipped) | [SHIPPED.R010.repo_bootstrap.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/SHIPPED.R010.repo_bootstrap.md) |
| R020 | 1 | CodeArtifact import (from INFO.md) | [PENDING.R020.codeartifact_import.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R020.codeartifact_import.md) |
| R030 | 2 | Shared-Services OIDC, ECR, CloudTrail | [PENDING.R030.shared_services_oidc_ecr.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R030.shared_services_oidc_ecr.md) |
| R040 | 3A | Dev governance and network | [PENDING.R040.dev_governance_network.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R040.dev_governance_network.md) |
| R050 | 3B | Dev DocumentDB and secrets | [PENDING.R050.dev_data_secrets.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R050.dev_data_secrets.md) |
| R060 | 3C | Dev ECS compute platform | [PENDING.R060.dev_compute_platform.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R060.dev_compute_platform.md) |
| R070 | 3D | Dev edge services (API GW, Cognito, S3, DNS, SES) | [PENDING.R070.dev_edge_services.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R070.dev_edge_services.md) |
| R080 | 4 | Pilot: coordinator journey | [PENDING.R080.pilot_coordinator.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R080.pilot_coordinator.md) |
| R090 | 5 | Remaining Dev services | [PENDING.R090.remaining_dev_services.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R090.remaining_dev_services.md) |
| R100 | 6 | CI/CD: ECR → ECS deploy | [PENDING.R100.cicd_ecs_deploy.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R100.cicd_ecs_deploy.md) |
| R110 | 7 | Documentation and diagram hygiene | [PENDING.R110.documentation_hygiene.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R110.documentation_hygiene.md) |
| R120 | 8 | Staging | [PENDING.R120.staging.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R120.staging.md) |
| R130 | 9 | Production | [PENDING.R130.production.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R130.production.md) |

Ad-hoc work (e.g., one-off resource imports): see [AS_NEEDED.sample.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/AS_NEEDED.sample.md).

---

## Repository layout

```text
mentorhub_cloudformation/          # dedicated repo (not mentorhub/infrastructure/)
├── README.md
├── parameters/
│   ├── shared-services.json
│   ├── dev.json
│   ├── staging.json          # R120
│   └── production.json       # R130
├── scripts/
│   └── deploy-stack.sh
├── templates/
│   ├── shared-services/
│   │   ├── codeartifact.yaml     # R020 — IMPORT from INFO.md
│   │   ├── github-oidc.yaml      # R030
│   │   ├── ecr.yaml              # R030
│   │   └── cloudtrail.yaml       # R030
│   └── dev/
│       ├── cloudtrail.yaml
│       ├── network.yaml
│       ├── documentdb.yaml
│       ├── secrets.yaml
│       ├── ecs-cluster.yaml
│       ├── api-gateway.yaml
│       ├── cognito.yaml
│       ├── s3.yaml
│       ├── route53-acm.yaml
│       ├── ses.yaml
│       └── ecs-services-*.yaml
├── tasks/
│   ├── README.md
│   └── PENDING.R*.md
└── .github/workflows/
    └── cfn-lint.yml
```

---

## Suggested timeline

| Tasks | Focused SRE | Deliverable |
|-------|-------------|-------------|
| R010–R020 | Week 1 | CodeArtifact imported into CF |
| R030 | Week 2 | OIDC + ECR + Shared CloudTrail |
| R040–R080 | Weeks 3–4 | Dev VPC/DB/ECS + coordinator in cloud |
| R090–R100 | Weeks 5–7 | All journeys + CI deploy to ECS |
| R110 | Week 8 | Docs/diagrams aligned |
| R120–R130 | Weeks 9–14 | Staging + Production |

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-17 | Initial checklist from INFO.md, InfrastructureDiagram, aws-platform.yaml |
| 2026-06-16 | Dedicated `mentorhub_cloudformation` repo; `architecture.yaml` input; discrete SRE tasks |
| 2026-06-19 | Added [CLOUDFORMATION_PLAN.md](./CLOUDFORMATION_PLAN.md) as strategic companion |
