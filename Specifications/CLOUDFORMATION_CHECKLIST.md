# CloudFormation Implementation Checklist — MentorHub

Practical, itemized checklist to implement AWS CloudFormation for MentorHub. Use with:

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

---

## Phase 0 — Repo and tooling

- [ ] **0.1** Create `infrastructure/cloudformation/` in `mentorhub`
- [ ] **0.2** Add `infrastructure/cloudformation/README.md` (stack order, profiles, rollback)
- [ ] **0.3** Add `parameters/shared-services.json` (values from [aws-platform.yaml](./aws-platform.yaml))
- [ ] **0.4** Add `parameters/dev.json` (record MentorHub-Dev account ID when confirmed)
- [ ] **0.5** Add `scripts/deploy-stack.sh` (`aws cloudformation deploy --profile …`)
- [ ] **0.6** Add GitHub Action or pre-commit: `cfn-lint` on `infrastructure/cloudformation/**/*.yaml`
- [ ] **0.7** Document naming: `mentorhub-<env>-<component>` stacks, tags `Project=MentorHub`, `Environment`, `ManagedBy=CloudFormation`
- [ ] **0.8** SRE can `aws sso login --profile mentorhub-shared` and `mentorhub-dev`

**Exit:** Empty IaC layout merged; lint passes on a sample template.

---

## Phase 1 — Shared-Services: CodeArtifact (import from INFO.md)

Existing resources (do not recreate):

| Resource | Name |
|----------|------|
| Domain | `mentor-forge` |
| PyPI repo | `mentorhub-pypi` (+ `public:pypi`) |
| npm repo | `mentorhub-npm` (+ `public:npmjs`) |
| Account | `560167829275` |

- [ ] **1.1** Add template `shared-services/codeartifact.yaml` matching [INFO.md](./INFO.md)
- [ ] **1.2** Plan CloudFormation **resource import** for domain + both repositories
- [ ] **1.3** Run import change set (`--import-existing-resources`)
- [ ] **1.4** Stack update: ensure external connections `public:pypi` and `public:npmjs` match INFO.md
- [ ] **1.5** Tag imported resources
- [ ] **1.6** Validate: `aws codeartifact list-repositories --domain mentor-forge --domain-owner 560167829275 --region us-east-1 --profile mentorhub-shared`
- [ ] **1.7** Validate: local `mh` → `pipenv run install` / `npm ci` in a consumer repo
- [ ] **1.8** Validate: GitHub tag publish still reaches CodeArtifact

**Exit:** CodeArtifact under CloudFormation management with zero consumer breakage.

---

## Phase 2 — Shared-Services: CI identity and ECR

- [ ] **2.1** Add template `shared-services/github-oidc.yaml`
- [ ] **2.2** GitHub OIDC provider `token.actions.githubusercontent.com` (skip if already exists; import or reference)
- [ ] **2.3** Role `GitHubActionsCodeArtifactPublish` (import if manual today — see [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) §0.2.2)
- [ ] **2.4** Role `GitHubActionsCodeArtifactRead` (import if manual — §0.2.3)
- [ ] **2.5** Role `GitHubActionsECRPush` (new)
- [ ] **2.6** Role `GitHubActionsECSDeploy` (new; trust scoped to `mentor-forge` repos)
- [ ] **2.7** Store role ARNs in GitHub org secrets / [aws-platform.yaml](./aws-platform.yaml) as needed
- [ ] **2.8** Validate: test workflow `aws sts get-caller-identity` per role
- [ ] **2.9** Add template `shared-services/ecr.yaml`
- [ ] **2.10** ECR repos (pilot set): `mentorhub-welcome`, `mentorhub-coordinator-api`, `mentorhub-coordinator-spa`
- [ ] **2.11** ECR lifecycle policy (retain last N images)
- [ ] **2.12** Validate: CI push one image to ECR via OIDC
- [ ] **2.13** Add template `shared-services/cloudtrail.yaml` + budget alarm (~$25/month)
- [ ] **2.14** Validate: trail logging; budget notification received

**Exit:** Shared-Services platform boxes in [InfrastructureDiagram.svg](./InfrastructureDiagram.svg) except “CloudFormation” meta are live and codified.

---

## Phase 3 — MentorHub-Dev: foundation stacks

Deploy **in order** (each stack depends on prior).

### 3A — Governance and network

