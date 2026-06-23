# Cloud Environment Plan

Tracked plan for MentorHub AWS platform work and architecture diagrams. Complements [architecture.yaml](./architecture.yaml), [aws-platform.yaml](./aws-platform.yaml), [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md), and [sre_standards.md](../DeveloperEdition/standards/sre_standards.md).

**Status:** Work in progress (2026-06-11)  
**Primary region:** `us-east-1`  
**First workload account:** `MentorHub-Dev`

---

## Environment model

| Environment | AWS account (target) | Diagram | Runtime status |
|-------------|----------------------|---------|----------------|
| Local | Developer machine (Docker Desktop) | [ArchitectureDiagram.local.svg](./ArchitectureDiagram.local.svg) | **Complete** |
| Development | `MentorHub-Dev` | [ArchitectureDiagram.dev.svg](./ArchitectureDiagram.dev.svg) | **Planned** — diagram WIP |
| Staging | TBD (separate account or shared) | *Not created* | Not started |
| Production | TBD | *Not created* | Not started |

**Platform services** (not application workloads) live in a future **`Shared-Services`** account: CodeArtifact, GitHub OIDC roles, later shared observability.

---

## As-built vs target (AWS Organization)

### As-built today

```text
AWS Organization
└── Root
    ├── Management account (Mike Storey)
    └── MentorHub-Dev (development workload)
```

Done:
- [x] IAM Identity Center enabled
- [x] Primary region recorded (`us-east-1`)
- [x] CloudTrail on MentorHub-Dev (`mentorhub-dev-trail`)
- [x] Budget on MentorHub-Dev ($50 / month)
- [x] CI publishes containers to GitHub Container Registry on merge to `main`

### Target before first cloud deploy

```text
AWS Organization
└── Root
    ├── Management
    ├── Shared-Services      ← package registries, GitHub OIDC
    └── MentorHub-Dev        ← ECS, DocumentDB, gateway, Cognito
```

---

## Phase 0 — Platform foundation (Shared-Services)

