# R107 – Move SRE documentation to mentorhub_cloudformation

**Status:** Shipped (pending PR merge)  
**Task Type:** Documentation / SRE  
**Run Mode:** Run as needed

## Goal

Relocate SRE and platform infrastructure specifications from `mentorhub/Specifications/` to **`mentorhub_cloudformation/docs/specifications/`**, with stubs and [Archive/README.md](../Specifications/Archive/README.md) preserving links.

## Boundary (agreed model)

| Stays in `mentorhub` | Moves to `mentorhub_cloudformation` |
|----------------------|-------------------------------------|
| Product specs (`architecture.yaml`, journeys, catalog) | `CLOUDFORMATION_PLAN`, `CLOUDFORMATION_CHECKLIST` |
| Dev/local architecture diagrams | `CloudEnvironmentPlan`, `DEPENDENCY_MOVE` |
| DE onboarding (`mh`, `make aws-setup`, CONTRIBUTING) | `INFO.md`, `InfrastructureDiagram.*` |
| App/DE tasks (`Tasks/R10x`) | SRE IaC tasks (`tasks/R010–R130`) |
| `aws-platform.yaml` convenience copy | **Canonical** `aws-platform.yaml` |

## Done in this change

- [x] Copy specs to `mentorhub_cloudformation/docs/specifications/`
- [x] Stubs at former `mentorhub/Specifications/` paths
- [x] `Specifications/Archive/README.md` migration map
- [x] Update cross-links in `ArchitectureDiagram.md`, `roadmap.yaml`, standards
- [x] `mentorhub_cloudformation/README.md` and `docs/README.md`

## Follow-up (not this PR)

- [ ] R110: split `sre_standards.md` platform vs developer sections further
- [ ] Sync `aws-platform.yaml` / `.env` from cloudformation on `make update` (optional automation)
- [ ] Archive or trim stub files once all external links updated

## PRs

- `mentorhub`: `feature/sre-docs-to-cloudformation` → `main`
- `mentorhub_cloudformation`: `feature/sre-docs-home` → `main`
