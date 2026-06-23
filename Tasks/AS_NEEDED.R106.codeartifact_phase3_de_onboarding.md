# R106 – CodeArtifact Phase 3 (DE docs and tooling)

**Status:** Shipped (pending PR merge)  
**Task Type:** Documentation / SRE  
**Run Mode:** Run as needed

## Goal

Close [DEPENDENCY_MOVE.md](../Specifications/DEPENDENCY_MOVE.md) **Phase 3** in `mentorhub`: developer onboarding and standards reflect the as-built CodeArtifact model (Phase 2 complete for all eight journey API+SPA consumers).

## Context

- Phase 0–1: CodeArtifact infra + utils publish — **done**
- Phase 2: All journey APIs/SPAs on CodeArtifact — **done**
- Phase 3: DE CLI, docs, `make verify` — **done** (this task)
- Phase 5: Remove obsolete git-dep logic (Stage0 templates, umbrella Dockerfile, etc.) — **next**

## Requirements

### 3.1 Local registry auth (`mh`)

- [x] Bare `mh` refreshes GHCR + CodeArtifact (existing)
- [x] `make update` runs bare `mh` (existing)
- [x] Validate: `pipenv run install` / `npm ci` in consumer repos after `mh`

### 3.2 Documentation and tooling

| Area | Change | Status |
|------|--------|--------|
| `CONTRIBUTING.md` | CodeArtifact-first package narrative; `make aws-setup` + `mh` before installs | Done |
| `make verify` | AWS CLI + SSO profile + CodeArtifact reachability check | Done |
| `sre_standards.md` | CI section: CodeArtifact canonical workflow | Done |
| `api_standards.md` | Dependency section post-migration | Done |
| `spa_standards.md` | Dependency Management section | Done |
| `branch_protection_standards.md` | PR CI deps: CodeArtifact OIDC only | Done |
| `system_tour.md` | `mh` + CodeArtifact install commands | Done |
| `README.md` | Onboarding link mentions CodeArtifact | Done |
| `CloudEnvironmentPlan.md` | P0-8/P0-9 + exit criteria | Done |
| `DEPENDENCY_MOVE.md` | Phase 3 marked complete; Stage0 → Phase 5 note | Done |

## Implementation notes

- Branch: `feature/codeartifact-phase3`
- `make verify` warns (does not fail) when SSO profile or CodeArtifact API is unavailable.
- Do **not** remove `GITHUB_TOKEN` / git URL rewrite from `make update` — still needed for git clone/push and GHCR.

## Testing

- [x] `make verify` — AWS CLI + profile + CodeArtifact reachable (2026-06-23)
- [x] `mentorhub_customer_api` — `pipenv run install` → `api-utils==0.2.1`
- [x] `mentorhub_customer_spa` — `npm ci` → `@mentor-forge/mentorhub_spa_utils@0.2.2`

## PR

- `feature/codeartifact-phase3` → `main` (or `feature-planning`)
