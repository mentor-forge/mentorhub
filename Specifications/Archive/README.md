# Specifications archive

SRE and platform infrastructure documentation **moved to [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)** (`docs/specifications/`). Stubs at the original paths below preserve links from older docs and tasks.

## Moved to `mentorhub_cloudformation/docs/specifications/`

| Former path (stub in `Specifications/`) | Canonical document |
|----------------------------------------|-------------------|
| `CLOUDFORMATION_PLAN.md` | [CLOUDFORMATION_PLAN.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_PLAN.md) |
| `CLOUDFORMATION_CHECKLIST.md` | [CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_CHECKLIST.md) |
| `CloudEnvironmentPlan.md` | [CloudEnvironmentPlan.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudEnvironmentPlan.md) |
| `DEPENDENCY_MOVE.md` | [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) |
| `INFO.md` | [INFO.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/INFO.md) |
| `InfrastructureDiagram.drawio` / `.svg` | [InfrastructureDiagram](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/docs/specifications) |

## Still in `mentorhub/Specifications/` (product / DE)

- `architecture.yaml`, journey diagrams, `catalog.yaml`, `product.yaml`, …
- `aws-platform.yaml` — convenience copy for Developer Edition; **canonical** in [cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/aws-platform.yaml)

## Still in `mentorhub/DeveloperEdition/` (developer onboarding)

- `mh`, `aws-setup`, `aws-platform.env`, `make verify` — developers do not need the IaC repo for day-one `pipenv` / `npm ci` / `mh up`.

## Tasks

- **SRE IaC tasks (R010–R130):** `mentorhub_cloudformation/tasks/`
- **App / DE tasks (R10x):** `mentorhub/Tasks/` — kept as organized AI change history

Tracked by [R107](../Tasks/AS_NEEDED.R107.sre_docs_to_cloudformation.md).
