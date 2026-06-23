# R106 – CodeArtifact Phase 3 (DE docs and tooling)

**Status:** Running  
**Task Type:** Documentation / SRE  
**Run Mode:** Run as needed

## Goal

Close [DEPENDENCY_MOVE.md](../Specifications/DEPENDENCY_MOVE.md) **Phase 3** in `mentorhub`: developer onboarding and standards reflect the as-built CodeArtifact model (Phase 2 complete for all eight journey API+SPA consumers).

## Context

- Phase 0–1: CodeArtifact infra + utils publish — **done**
- Phase 2: All journey APIs/SPAs on CodeArtifact — **done**
- Phase 3: DE CLI, docs, `make verify` — **this task**
- Phase 5: Remove obsolete git-dep logic (Stage0 templates, umbrella Dockerfile, etc.) — **not started**

## Requirements

### 3.1 Local registry auth (`mh`)

- [x] Bare `mh` refreshes GHCR + CodeArtifact (existing)
- [x] `make update` runs bare `mh` (existing)
- [ ] Validate: `pipenv run install` / `npm ci` in a consumer repo after `mh` (manual)

### 3.2 Documentation and tooling

| Area | Change | Status |
|------|--------|--------|
| `CONTRIBUTING.md` | CodeArtifact-first package narrative; `make aws-setup` + `mh` before installs | Done |
| `make verify` | AWS CLI + optional SSO profile / platform env checks | Done |
| `sre_standards.md` | CI section: CodeArtifact canonical workflow; remove transitional git+GH_PAT | Done |
| `api_standards.md` | Dependency section post-migration; pin `api-utils==0.2.1` example | Done |
| `branch_protection_standards.md` | PR CI deps: CodeArtifact OIDC only | Done |
| `README.md` | Onboarding link mentions CodeArtifact | Done |
| `CloudEnvironmentPlan.md` | P0-8 exit criteria alignment | Pending |
| Stage0 template git-deps note in DEPENDENCY_MOVE | Document exception until Phase 5 | Existing |

## Implementation notes

- Branch: `feature/codeartifact-phase3`
- `make verify` warns (does not fail) when `~/.aws/config` lacks `mentorhub-shared` — developers run `make aws-setup` once.
- Do **not** remove `GITHUB_TOKEN` / git URL rewrite from `make update` — still needed for git clone/push and GHCR.

## Testing

- [ ] `make verify` on machine with AWS CLI + `make install` (profile warn path)
- [ ] `make verify` after `make aws-setup` (profile OK path)
- [ ] Spot-check CONTRIBUTING + standards render in GitHub preview

## PR

- Open PR from `feature/codeartifact-phase3` → `main` (or `feature-planning` if that is the integration branch)
