# Cloud Dev Roadmap — Now / Next / Later

**Status:** Active  
**Goal:** A live **MentorHub-Dev** environment — reachable URL, sign-in, at least one journey (coordinator) working end-to-end against DocumentDB.

**Operating model:** Each **Now** item is one **Feature**. Implement it through the **Task Automation Framework** ([mentorhub_cloudformation/tasks](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/tasks) for platform IaC; [mentorhub/Tasks](../Tasks/README.md) for application work). When a Feature ships, promote the top **Next** item to **Now**.

**Related specs:** [CloudEnvironmentPlan](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudEnvironmentPlan.md) · [CLOUDFORMATION_PLAN](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_PLAN.md) · [roadmap.yaml](./roadmap.yaml)

---

## Now

### Feature: Provision ECR and connect it to GHCR

Merge to `main` today publishes container images to **GHCR only**. ECS in AWS needs **ECR**. This feature wires the two registries so the same build artifact is available in AWS without breaking local/dev workflows that already use GHCR.

| What | Task |
|------|------|
| GitHub OIDC provider + `GitHubActionsECRPush` role | [R030.1–R030.3](../../mentorhub_cloudformation/tasks/RUNNING.R030.ecr_ghcr_connection.md) |
| ECR repos + lifecycle (pilot set) | [R030.4–R030.6](../../mentorhub_cloudformation/tasks/RUNNING.R030.ecr_ghcr_connection.md) |
| CI dual-push to GHCR and ECR (pilot repo) | [R030.7–R030.8](../../mentorhub_cloudformation/tasks/RUNNING.R030.ecr_ghcr_connection.md) |

**Done when:** A merge to `main` produces matching `:latest` tags on GHCR and ECR for at least one pilot image; ECS (later) can pull from ECR without manual copy.

**Prerequisite (parallel):** [R020 CodeArtifact import](../../mentorhub_cloudformation/tasks/RUNNING.R020.codeartifact_import.md) execute when SRE access is available — same account, does not block template or workflow work.

---

## Next

Features we expect to build after ECR ↔ GHCR ships. Promote **#1** to Now when the current Now is done.

| # | Feature | Task(s) | Why next |
|---|---------|---------|----------|
| 1 | **Shared-Services governance** | [R031](../../mentorhub_cloudformation/tasks/PENDING.R031.shared_services_cloudtrail_budget.md) | CloudTrail + budget; codify existing CodeArtifact OIDC roles |
| 2 | **Dev network foundation** | R040 | VPC, subnets, NAT, security groups |
| 3 | **Dev data layer** | R050 | DocumentDB + Secrets Manager |
| 4 | **ECS compute platform** | R060 | Cluster, execution role (ECR pull, secrets, logs) |
| 5 | **Edge + auth (decisions first)** | R070 + D-2, D-3 | API Gateway, TLS/domain, Cognito vs interim login |
| 6 | **Coordinator pilot in cloud** | R080 | First live journey — login → SPA → API → DocumentDB |
| 7 | **Full CI/CD to ECS** | R100 | Merge → ECR → deploy Dev automatically |
| 8 | **Remaining journeys in Dev** | R090 | Customer, mentor, mentee, welcome, etc. |

### Parallel (not on critical path to first cloud URL)

| Feature | Task | Note |
|---------|------|------|
| CodeArtifact CF import (if not done) | R020 | Platform hygiene; consumers already work |
| Stage0 SPA CodeArtifact | [R108](../Tasks/AS_NEEDED.R108.codeartifact_phase5_stage0_spa.md) | Template hygiene |
| Local dev login IdP | [R102](../Tasks/AS_NEEDED.R102.dev_login_pilot.md) | Docker only; cloud uses Cognito |

---

## Later

High-level goals once Dev is live. Detail when promoted to Next.

| Theme | Goal |
|-------|------|
| **Test environments** | Additional stacks or namespaces in the Dev account for integration/QA |
| **Staging** | R120 — separate account or shared model; promote immutable images dev → staging |
| **Production** | R130 — HA, backups, production IdP, Stripe live |
| **GHCR retirement** | Remove GHCR push after ECR path proven ([DEPENDENCY_MOVE](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) container phase) |
| **Docs/diagrams match reality** | R110 |
| **Stage0 relaunch** | [R104](../Tasks/AS_NEEDED.R104.stage0_delete_journey_repos.md), [R105](../Tasks/AS_NEEDED.R105.architecture_rename_and_relaunch.md) |

---

## Promotion flow

```text
NOW:  ECR provisioned + GHCR ↔ ECR on merge (R030)
  ↓
NEXT: Shared-Services governance (R031)
  ↓
NEXT: Dev VPC (R040) → DocumentDB (R050) → ECS platform (R060)
  ↓
NEXT: Edge + auth decisions (R070)
  ↓
NEXT: Coordinator pilot live (R080)     ← "Dev is live"
  ↓
NEXT: CI/CD → ECS (R100) → all journeys (R090)
```

When R030 ships, update this section: move R031 to **Now**, shift the list, and link the active task file.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-24 | Initial Now/Next/Later roadmap; R030 scoped to ECR + GHCR; R031 split for CloudTrail/budget |
