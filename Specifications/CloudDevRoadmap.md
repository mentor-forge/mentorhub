# Cloud Dev Roadmap

**Status:** Active (draft for review)  
**North star:** MentorHub running in **AWS MentorHub-Dev** — a URL a developer can open, sign in, and complete at least one journey (coordinator) end-to-end with data in DocumentDB.

This document is the **single map** from where we are today to that goal. It uses an **Agile Design Thinking** rhythm: **Now**, **Next**, and **Later** — not a detailed plan that will go stale.

---

## How we use this roadmap

| Term | Meaning |
|------|---------|
| **Now** | The one most important **feature** to build next. Only one. |
| **Next** | Features we expect to build after **Now** ships, in rough order. |
| **Later** | High-level goals after Dev is live (test envs, staging, production). No detail until promoted. |
| **Promote** | When **Now** is done, move the top **Next** item to **Now** and update this file. |

**Now** is implemented through the **Task Automation Framework**:

- Platform / IaC: [mentorhub_cloudformation/tasks](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/tasks) (R010–R130)
- Application: [mentorhub/Tasks](../Tasks/README.md) (R100+)

Each **Now** feature maps to one (or a tight cluster of) task file(s). Agents and humans execute that task before starting the next feature.

**Deeper specs** (reference, not the roadmap): [CloudEnvironmentPlan](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudEnvironmentPlan.md) · [CLOUDFORMATION_PLAN](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_PLAN.md) · [architecture.yaml](./architecture.yaml)

---

## Current state

| Area | Status |
|------|--------|
| **Local Developer Edition** | Complete — Docker Compose, `mh`, full stack on localhost |
| **Application code** | Journey APIs/SPAs build and run locally; active feature work continues |
| **Package registry** | CodeArtifact live (`mentor-forge` domain); consumers on private pip/npm |
| **Container publish** | Merge to `main` → **GHCR** only (`ghcr.io/mentor-forge/*`) |
| **Shared-Services account** | Exists (`560167829275`); CodeArtifact operational |
| **IaC repo** | [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) bootstrapped; R020 import template merged |
| **MentorHub-Dev runtime** | **Not deployed** — no VPC, DocumentDB, ECS, or public URL yet |
| **Cloud DEV diagram** | WIP — [ArchitectureDiagram.dev.guide.md](./ArchitectureDiagram.dev.guide.md) |

```text
TODAY                          TARGET (Dev is live)
─────                          ────────────────────
Local Docker  ──────────────►  MentorHub-Dev URL
GHCR images                     ECS + DocumentDB
CodeArtifact packages           Cognito (or agreed interim auth)
No AWS app runtime              Coordinator journey end-to-end
```

---

## Journey to live Dev

