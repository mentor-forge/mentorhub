# S48 – Refactor architecture.yaml: remove Coordinator, add Admin + Discovery

Status: Pending
Type: Feature
Depends On: none
Description: F-W09 E0 — Remove the Coordinator journey domain from platform architecture specs and document Admin + Discovery as the replacement journey domains (GitHub coordinator repos deleted; Customer API/SPA unchanged).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Workshops/customer_journey_issues.md (F-W09 issue text, E0)
- ./Workshops/customer_journey_issues_adjustments.md (Coordinator role, F-W18/F-US09)
- ./Workshops/admin_journey_issues.md (Admin + Discovery copy sources, F-W18)
- ./Specifications/architecture.yaml
- ./Specifications/journeys.yaml

## Goals

- Remove the `coordinator` journey domain block (and `coordinator_api` / `coordinator_spa` repos) from `Specifications/architecture.yaml`.
- Add **`admin`** and **`discovery`** journey domains to `architecture.yaml`, aligned with F-W13/F-W14 and `Workshops/admin_journey_issues.md`:
  - Reuse freed Coordinator ports for Admin: `admin_api` **8389**, `admin_spa` **8390**.
  - Assign Discovery ports: `discovery_api` **8397**, `discovery_spa` **8398** (runbook remains 8395/8396; do not renumber mentor/mentee).
  - Use the same repo naming pattern as other journey domains (`admin_api`, `admin_spa`, `discovery_api`, `discovery_spa`).
- Remove the **Coordinator Journey** entry from `Specifications/journeys.yaml` (keep Mentor, Mentee, Customer).
- Do **not** change Customer domain ports (8387/8388) or Cognito/IdP ownership — Customer SPA remains the Cognito redirect consumer.

## Testing Expectations

- YAML parse: `yq '.' Specifications/architecture.yaml` and `yq '.' Specifications/journeys.yaml` succeed.
- Grep `Specifications/architecture.yaml` and `Specifications/journeys.yaml` — no `coordinator_api`, `coordinator_spa`, or `Coordinator Journey`.
- Confirm port assignments are unique across all repos listed in `architecture.yaml`.
- Markdown/YAML lint on touched files if tooling is available.

## Outputs

- `Specifications/architecture.yaml` — remove coordinator domain; add admin + discovery domains with ports above.
- `Specifications/journeys.yaml` — remove Coordinator Journey entry.

## Execution Notes