- [ ] **3.1** Record MentorHub-Dev AWS account ID in `parameters/dev.json` and [aws-platform.yaml](./aws-platform.yaml)
- [ ] **3.2** Template `dev/cloudtrail.yaml` + budget (~$50/month)
- [ ] **3.3** Template `dev/network.yaml` — VPC `10.0.0.0/16`, 2 public + 2 private subnets, IGW, NAT
- [ ] **3.4** Security groups: `alb-sg`, `ecs-sg`, `documentdb-sg` (gateway → ECS → DB)
- [ ] **3.5** Validate: subnets and NAT; private egress works

### 3B — Data and secrets

- [ ] **3.6** Template `dev/documentdb.yaml` — cluster (dev sizing), subnet group in private subnets
- [ ] **3.7** Template `dev/secrets.yaml` — Secrets Manager: DocumentDB connection string, `JWT_SECRET`
- [ ] **3.8** Validate: connection from a one-off task or bastion

### 3C — Compute platform

- [ ] **3.9** Template `dev/ecs-cluster.yaml` — Fargate cluster + CloudWatch log groups
- [ ] **3.10** ECS task execution role: ECR pull, Secrets Manager read, CloudWatch logs
- [ ] **3.11** Validate: empty cluster visible in console

### 3D — Edge and supporting services (defer if blocked)

- [ ] **3.12** Template `dev/api-gateway.yaml` — HTTP/REST API, route to pilot API
- [ ] **3.13** Template `dev/cognito.yaml` — user pool + app clients *(or defer: interim welcome JWT)*
- [ ] **3.14** Template `dev/s3.yaml` — app bucket(s), block public access
- [ ] **3.15** Template `dev/route53-acm.yaml` — hosted zone + ACM cert *(when domain owned)*
- [ ] **3.16** Template `dev/ses.yaml` — verified domain / sandbox *(when email ready)*
- [ ] **3.17** Validate: API Gateway URL returns coordinator API health (HTTPS optional until 3.15)

**Exit:** Dev swimlane foundation in InfrastructureDiagram — VPC, DocumentDB, ECS, API Gateway — deployed; Cognito/Route53/SES as far as decisions allow.

---

## Phase 4 — Pilot application (coordinator)

Mirror local ports from [docker-compose.yaml](../DeveloperEdition/docker-compose.yaml): coordinator API `8389`, SPA `8390`, welcome `8080`.

- [ ] **4.1** Template `dev/ecs-services-coordinator.yaml`
- [ ] **4.2** Task definition: `coordinator_api` (image from ECR or interim GHCR)
- [ ] **4.3** Task definition: `coordinator_spa` (env: `API_HOST`, `IDP_LOGIN_URI`, JWT settings)
- [ ] **4.4** Task definition: `welcome` (optional for interim dev login)
- [ ] **4.5** ECS services in private subnets; target groups / API Gateway integration
- [ ] **4.6** Env vars from Secrets Manager — not baked into images
- [ ] **4.7** Run `mongodb_api` configure job once against DocumentDB (ops runbook)
- [ ] **4.8** Smoke test: login → coordinator SPA → API round-trip → data in DocumentDB
- [ ] **4.9** Document rollback: previous task definition / image tag

**Exit:** First journey live in cloud Dev; matches pilot scope in [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md).

---

## Phase 5 — Remaining Dev services

Per [ArchitectureDiagram.dev.svg](./ArchitectureDiagram.dev.svg) and [ArchitectureDiagram.dev.guide.md](./ArchitectureDiagram.dev.guide.md):

| Journey | API | SPA |
|---------|-----|-----|
| Customer | `customer_api` | `customer_spa` |
| Mentor | `mentor_api` | `mentor_spa` |
| Mentee | `mentee_api` | `mentee_spa` |

Also: `mongodb_api` (configure job), `runbook_api` (ops).

