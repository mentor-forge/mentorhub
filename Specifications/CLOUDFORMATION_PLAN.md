# CloudFormation Implementation Plan — MentorHub

Strategic plan for bringing MentorHub AWS infrastructure under CloudFormation. This document **coexists with** [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md); it does not replace it.

| Document | Role | Audience |
|----------|------|----------|
| **This plan** | Why, milestones, governance, decisions, mapping to broader platform work | Mike Storey, SRE leads, stakeholders |
| [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md) | Tactical index: task order, repo layout, timeline | SRE implementers, agents |
| [mentorhub_cloudformation/tasks/](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/tasks) | Executable task files (R010–R130) | SRE implementers, agents |
| [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) | Platform and application runtime scope (all environments) | Whole team |

**IaC repo:** [mentor-forge/mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)  
**Status:** In progress — R010 shipped (2026-06-19); next task R020  
**Primary region:** `us-east-1` · **SSO:** `us-east-2`

---

## 1. Purpose

MentorHub needs reproducible, reviewable AWS infrastructure so that:

1. **Shared-Services** (CodeArtifact, ECR, GitHub OIDC) and **workload accounts** (Dev → Staging → Production) match [InfrastructureDiagram.svg](./InfrastructureDiagram.svg).
2. SRE can deploy, roll back, and audit changes without console-only drift.
3. CI/CD in service repos can push images and update ECS using OIDC — not long-lived keys.
4. Fundraising campaign 3 (“cloud for dev”) in [FundraisingCampaigns.md](./FundraisingCampaigns.md) has a credible delivery path.

CloudFormation was chosen for incremental adoption: import existing CodeArtifact from [INFO.md](./INFO.md), add stacks one at a time, validate each before the next.

---

## 2. Scope

### In scope

- CloudFormation templates, parameters, and deploy automation in `mentorhub_cloudformation`
- Shared-Services account `560167829275` (`mentorhub-shared`)
- MentorHub-Dev workload account (ID TBD — record in [aws-platform.yaml](./aws-platform.yaml))
- Staging and Production (later milestones R120, R130)
- GitHub Actions: `cfn-lint` in IaC repo; ECR/ECS deploy patterns in service repos (R100)
- Diagram and spec hygiene (R110)

### Out of scope (handled elsewhere)

| Topic | Document / repo |
|-------|-----------------|
| Application code, API/SPA features | Service repos |
| CodeArtifact consumer migration (pip/npm) | [DEPENDENCY_MOVE.md](./DEPENDENCY_MOVE.md) |
| Local Docker dev | [DeveloperEdition/docker-compose.yaml](../DeveloperEdition/docker-compose.yaml) |
| Commercial IdP / Stripe live cutover details | [sre_standards.md](../DeveloperEdition/standards/sre_standards.md), R130 |

---

## 3. Principles

1. **Import, don’t recreate** — CodeArtifact domain and repos already exist; use CF resource import (R020).
2. **One stack per PR** — small blast radius; checklist task = one logical deploy unit.
3. **Specifications are inputs** — [architecture.yaml](./architecture.yaml), diagrams, and INFO.md drive templates; templates don’t redefine product intent.
4. **Isolated IaC CI** — CloudFormation workflows live in `mentorhub_cloudformation`, not `mentorhub` welcome/login CI.
5. **Secrets at runtime** — DocumentDB and JWT in Secrets Manager; not baked into images (aligns with CloudEnvironmentPlan D1-23).
6. **Pilot before breadth** — Coordinator journey in cloud Dev (R080) before all journeys (R090).

