# Cloud DEV Diagram — Box-by-Box Finish Guide

Finish [ArchitectureDiagram.dev.drawio](./ArchitectureDiagram.dev.drawio) in draw.io (VS Code Draw.io Integration extension). Export [ArchitectureDiagram.dev.svg](./ArchitectureDiagram.dev.svg) when done.

**Reference:** [CloudEnvironmentPlan](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudEnvironmentPlan.md) · [architecture.yaml](./architecture.yaml) · Local diagram for parity: [ArchitectureDiagram.local.drawio](./ArchitectureDiagram.local.drawio)

---

## How to use this guide

Work **top to bottom, outside-in**:

1. Environment callout (context)
2. Network zones (VPC boxes)
3. Edge + browser entry
4. AWS managed services (ECS, DocumentDB, Cognito, SES, Gateway)
5. Application services (SPAs → APIs → data collections)
6. Integrations (Stripe, Events)
7. Missing boxes to add
8. Edges to draw or fix
9. Optional platform overlay page

Use **solid arrows** for runtime traffic, **dashed arrows** for build/deploy or admin paths.

---

## Box 1 — Environment callout (top-left)

**Current label (incomplete):**

```text
Environment: DEV
Image Tag: latest
AWS Account: mentorhub-dev
AWS VPN:
```

**Replace with:**

```text
Environment: DEV
Region: us-east-1
AWS Account: MentorHub-Dev
Image: ghcr.io/mentor-forge/* :latest (→ ECR later)
Developer access: IAM Identity Center (SSO)
Optional: Client VPN (TBD)
```

**Actions:**
- [ ] Fill or remove the `AWS VPN` line — if devs use SSO only, delete that line
- [ ] Use shape style: note / callout, not a service
- [ ] Align with [aws-platform.yaml](./aws-platform.yaml)

---

## Box 2 — `VPC1` → Public subnets

**Current:** Generic label `VPC1` (outer left, ~490×470)

**Rename to:**

```text
Public subnets
ALB / API Gateway
NAT Gateway (egress)
```

**Actions:**
- [ ] Rename the swimlane or group title
- [ ] Place **AWS API Gateway** inside or on the boundary facing the Browser
- [ ] Optionally add small **Route 53** + **ACM** icons near the gateway

---

## Box 3 — `VPC 2` → Private subnets

**Current:** Generic label `VPC 2` (center-right, ~490×740)

**Rename to:**

```text
Private subnets
ECS Fargate tasks
DocumentDB (data tier)
```

**Actions:**
- [ ] Rename the swimlane
- [ ] Ensure **AWS ECS** and **AWS DocumentDB** sit inside this zone
- [ ] All `*_api` / `*_spa` boxes should appear inside private subnets (tasks only reachable via gateway)

---

## Box 4 — Browser

**Current:** Icon on the far left

**Label:** `Browser` (keep)

**Actions:**
- [ ] Draw arrow: **Browser → AWS API Gateway** (HTTPS) — should exist; verify it is connected
- [ ] Remove any dangling edge from Browser to nowhere
- [ ] Do **not** connect Browser directly to ECS tasks or DocumentDB

---

## Box 5 — AWS API Gateway

**Current:** Left of application stack

**Label:** `AWS API Gateway` (keep; add subtitle if helpful: `TLS termination, routing`)

**Actions — draw these outbound edges:**

| To | Label on arrow |
|----|----------------|
| mentee_spa | `/mentee/*` or host-based route |
| customer_spa | `/customer/*` |
| mentor_spa | `/mentor/*` |
| coordinator_spa | `/coordinator/*` |
| AWS Cognito | OAuth/OIDC authorize (dashed) |

**Future:** Add **Welcome / Login** route to Cognito hosted UI or a static CloudFront origin.

---

## Box 6 — AWS Cognito (IdP)

**Current:** Bottom area, linked from coordinator_api and API Gateway

**Label:** `AWS Cognito` / `Identity Provider (IdP)` (keep)

**Actions:**
- [ ] Edge **API Gateway → Cognito** (OIDC) — dashed
- [ ] Edge **coordinator_api → Cognito** only if API validates tokens via JWKS (optional; prefer “all APIs validate JWT” note)
- [ ] Add callout: replaces local `login.html` personas in DEV cloud
- [ ] Match [sre_standards.md](../DeveloperEdition/standards/sre_standards.md) production auth story

---

## Box 7 — AWS ECS

**Current:** Upper-left inside private zone

**Label:** `AWS ECS (Elastic Container Service)` (keep)

**Actions:**
- [ ] Treat ECS as the **runtime host** for every container box below (implicit grouping — optional dashed box around all services)
- [ ] Add note: **Orchestration: ECS Fargate** (preferred in sre_standards)
- [ ] Add dashed edge from **GitHub Actions / GHCR** (new icon off-page or in legend): `build → push → deploy`

---

## Box 8 — AWS DocumentDB

**Current:** Near ECS

**Label:** `AWS DocumentDB` (keep)

**Actions:**
- [ ] Draw edges **every `*_api` → DocumentDB** (MongoDB protocol), or one edge from a labeled **“API tasks”** group if cluttered
- [ ] **mongodb_api** also connects here for configure/migrate jobs
- [ ] Add note: MongoDB-compatible; local uses `MongoDB` — intentional mapping

**Data collection boxes** (Subscription, Journey, etc.) are **logical** — they live inside DocumentDB, not separate AWS services. Keep them as labels linked from APIs (as today).

---

## Box 9 — AWS SES

**Current:** Bottom right

**Label:** `AWS SES (SMTP Service)` (keep)

**Actions — draw inbound from APIs that send mail:**

