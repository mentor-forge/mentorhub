# L020 – Document cognito-local Developer Edition mock

Status: Pending
Type: Feature
Depends On: L019.seed_cognito_local_user_pool
Description: Record the new cognito-local compose service (port **9229**, env vars, how it relates to `login.html`) in living Developer Edition docs, and supersede F-W10 locked decision **L5** now that the follow-on container exists.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./Research/local_dev_mocks.md (**L5** currently forbids a Cognito container; **L1/L2/L9** still own SPA login / HS256 JWT)
- ./Research/cognito.md
- ./Workshops/customer_journey_issues.md (F-W10 historical “no cognito-local” — do not rewrite workshop transcript; add a short supersession note if a living section still states L5 as current)
- ./DeveloperEdition/docker-compose.yaml (L018/L019 outputs)
- ./Specifications/ArchitectureDiagram.local.drawio (already has a **Cognito (mock)** box)
- ./tasks/PENDING.L018.add_cognito_local_compose.md
- ./tasks/PENDING.L019.seed_cognito_local_user_pool.md
- [jagregory/cognito-local](https://github.com/jagregory/cognito-local)

## Goals

- **`Research/local_dev_mocks.md`:**
  - Update locked **L5**: Developer Edition **does** run `mock_cognito` (`jagregory/cognito-local`, port **9229**) for Cognito **Admin / IDP wire protocol**.
  - Keep **L1**, **L2**, **L9**: SPA sign-in UX remains `login.html`; `COGNITO_ENABLED` defaults **false**; local JWTs remain HS256 from welcome-auth until a later API task opts into Cognito-issued tokens.
  - Keep **L6**: no Post Confirmation Lambda in compose.
  - Document compose service name, port, profiles, and env vars (`COGNITO_ENDPOINT`, `COGNITO_USER_POOL_ID`, `COGNITO_CLIENT_ID`).
  - Document host vs compose-network URLs: `http://127.0.0.1:9229` from the host / AWS CLI; `http://mock_cognito:9229` from API containers.
  - Document a dummy-credential AWS CLI example (`list-user-pools` / `admin-create-user`) against the local endpoint.
  - Move “cognito-local” out of **Deferred** / anti-pattern “just in case”; clarify remaining anti-pattern: do not require **real AWS Cognito** for daily Developer Edition login.
- **`README.md` Quick Start port note:** add **9229 (cognito-local)** alongside **12111 (stripe-mock)**.
- **`CONTRIBUTING.md`:** only if a short pointer is missing — e.g. local mocks live in compose (`mock_stripe_api`, `mock_cognito`); do not duplicate the full env table from `local_dev_mocks.md`. Do **not** document path-based welcome routing here (**L026**).
- **`Specifications/ArchitectureDiagram.local.drawio`:** optional — add **9229** to the existing Cognito (mock) label if it can be done without a layout rewrite; regenerate the companion SVG only if the repo already treats that SVG as derived from the drawio file.
- Do **not** implement F-W10 login.html tabs, customer_api boto3 clients, or admin_api ingress in this task.

## Testing Expectations

- `README.md` port list includes **9229** and still lists **12111**.
- `Research/local_dev_mocks.md` no longer states “no cognito-local container” as the current locked decision; L1/L2/L9 remain.
- Grep `DeveloperEdition/docker-compose.yaml` vs the documented env var names — they match.
- Markdown lint on touched docs if tooling is available.
- Do not require a running stack for this docs-only task beyond confirming quoted ports/ids match L018/L019 files.

## Outputs

- `Research/local_dev_mocks.md` — L5 supersession, compose/env table, CLI examples.
- `README.md` — port list includes 9229 (cognito-local).
- `CONTRIBUTING.md` — only if a one-line mocks cross-reference is warranted.
- `Workshops/customer_journey_issues.md` — optional one-line note that L5 was superseded by L018–L020 (do not restage the F-W10 issue body as if cognito-local were never deferred).
- `Specifications/ArchitectureDiagram.local.drawio` — optional port label; `Specifications/ArchitectureDiagram.local.svg` only if regenerated.

## Execution Notes