Full tactical rules: [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md#rules-one-stack-per-pr-validate-every-section-before-starting-the-next-do-not-delete-and-recreate-codeartifact--import-existing-resources-from-infomd).

---

## 4. Governance and approval

| Role | Responsibility |
|------|----------------|
| **Mike Storey** (`@FlatBallFlyer`) | Approve infrastructure specification changes and IaC repo PRs |
| **SRE** (Luther / Lucky) | Implement tasks R020+; run validation and smoke tests |
| **Developers** | Consume CodeArtifact/ECR; service-repo CI changes in R100 |

**Approval paths**

- `mentorhub` Specifications (diagrams, this plan, checklist): PR review — CODEOWNERS → `@FlatBallFlyer`
- `mentorhub_cloudformation`: PR review — CODEOWNERS → `@FlatBallFlyer`
- R010 bootstrap on `main`: retrospective sign-off via [mentorhub_cloudformation#1](https://github.com/mentor-forge/mentorhub_cloudformation/issues/1)

**Merge gates per milestone** (below): Mike sign-off + task `SHIPPED` + smoke test evidence in task file.

---

## 5. Milestones and gates

Each milestone maps to checklist tasks. **Do not start the next milestone until the gate passes.**

```text
M0 Repo ready     ──► R010 ✓ shipped
M1 Shared pkg     ──► R020, R030
M2 Dev foundation ──► R040–R070
M3 Pilot app      ──► R080
M4 Full Dev       ──► R090, R100
M5 Docs aligned   ──► R110
M6 Staging        ──► R120
M7 Production     ──► R130
```

### M0 — IaC repository ready ✓

| Gate | Evidence |
|------|----------|
| `mentorhub_cloudformation` on GitHub | Repo live, `cfn-lint` CI green |
| Task framework | `tasks/README.md`, R010–R130 files |
| Checklist index | [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md) links IaC repo |

**Shipped:** R010. **Approver:** Mike (issue #1).

### M1 — Shared-Services platform codified

| Gate | Evidence |
|------|----------|
| CodeArtifact under CF | Import complete; consumers unchanged ([INFO.md](./INFO.md)) |
| OIDC roles live | Test workflow `sts get-caller-identity` per role |
| ECR pilot repos | At least one image pushed via OIDC |
| Shared CloudTrail + budget | Trail logging; ~$25/month budget alarm |

**Tasks:** R020, R030. **Blocks:** All Dev deploys that pull from ECR.

### M2 — Dev foundation

| Gate | Evidence |
|------|----------|
| Dev account ID recorded | `parameters/dev.json`, [aws-platform.yaml](./aws-platform.yaml) |
| Network | VPC, NAT, security groups; private egress verified |
| Data | DocumentDB + Secrets Manager; connectivity smoke test |
| Compute | ECS cluster + execution role |
| Edge (as allowed) | API Gateway reachable; Cognito/Route53/SES deferred only with documented rationale |

**Tasks:** R040–R070. **Aligns with:** CloudEnvironmentPlan Phase 1 §1.1–1.3 (partial 1.4).

### M3 — Pilot in cloud Dev

| Gate | Evidence |
|------|----------|
| Coordinator journey | Login → coordinator SPA → API → DocumentDB |
| Configure job | `mongodb_api` run once against DocumentDB |
| Rollback documented | Previous task definition / image tag |

**Tasks:** R080. **Aligns with:** CloudEnvironmentPlan D1-24 (single journey).

### M4 — Full Dev + CI/CD

| Gate | Evidence |
|------|----------|
| All journeys deployed | Customer, mentor, mentee smoke tests |
| CI deploy | Merge to `main` → ECR → ECS without manual console |
| GHCR interim | Documented; removal per DEPENDENCY_MOVE Phase 5 when ECR proven |

**Tasks:** R090, R100. **Aligns with:** CloudEnvironmentPlan D1-12, D1-21, D1-22.

### M5 — Documentation truth

| Gate | Evidence |
|------|----------|
| Diagrams match deployed Dev | InfrastructureDiagram internal arrows; dev diagram updated |
| sre_standards | “IaC TBD” replaced with as-implemented |
| Runbook | Deploy, rollback, destroy Dev, cost check |

**Task:** R110.

### M6 — Staging

| Gate | Evidence |
|------|----------|
| Account model decided | CloudEnvironmentPlan Phase 2 |
| Stack set deployed | Smaller sizing; immutable image promotion |
| `ArchitectureDiagram.staging.svg` | Created |

**Task:** R120.

### M7 — Production

| Gate | Evidence |
|------|----------|
| HA / backups | DocumentDB, multi-AZ where required |
| Production sign-off | Checklist in sre_standards complete |
| `ArchitectureDiagram.production.svg` | Created |

**Task:** R130.

---

## 6. Mapping — CloudEnvironmentPlan ↔ CloudFormation tasks

Use this table to see how platform plan items trace to IaC work. Detail stays in task files.

| CloudEnvironmentPlan | CloudFormation task(s) | Notes |
|----------------------|------------------------|-------|
| Phase 0 (P0-1–P0-9) | R020, R030, DEPENDENCY_MOVE | P0-5–P0-6 largely done manually; R020 **imports** into CF |
| Phase 1 §1.1 Networking (D1-1–D1-6) | R040 | VPN decision may defer |
| Phase 1 §1.2 Data (D1-7–D1-9) | R050, R080 | Configure job at R080 |
| Phase 1 §1.3 Compute (D1-10–D1-13) | R030 (ECR), R060, R080–R090 | |
| Phase 1 §1.4 Edge (D1-14–D1-20) | R070 | Cognito/SES/Stripe may phase |
| Phase 1 §1.5 Delivery (D1-21–D1-24) | R010 ✓, R100, R080 | D1-21 satisfied by `mentorhub_cloudformation` |
| Phase 2 Staging | R120 | |
| Phase 3 Production | R130 | |
| Diagram: InfrastructureDiagram | R110 | Platform view |
| Diagram: ArchitectureDiagram.dev | R080, R090, R110 | Application view |

---

## 7. Open decisions

Record decisions here; unblock tasks by updating task files or marking `BLOCKED.` prefix.

| ID | Decision | Options | Blocks | Owner |
|----|----------|---------|--------|-------|
| D-1 | MentorHub-Dev AWS account ID | Confirm existing vs new account | R040 | Mike / SRE |
| D-2 | Dev login interim | Welcome JWT vs Cognito-first | R070, R080 | Mike |
| D-3 | Dev domain + TLS | Owned domain + ACM vs HTTP-only interim | R070 | Mike |
| D-4 | Staging account model | Separate account vs shared | R120 | Mike |
| D-5 | Image registry cutover | GHCR parallel until ECR proven | R100 | SRE |
| D-6 | Developer VPN | SSO-only vs Client VPN (CloudEnvironmentPlan D1-6) | R040 | Mike |

When resolved, update [aws-platform.yaml](./aws-platform.yaml) and the relevant `PENDING.R*.md` task.

---

## 8. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| CodeArtifact import breaks consumers | Import-only change set; validate pip/npm + tag publish (R020) |
| Drift between diagram and reality | R110; update diagrams in same PR as stack when possible |
| Cost overrun on Dev NAT/DocumentDB | Budgets (R040); right-size in parameters |
| mentee_api not on CodeArtifact | Merge [mentorhub_mentee_api PR #1](https://github.com/mentor-forge/mentorhub_mentee_api/pull/1) before R090 |
| Direct pushes to `main` on IaC repo | CODEOWNERS + PR workflow for R020+ |

---

## 9. Timeline (indicative)

Same windows as [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md#suggested-timeline); adjust when milestones slip.

| Window | Milestone | Outcome |
|--------|-----------|---------|
| Week 1 | M1 start | CodeArtifact in CF |
| Week 2 | M1 complete | OIDC + ECR + Shared trail |
| Weeks 3–4 | M2–M3 | Dev foundation + coordinator in cloud |
| Weeks 5–7 | M4 | All journeys + CI to ECS |
| Week 8 | M5 | Docs match reality |
| Weeks 9–14 | M6–M7 | Staging + Production |

---

## 10. How to use these documents together

**Starting work**

1. Read this plan for context and current milestone.
2. Open [CLOUDFORMATION_CHECKLIST.md](./CLOUDFORMATION_CHECKLIST.md) for the next task ID.
3. Execute the task file in `mentorhub_cloudformation/tasks/` per [tasks/README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/README.md).
4. For application/runtime questions, cross-check [CloudEnvironmentPlan.md](./CloudEnvironmentPlan.md) and [architecture.yaml](./architecture.yaml).

**Finishing work**

1. Mark task `SHIPPED`; update implementation notes.
2. If a milestone gate is satisfied, note it in this plan’s revision history.
3. Request Mike’s review on the PR; merge when approved.

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-19 | Initial plan; coexists with CLOUDFORMATION_CHECKLIST; R010 shipped |