- [ ] **5.1** ECR repos for each service image (or expand `ecr.yaml`)
- [ ] **5.2** Template `dev/ecs-services-customer.yaml` — deploy + smoke test
- [ ] **5.3** Template `dev/ecs-services-mentor.yaml` — deploy + smoke test
- [ ] **5.4** Template `dev/ecs-services-mentee.yaml` — deploy + smoke test *(merge [mentorhub_mentee_api](https://github.com/mentor-forge/mentorhub_mentee_api) CodeArtifact PR #1 first)*
- [ ] **5.5** Wire API Gateway / ALB routes: SPA static + `/api/*` → paired API
- [ ] **5.6** Replace interim dev `login.html` with Cognito when §3.13 complete
- [ ] **5.7** Full Dev smoke test across all journeys

**Exit:** Full Development Environment swimlane in InfrastructureDiagram populated.

---

## Phase 6 — CI/CD (close diagram arrows)

```text
git → GitHub Actions → ECR → ECS (MentorHub-Dev)
              ↓
        CodeArtifact (packages — already live)
```

- [ ] **6.1** Update `docker-push.yml` (pilot: `mentorhub_coordinator_api`, `mentorhub_coordinator_spa`): push to ECR
- [ ] **6.2** Add deploy step: update ECS service on merge to `main` (OIDC `GitHubActionsECSDeploy`)
- [ ] **6.3** Keep GHCR push in parallel until ECR path proven; then remove GHCR build-arg/deps per [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase 5
- [ ] **6.4** Roll CI pattern to customer, mentor, mentee, welcome repos
- [ ] **6.5** Validate: merge trivial change → new image running in ECS within expected time
- [ ] **6.6** Document promotion: immutable tag discipline (`latest` dev only; semver or sha for staging+)

**Exit:** Diagram CI/CD arrows implemented; Dev deploys from git without manual console steps.

---

## Phase 7 — Documentation and diagram hygiene

- [ ] **7.1** Update [ArchitectureDiagram.md](./ArchitectureDiagram.md) — link Infrastructure + CF checklist
- [ ] **7.2** Update [InfrastructureDiagram.svg](./InfrastructureDiagram.svg) — add missing internal arrows (VPC ↔ ECS ↔ API Gateway ↔ DocumentDB)
- [ ] **7.3** Note GHCR interim vs ECR target on diagram
- [ ] **7.4** Revise [sre_standards.md](../DeveloperEdition/standards/sre_standards.md) to as-implemented (replace “IaC TBD”)
- [ ] **7.5** Update [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) checkboxes to match deployed stacks
- [ ] **7.6** Runbook: deploy, rollback, destroy Dev stack, monthly cost check

**Exit:** Specs match reality; new SRE can deploy from checklist alone.

---

## Phase 8 — Staging (copy templates)

- [ ] **8.1** Decide account model ([CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) §Phase 2)
- [ ] **8.2** Add `parameters/staging.json`
- [ ] **8.3** Deploy Phase 3–6 stack set in staging account (smaller sizing)
- [ ] **8.4** CD: promote immutable image dev → staging
- [ ] **8.5** Create `ArchitectureDiagram.staging.svg`
- [ ] **8.6** Staging smoke test + test-data policy

**Exit:** Second swimlane in InfrastructureDiagram live.

---

## Phase 9 — Production (copy templates)

- [ ] **9.1** Production account + stricter IAM
- [ ] **9.2** Add `parameters/production.json`
- [ ] **9.3** HA DocumentDB, backups, multi-AZ where required
- [ ] **9.4** Production Cognito / IdP per [sre_standards.md](../DeveloperEdition/standards/sre_standards.md)
- [ ] **9.5** Route53 production domain + ACM
- [ ] **9.6** Stripe live mode cutover (customer_api)
- [ ] **9.7** Production checklist sign-off
- [ ] **9.8** Create `ArchitectureDiagram.production.svg`

**Exit:** Third swimlane in InfrastructureDiagram live.

---

## Quick reference — stack files

```text
infrastructure/cloudformation/
├── README.md
├── parameters/
│   ├── shared-services.json
│   ├── dev.json
│   ├── staging.json          # Phase 8
│   └── production.json       # Phase 9
├── scripts/
│   └── deploy-stack.sh
├── shared-services/
│   ├── codeartifact.yaml     # Phase 1 — IMPORT from INFO.md
│   ├── github-oidc.yaml      # Phase 2
│   ├── ecr.yaml              # Phase 2
│   └── cloudtrail.yaml       # Phase 2
└── dev/
    ├── cloudtrail.yaml
    ├── network.yaml
    ├── documentdb.yaml
    ├── secrets.yaml
    ├── ecs-cluster.yaml
    ├── api-gateway.yaml
    ├── cognito.yaml
    ├── s3.yaml
    ├── route53-acm.yaml
    ├── ses.yaml
    ├── ecs-services-coordinator.yaml
    ├── ecs-services-customer.yaml
    ├── ecs-services-mentor.yaml
    └── ecs-services-mentee.yaml
```

---

## Suggested timeline

| Phase | Focused SRE | Deliverable |
|-------|-------------|-------------|
| 0–1 | Week 1 | CodeArtifact imported into CF |
| 2 | Week 2 | OIDC + ECR + Shared CloudTrail |
| 3–4 | Weeks 3–4 | Dev VPC/DB/ECS + coordinator in cloud |
| 5–6 | Weeks 5–7 | All journeys + CI deploy to ECS |
| 7 | Week 8 | Docs/diagrams aligned |
| 8–9 | Weeks 9–14 | Staging + Production |

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-17 | Initial checklist from INFO.md, InfrastructureDiagram, aws-platform.yaml |