| From | Purpose |
|------|---------|
| customer_api | Billing / subscription notices |
| coordinator_api | Invite / match emails |
| mentor_api | Session notifications (future) |

Local equivalent: `mailhog (mock)`.

---

## Box 10 — Stripe (Test Mode)

**Current:** `Stripe / Testing Service` (vague)

**Replace label with:**

```text
Stripe (Test Mode)
Checkout · Webhooks
```

**Actions:**
- [ ] Edge **customer_api → Stripe** (HTTPS outbound)
- [ ] Optional dashed **Stripe → API Gateway** webhook path
- [ ] Local equivalent: `stripe_api (mock)`

---

## Box 11 — mongodb_api

**Current:** Top of API column

**Actions:**
- [ ] Edge **mongodb_api → DocumentDB** (schema configure, migrations)
- [ ] Mark as **ops / CI job** or admin-only (not user browser traffic)
- [ ] Optional: dashed edge from **GitHub Actions** or **Runbook** for “Configure Database”

Configurator SPA is **local-only** in most setups — omit from cloud DEV or mark “optional admin tool”.

---

## Boxes 12–19 — Journey services (SPA → API → collections)

Mirror the local diagram pattern: **Browser → Gateway → SPA → API → collection labels**.

### mentee_spa → mentee_api → Journey / Rating / Note

| Box | Action |
|-----|--------|
| mentee_spa | Gateway edge in; edge to mentee_api |
| mentee_api | Edge to Journey/Rating/Note; edge to DocumentDB |
| Journey/Rating/Note | Logical collections — keep as grouped label |

### customer_spa → customer_api → Subscription / Dashboard

| Box | Action |
|-----|--------|
| customer_spa | Gateway edge in; edge to customer_api |
| customer_api | Edge to Subscription/Dashboard; edges to Stripe, SES, DocumentDB |
| Subscription/Dashboard | Logical collections |

### mentor_spa → mentor_api → Resource / Path / Plan / Encounter

| Box | Action |
|-----|--------|
| mentor_spa | Gateway edge in; edge to mentor_api |
| mentor_api | Edge to Resource/Path/Plan/Encounter; DocumentDB; optional SES |

### coordinator_spa → coordinator_api → Customer / Profile / Identity / Login

| Box | Action |
|-----|--------|
| coordinator_spa | Gateway edge in; edge to coordinator_api |
| coordinator_api | Edge to Customer/Profile/Identity/Login; DocumentDB; Cognito validation |
| Customer/Profile/Identity/Login | Logical collections |

**Fix broken edges today:** Several API boxes have edges to `None` in the source file — reconnect **each `*_api` → DocumentDB** and remove orphan connectors.

---

## Box 20 — Events

**Current:** Small box near DocumentDB

**Label:** `Events` (logical collection)

**Actions:**
- [ ] Show **multiple APIs write Events** (dashed “creates Event” from coordinator, customer, mentor, mentee APIs)
- [ ] Events live in DocumentDB — edge from collection group to DocumentDB, not a separate AWS service

---

## Boxes to ADD (missing vs local diagram)

| Add this box | Placement | Notes |
|--------------|-----------|-------|
| **Welcome / Login** | Between Browser and Cognito/Gateway | CloudFront static or Cognito hosted UI; replaces `mentorhub Welcome/Login` |
| **runbook_api** | Near mongodb_api | Port 8395; automation — optional in DEV |
| **GitHub Actions → GHCR** | Legend or top margin | Build/publish on merge to `main` |
| **CodeArtifact** | Second page or legend | Shared-Services; build-time only |
| **CloudWatch** | Near ECS | Logs and metrics |

---

## Edge checklist (complete the drawing)

Copy this checklist in draw.io’s layer notes:

**User traffic**
- [ ] Browser → API Gateway (HTTPS)
- [ ] API Gateway → each SPA (×4)
- [ ] Each SPA → paired API (×4)

**Data**
- [ ] Each API → DocumentDB
- [ ] mongodb_api → DocumentDB

**Auth**
- [ ] API Gateway ↔ Cognito (OIDC)
- [ ] SPAs redirect to login URL (annotation)

**Integrations**
- [ ] customer_api → Stripe
- [ ] customer_api / coordinator_api → SES

**Deploy (dashed)**
- [ ] GHCR → ECS (image pull)
- [ ] GitHub Actions → GHCR

**Remove**
- [ ] Any connector ending nowhere
- [ ] Duplicate or conflicting Browser edges

---

## Styling conventions

| Element | Style |
|---------|--------|
| AWS managed service | AWS orange / official icon if available |
| MentorHub container | Same color family as local diagram |
| Logical MongoDB collections | Cylinder or stacked label near DocumentDB |
| Build/deploy path | Dashed gray |
| User HTTPS path | Solid blue |
| Not yet provisioned | Dashed border + “Planned” subtitle |

---

## Export and commit

1. **File → Export as → SVG** → overwrite `ArchitectureDiagram.dev.svg`
2. Save `ArchitectureDiagram.dev.drawio`
3. Preview in [ArchitectureDiagram.md](./ArchitectureDiagram.md)
4. When Phase 1 infra lands, update labels with real hostnames and account IDs

---

## Optional — Page 2: Platform view

If Page 1 is crowded, add **Page-2: Platform (Shared-Services)**:

```text
GitHub (mentor-forge org)
  → GitHub Actions (OIDC)
    → CodeArtifact (mentorhub-pypi, mentorhub-npm)
    → GHCR (images, interim)
Shared-Services account
  ├── CodeArtifact domain: mentor-forge
  └── IAM roles: Publish / Read
MentorHub-Dev account
  └── ECS pulls images + runtime config
```

Cross-link Page 1 ↔ Page 2 with a note on Page 1: “Build deps: see Platform diagram.”
