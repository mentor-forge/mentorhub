# Specifications archive

SRE and platform infrastructure documentation lives in **[mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation)** (`docs/specifications/` and `tasks/`). Former stub paths under `Specifications/` have been removed.

## In `mentorhub_cloudformation`

| Document | Location |
|----------|----------|
| `CLOUDFORMATION_PLAN.md` | [docs/specifications/CLOUDFORMATION_PLAN.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_PLAN.md) |
| `CLOUDFORMATION_CHECKLIST.md` | [docs/specifications/CLOUDFORMATION_CHECKLIST.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CLOUDFORMATION_CHECKLIST.md) |
| `CloudEnvironmentPlan.md` | [docs/specifications/CloudEnvironmentPlan.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudEnvironmentPlan.md) |
| `CloudDevRoadmap.md` | [docs/specifications/CloudDevRoadmap.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/CloudDevRoadmap.md) |
| `DEPENDENCY_MOVE.md` | [docs/specifications/DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) |
| `INFO.md` | [docs/specifications/INFO.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/INFO.md) |
| `roadmap.yaml` | [docs/specifications/roadmap.yaml](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/roadmap.yaml) |
| `InfrastructureDiagram.*` | [docs/specifications/](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/docs/specifications) |
| SRE tasks R107, R108, R010–R130 | [tasks/](https://github.com/mentor-forge/mentorhub_cloudformation/tree/main/tasks) |

## Still in `mentorhub/Specifications/` (product / DE)

- `architecture.yaml`, journey diagrams, `catalog.yaml`, `product.yaml`, …
- `aws-platform.yaml` — convenience copy for Developer Edition; **canonical** in [cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/aws-platform.yaml)

## Still in `mentorhub/DeveloperEdition/` (developer onboarding)

- `mh`, `aws-setup`, `aws-platform.env`, `make verify` — developers do not need the IaC repo for day-one `pipenv` / `npm ci` / `mh up`.

## Tasks

- **SRE IaC tasks (R010–R130, R107, R108):** `mentorhub_cloudformation/tasks/`
- **App / DE tasks (R10x dev login, etc.):** `mentorhub/Tasks/`

Tracked by [SHIPPED.R107.sre_docs_to_cloudformation.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/tasks/SHIPPED.R107.sre_docs_to_cloudformation.md).
