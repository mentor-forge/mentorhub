# R110 – Fix broken mentorhub_cloudformation doc references

**Status**: Shipped  
**Task Type**: Docs  
**Run Mode**: Sequential

## Goal

Update `mentorhub` documentation and standards so links and references match the flattened layout in [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation) (`platform-planning` branch). Remove or replace pointers to the deleted `docs/specifications/` path and to roadmap-era documents that were archived.

## Context / Input files

Read before implementation:

- [mentorhub_cloudformation/README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/README.md) — TO-BE platform overview (replaces roadmap-era planning docs)
- [mentorhub_cloudformation/config/aws-platform.yaml](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/config/aws-platform.yaml) — canonical platform state (accounts, CodeArtifact, SSO, packages)
- [mentorhub_cloudformation/docs/archive/README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/docs/archive/README.md) — index of archived planning documents (historical reference only)
- [mentorhub_cloudformation/docs/InfrastructureDiagram.svg](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/docs/InfrastructureDiagram.svg) — platform diagram (moved out of `specifications/`)

### Path mapping (old → new)

| Old reference | New reference | Notes |
|---------------|---------------|-------|
| `docs/specifications/aws-platform.yaml` | `config/aws-platform.yaml` | Canonical config |
| `docs/specifications/InfrastructureDiagram.svg` | `docs/InfrastructureDiagram.svg` | |
| `docs/specifications/DEPENDENCY_MOVE.md` | `config/aws-platform.yaml` | Migration complete; use config for as-built state. Archive only if historical context needed. |
| `docs/specifications/CloudEnvironmentPlan.md` | [README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/README.md) | Platform overview |
| `docs/specifications/CLOUDFORMATION_PLAN.md` | [README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/README.md) | |
| `docs/specifications/CLOUDFORMATION_CHECKLIST.md` | [tasks/README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/tasks/README.md) | Task index |
| `docs/specifications/roadmap.yaml` | [README.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/platform-planning/README.md) | Roadmap retired |
| `docs/specifications/` (folder) | `config/` + `docs/` + `docs/archive/` | Folder removed |
| `Specifications/DEPENDENCY_MOVE.md` | `config/aws-platform.yaml` | **File does not exist** in mentorhub — broken local link |
| `Specifications/aws-platform.yaml` | `mentorhub_cloudformation/config/aws-platform.yaml` | **File does not exist** in mentorhub — broken local link |
| `Specifications/Archive/README.md` | Remove or replace | **File does not exist** — referenced from `Specifications/README.md` |

## Requirements

### Files to update

| File | Broken / stale references | Suggested fix |
|------|----------------------------|---------------|
| `README.md` | `docs/specifications/roadmap.yaml`; "roadmap and IaC tasks" / "platform specs" wording | Link to cloudformation README; remove product roadmap link or replace with platform overview |
| `Specifications/README.md` | `docs/specifications/`; `Archive/README.md` | Point to `config/aws-platform.yaml`, cloudformation README, `docs/archive/` |
| `Specifications/ArchitectureDiagram.md` | `CloudEnvironmentPlan`, `CLOUDFORMATION_PLAN`, `CLOUDFORMATION_CHECKLIST`, `InfrastructureDiagram.svg` under `docs/specifications/` | Platform overview README + `docs/InfrastructureDiagram.svg` |
| `Specifications/ArchitectureDiagram.dev.guide.md` | `CloudEnvironmentPlan`; local `./aws-platform.yaml` | Cloudformation README + `config/aws-platform.yaml` URL |
| `DeveloperEdition/standards/sre_standards.md` | `docs/specifications/` (6×); `DEPENDENCY_MOVE.md` (6×); `Specifications/aws-platform.yaml` | `config/aws-platform.yaml`; drop DEPENDENCY_MOVE links — cite config or sre_standards prose |
| `DeveloperEdition/standards/api_standards.md` | `DEPENDENCY_MOVE.md` (2×) | `config/aws-platform.yaml` (`packages.pypi`) |
| `DeveloperEdition/standards/spa_standards.md` | `../../Specifications/DEPENDENCY_MOVE.md` (2×) — **404** | `config/aws-platform.yaml` (`packages.npm`) |
| `DeveloperEdition/standards/branch_protection_standards.md` | `DEPENDENCY_MOVE.md` | `config/aws-platform.yaml` or `sre_standards.md` CI section |
| `DeveloperEdition/standards/examples/docker-push.yml` | Comment: `docs/specifications/DEPENDENCY_MOVE.md` | `config/aws-platform.yaml` or `sre_standards.md` |
| `DeveloperEdition/standards/examples/docker-push-codeartifact.yml` | Comment: `docs/specifications/DEPENDENCY_MOVE.md` | Same as above |
| `DeveloperEdition/aws-platform.env` | Comment: `Specifications/aws-platform.yaml` | `mentorhub_cloudformation/config/aws-platform.yaml` |
| `Tasks/README.md` | `docs/specifications` link | `config/aws-platform.yaml` + cloudformation README |

### Optional follow-up (same task if scope allows)

| Item | Action |
|------|--------|
| `Specifications/aws-platform.yaml` | Add a thin convenience copy synced from cloudformation `config/aws-platform.yaml` **or** document that DE tooling reads only `aws-platform.env` and link externally — resolve `aws-platform.env` header comment either way |
| `Specifications/Archive/README.md` | Remove reference from `Specifications/README.md` **or** add a short stub pointing to cloudformation `docs/archive/` |
| Shipped task files (`AS_NEEDED.R106`, etc.) | Leave historical implementation notes unchanged unless link rot causes confusion in active workflows |

### Content guidance

- **Do not** restore links to archived planning docs (`DEPENDENCY_MOVE`, `CloudDevRoadmap`, `LiveDevPlan`, etc.) as primary references.
- **Do** point developers and architects to `config/aws-platform.yaml` for account IDs, CodeArtifact repos, SSO, and package names.
- **Do** point to cloudformation `README.md` for TO-BE platform architecture (accounts, tenancy, CI/CD).
- Use `docs/archive/` links only when historical migration context is explicitly needed.

## Testing expectations

Docs-only task — `make container` does not apply.

- [ ] Run a repo-wide search and confirm zero hits for `docs/specifications` (except this task file and shipped historical notes, if retained):
  ```sh
  rg 'docs/specifications' --glob '!Tasks/PENDING.R110*' --glob '!Tasks/AS_NEEDED.R106*'
  ```
- [ ] Run a repo-wide search and confirm zero hits for `Specifications/DEPENDENCY_MOVE` and `Specifications/aws-platform.yaml` (unless a convenience copy is intentionally added).
- [ ] Manually spot-check updated markdown links resolve on GitHub after `mentorhub_cloudformation` `platform-planning` is merged to `main` (or use `platform-planning` branch URLs until then).

## Dependencies / Ordering

- **After:** [mentorhub_cloudformation `platform-planning`](https://github.com/mentor-forge/mentorhub_cloudformation/tree/platform-planning) is merged to `main` (or update links to `platform-planning` branch URLs until merge).
- **Before:** Any new DE or standards work that cites platform config paths.

## Change control checklist

- [ ] Reviewed cloudformation path mapping and `config/aws-platform.yaml`.
- [ ] Updated all files in the requirements table.
- [ ] Ran `rg` verification searches; no unexpected stale references.
- [ ] Scoped commit referencing R110.

## Implementation notes (to be updated by the agent)

**Summary of changes**

**Verification results**

**Follow-up tasks**