High-level phases. **Now** sits in phase 1; everything after is **Next** until Dev is live, then **Later** for staging/production.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 0 — Platform foundation (Shared-Services)                        │
│  CodeArtifact ✓  │  CF import (R020)  │  governance (R031)             │
├─────────────────────────────────────────────────────────────────────────┤
│  PHASE 1 — Image pipeline                              ◄── NOW          │
│  ECR repos + GitHub OIDC + GHCR ↔ ECR dual-push (R030)                  │
├─────────────────────────────────────────────────────────────────────────┤
│  PHASE 2 — Dev infrastructure (MentorHub-Dev)          ◄── NEXT         │
│  VPC → DocumentDB → ECS cluster → edge (gateway, DNS, auth)             │
│  R040 → R050 → R060 → R070                                               │
├─────────────────────────────────────────────────────────────────────────┤
│  PHASE 3 — First app in cloud                          ◄── NEXT         │
│  Coordinator pilot: login → SPA → API → DocumentDB (R080)               │
├─────────────────────────────────────────────────────────────────────────┤
│  PHASE 4 — Dev fully operational                       ◄── NEXT         │
│  CI/CD to ECS (R100) → all journeys (R090) → docs match reality (R110)   │
├─────────────────────────────────────────────────────────────────────────┤
│  PHASE 5 — Beyond Dev                                    ◄── LATER      │
│  Test envs · Staging (R120) · Production (R130)                           │
└─────────────────────────────────────────────────────────────────────────┘
```

**“Dev is live”** = Phase 3 exit: coordinator journey works in MentorHub-Dev against DocumentDB.

---

## Now

### Feature: Provision ECR and connect it to GHCR

**Why now:** CI already builds images on every merge to `main`, but they land in GHCR only. Nothing in AWS can run our containers until **ECR** exists and receives the same artifacts. This is the smallest platform step that unblocks all Dev deploy work.

| Deliverable | Task |
|-------------|------|
| `GitHubActionsECRPush` OIDC role | [R030.1–R030.3](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/RUNNING.R030.ecr_ghcr_connection.md) |
| ECR repos + lifecycle (pilot set) | [R030.4–R030.6](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/RUNNING.R030.ecr_ghcr_connection.md) |
| Dual-push GHCR + ECR on merge (pilot repo) | [R030.7–R030.8](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/RUNNING.R030.ecr_ghcr_connection.md) |

**Done when:** Merge to `main` on a pilot repo produces matching `:latest` in GHCR and ECR.

**Parallel (not blocking):** [R020](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/RUNNING.R020.codeartifact_import.md) CodeArtifact CF import execute when SRE access is available.

---

## Next

Promote **#1** to **Now** when ECR + GHCR ships. Order may shift; dependencies noted.

| # | Feature | Phase | Task(s) | Unblocks |
|---|---------|-------|---------|----------|
| 1 | Shared-Services governance | 0 | [R031](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/PENDING.R031.shared_services_cloudtrail_budget.md) | CloudTrail, budget, CodeArtifact OIDC in CF |
| 2 | Dev network | 2 | R040 | VPC, subnets, NAT, security groups |
| 3 | Dev data | 2 | R050 | DocumentDB, Secrets Manager |
| 4 | ECS platform | 2 | R060 | Cluster, task execution role, logs |
| 5 | Edge + auth | 2 | R070 | API Gateway, DNS/TLS, Cognito (decisions D-2, D-3) |
| 6 | Coordinator pilot | 3 | R080 | **First live journey in cloud** |
| 7 | CI/CD to ECS | 4 | R100 | Merge → deploy without manual steps |
| 8 | All journeys in Dev | 4 | R090 | Full product surface in MentorHub-Dev |
| 9 | Docs match deployed Dev | 4 | R110 | Diagrams and runbooks truthful |

### Not on the critical path to first cloud URL

These improve local dev or future relaunches; run in parallel when capacity allows.

| Feature | Task |
|---------|------|
| CodeArtifact CF import (if not done) | R020 |
| Stage0 SPA CodeArtifact | [R108](../Tasks/AS_NEEDED.R108.codeartifact_phase5_stage0_spa.md) |
| Local dev login IdP | [R102](../Tasks/AS_NEEDED.R102.dev_login_pilot.md) |
| Profile dashboard | [profile_dashboard.yaml](./profile_dashboard.yaml) |

---

## Later

Goals after **Dev is live**. Detail when an item is promoted to **Next**.

| Goal | Notes |
|------|-------|
| **Test environments** | Additional stacks or namespaces in the Dev account for integration/QA |
| **Staging** | R120 — account model TBD; promote immutable images dev → staging |
| **Production** | R130 — HA, backups, production IdP, Stripe live |
| **Retire GHCR** | After ECR + ECS path proven ([DEPENDENCY_MOVE](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md)) |
| **Stage0 relaunch** | [R104](../Tasks/AS_NEEDED.R104.stage0_delete_journey_repos.md), [R105](../Tasks/AS_NEEDED.R105.architecture_rename_and_relaunch.md) |

---

## Promotion queue

Current queue (update when **Now** ships):

```text
NOW   → ECR + GHCR dual-push (R030)
NEXT  → Shared-Services governance (R031)
NEXT  → Dev VPC (R040) → DocumentDB (R050) → ECS (R060) → Edge (R070)
NEXT  → Coordinator pilot (R080)          ← "Dev is live"
NEXT  → CI/CD to ECS (R100) → all journeys (R090) → docs (R110)
LATER → test envs · staging · production
```

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-24 | Initial Now/Next/Later; R030 scoped to ECR + GHCR |
| 2026-06-25 | Expanded: current state, journey phases, promotion model, task framework link |