**Owner:** SRE (Luther / Lucky)  
**Blocks:** Reproducible builds without git-based utils deps  
**Detail:** [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase -1 and Phase 0

| ID | Task | Done |
|----|------|------|
| P0-1 | Create `Shared-Services` AWS account | [ ] |
| P0-2 | Budget ($25) + CloudTrail on Shared-Services | [ ] |
| P0-3 | Create `Developer-Packages` permission set; assign `Developer` group | [ ] |
| P0-4 | Record `AWS_SHARED_SERVICES_ACCOUNT_ID` in [aws-platform.yaml](./aws-platform.yaml) and GitHub org variables | [ ] |
| P0-5 | Create CodeArtifact domain `mentor-forge` + repos `mentorhub-pypi`, `mentorhub-npm` | [ ] |
| P0-6 | GitHub OIDC roles: `GitHubActionsCodeArtifactPublish`, `GitHubActionsCodeArtifactRead` | [ ] |
| P0-7 | Publish pipelines for `mentorhub_api_utils` and `mentorhub_spa_utils` | [ ] |
| P0-8 | Migrate consumer APIs/SPAs off git deps; implement `mh codeartifact login` | [x] journey repos; Stage0 templates still git (Phase 5) |
| P0-9 | Revise [sre_standards.md](../DeveloperEdition/standards/sre_standards.md) to match as-built | [x] CI/deps section (R106); full cloud P0-1–7 still open |

**Exit criteria:** Journey developers run `pipenv run install` / `npm ci` using CodeArtifact only; no `GH_PAT` for utils in journey Docker builds. Stage0 template repos remain on git-based `spa_utils` until [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) Phase 5.

---

## Phase 1 — Cloud DEV infrastructure (MentorHub-Dev)

**Owner:** SRE  
**Blocks:** Running MentorHub in AWS (fundraising campaign 3: “cloud for dev”)  
**Diagram guide:** [ArchitectureDiagram.dev.guide.md](./ArchitectureDiagram.dev.guide.md)

### 1.1 Networking

| ID | Task | Diagram box |
|----|------|-------------|
| D1-1 | Design VPC CIDR and AZ layout | Environment callout |
| D1-2 | **Public subnets** — ALB / API Gateway endpoints | Rename `VPC1` → Public subnets |
| D1-3 | **Private subnets** — ECS tasks, DocumentDB | Rename `VPC 2` → Private subnets |
| D1-4 | NAT gateway(s) for private egress | Add to diagram if not shown |
| D1-5 | Security groups: gateway → ECS → DocumentDB | Document on diagram edges |
| D1-6 | Decide developer access: SSO only vs Client VPN (fill “AWS VPN” line or remove) | Environment callout |

### 1.2 Data

| ID | Task | Diagram box |
|----|------|-------------|
| D1-7 | DocumentDB cluster (MongoDB 7 compatible) | AWS DocumentDB |
| D1-8 | Secrets Manager: connection string, `JWT_SECRET` | Edge ECS → DocumentDB |
| D1-9 | Run `mongodb_api` configure job once (schema + test data policy) | mongodb_api service |

### 1.3 Compute and images

| ID | Task | Diagram box |
|----|------|-------------|
| D1-10 | ECR repositories (or interim: pull from GHCR) | Add note on diagram |
| D1-11 | ECS cluster + Fargate task definitions per service | AWS ECS |
| D1-12 | Map 8 API + 8 SPA containers from [architecture.yaml](./architecture.yaml) | All `*_api` / `*_spa` boxes |
| D1-13 | NGINX SPA containers proxy `/api/*` to paired API (see sre_standards) | SPA → API edges |

**Service inventory (cloud DEV):**

| Service | Port (local ref) | Data domains |
|---------|------------------|--------------|
| mongodb_api | 8383 | Schema configure (ops job, not user-facing) |
| coordinator_api / spa | 8389 / 8390 | Customer, Identity, Profile, Login |
| customer_api / spa | 8387 / 8388 | Subscription, Dashboard, Card + consumes |
| mentor_api / spa | 8391 / 8392 | Resource, Path, Plan, Encounter |
| mentee_api / spa | 8393 / 8394 | Journey, Rating, Note |
| runbook_api | 8395 | Runbook automation (add to diagram) |

### 1.4 Edge, identity, integrations

| ID | Task | Diagram box |
|----|------|-------------|
| D1-14 | Route 53 hosted zone + ACM certificate | Add to diagram |
| D1-15 | API Gateway or ALB + CloudFront for SPAs | AWS API Gateway |
| D1-16 | Cognito user pool + app clients; replace dev `login.html` | AWS Cognito |
| D1-17 | Welcome/login URL → Cognito hosted UI or custom domain | Add **Welcome / Login** box |
| D1-18 | SES verified domain + IAM for transactional email | AWS SES |
| D1-19 | Stripe test mode: Checkout + webhooks to customer_api | Stripe (Test Mode) |
| D1-20 | CloudWatch logs/metrics; optional Prometheus sidecar | Add observability note |

### 1.5 Delivery

| ID | Task |
|----|------|
| D1-21 | IaC repo — [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) (CloudFormation); see [CLOUDFORMATION_PLAN.md](./CLOUDFORMATION_PLAN.md) |
| D1-22 | CD workflow: merge to `main` → build → push image → deploy ECS on MentorHub-Dev |
| D1-23 | Environment config via task env / Secrets Manager (not rebuilt images) |
| D1-24 | Smoke test: portal login → one journey SPA → one API round-trip |

**Exit criteria:** MentorHub-Dev URL reachable; Cognito login; data in DocumentDB; diagram matches deployed architecture.

---

## Phase 2 — Staging

| ID | Task |
|----|------|
| S2-1 | Decide account model (new `MentorHub-Staging` vs shared account) |
| S2-2 | Create `ArchitectureDiagram.staging.drawio` + `.svg` |
| S2-3 | Copy Phase 1 stack with staging config and test data policy |
| S2-4 | CD promotion: promote immutable image from dev → staging |
| S2-5 | Automated tests gate before prod promotion |

---

## Phase 3 — Production

| ID | Task |
|----|------|
| S3-1 | Production AWS account + stricter IAM |
| S3-2 | Create `ArchitectureDiagram.production.drawio` + `.svg` |
| S3-3 | Production IdP (Cognito or commercial IdP per sre_standards) |
| S3-4 | DocumentDB backup / restore runbook |
| S3-5 | Production checklist in sre_standards (JWT, TLS, budgets, CloudTrail) |
| S3-6 | Stripe live mode cutover |

---

## Diagram deliverables

| File | Purpose | Status |
|------|---------|--------|
| `ArchitectureDiagram.local.*` | Docker Desktop stack | Done |
| `ArchitectureDiagram.dev.*` | MentorHub-Dev AWS | **WIP** — use [dev guide](./ArchitectureDiagram.dev.guide.md) |
| `ArchitectureDiagram.staging.*` | Staging | Not started |
| `ArchitectureDiagram.production.*` | Production | Not started |
| Optional: `ArchitectureDiagram.platform.*` | Shared-Services, CodeArtifact, CI | Not started |

After each diagram edit: export SVG, commit both `.drawio` and `.svg`, update [ArchitectureDiagram.md](./ArchitectureDiagram.md).

---

## Cost sketch (for fundraising alignment)

| Account / env | Monthly budget (documented) | Primary spend |
|---------------|----------------------------|---------------|
| Shared-Services | $25 | CodeArtifact, CloudTrail |
| MentorHub-Dev | $50 | ECS Fargate, DocumentDB, NAT, gateway |
| Staging | TBD | Same classes, smaller sizing |
| Production | TBD | HA DocumentDB, multi-AZ, higher task count |

Campaign 3 in [FundraisingCampaigns.md](./FundraisingCampaigns.md) maps to Phase 0 + Phase 1 ops funding.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-11 | Initial plan; links dev diagram box-by-box guide |
