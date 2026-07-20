# Workshop Task Automation Framework - Planning

This folder contains workshop tasks that an orchestration agent can execute, based on the context and instructions in each task file. This file is a guide for an agent that is helping to plan changes by creating task files to achieve a goal. Create tasks following the [naming conventions](#naming-conventions) and guides below. When planning, only create tasks, do not execute any tasks, and do not change any files outside of the tasks folder. 

- **Path anchoring**
  - All paths in task files are relative to **this API repository root** (the directory that contains `Pipfile`).
  - Sibling repos must all be sibling folders under a common parent.
  - Standards: `../mentorhub/DeveloperEdition/standards/api_standards.md`
  - In-repo: `README.md`, `Workshops/...`,  `tasks/...`

- **Context** Before creating any task files you should review the following files for context:
- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./CONTRIBUTING.md
- ./Workshops/README.md
- ./tasks/_ORCHESTRATE.md
- ./tasks/_PLANNING.md (this file)

## Task File Layout

Each task file must contain the following sections under H1 and H2 headings.

- Under the top H1 task header:
  - Each task file should declare `Status:` **inside the file**, and also encode the status in the **filename prefix** so tasks are visually grouped in the IDE.
  - **Lifecycle statuses (in‑file)**:
    - `Pending`: Not yet started.
    - `Running`: Work is currently being done in the active session.
    - `Blocked`: Waiting on some external dependency or decision.
    - `Shipped`: Implemented, tested, and committed as per the change control process.
    - `Run as needed`: Not part of the main long‑running sequence; to be run manually or opportunistically.
  - **Filename status prefixes (for grouping)**:
    - `AS_NEEDED.` – Tasks that should **not** be part of the main long‑running sequence.
    - `BLOCKED.` – Tasks currently blocked.
    - `PENDING.` – Tasks that are ready to be picked up when their turn comes.
    - `RUNNING.` – (Optional) Tasks currently being executed in this session.
    - `SHIPPED.` – Tasks that are fully implemented and completed.
  - **Type**: `Feature` | `Defect` to describe why we are running this task
  - **Depends On**: `L010_update_profile_openapi` the required predecessor task **in this repo**, or `none` for parallel tasks
  - **Description**: A brief human description of the task.

- Under a **Context** H2 header:
  - A list of context files. This list should always include:
    - ../mentorhub/DeveloperEdition/standards/*.md
    - ../mentorhub_api_utils/README.md
    - ../mentorhub_spa_utils/README.md
    - ./README.md
    - ./Workshops/README.md
  - Any other input files for the execution of the task.
  - `AS_NEEDED` tasks may include a **Parameters (edit before running)** subsection here for values to customize before promoting to `Pending`.

- Under a **Goals** H2 header:
  - A list of desired outcomes for the task.
  - Each item should describe the outcome (e.g. "OpenAPI `Profile` schema includes `full_name`").

- Under a **Testing Expectations** H2 header:
  - Should always include a description of the tests that should be used to verify completion.
  - In this repo, that typically means:
    - linting of markdown files

- Under an **Outputs** H2 header:
  - A list of the files that will be created/updated/moved/renamed/etc.
  - `tickets.md` will be updated to support `<Goal>`
  - List all files including new files to be created.
  - The agent will not update files not listed.

- Under an **Execution Notes** H2 header:
  - Reserved for the task execution agent to record plan, commands run, test results, and follow-ups.

## Naming Conventions
- **Recommended filename pattern**:
  - `STATUS.LNNN.short_task_name.md` where L is (B)efore or (A)fter workshop, and NNN is a serial task number. When planning, create only PENDING status tasks. 
  - Examples:
    - `PENDING.A010.identify_tickets.md`
    - `PENDING.A011.identify_data_structures.md`
    - `PENDING.A012.update_profile.md`
    - `SHIPPED.B009.plan_workshop.md`

## External repository boundaries

Task planning and execution in **this API repo** (`mentorhub`) must not read or depend on other sibling repositories for input context, except:

## MongoDB dictionary schemas

**Definitive** MongoDB collection/dictionary schema information must come from the **running MongoDB configurator service** (`mentorhub_mongodb_api`), not from files in the `mentorhub_mongodb_api` repository.

Start the backing database if needed (`pipenv run db`), then fetch the latest JSON schema with `curl`:

```bash
curl -X GET "http://localhost:8383/api/configurations/json_schema/<Dictionary>.yaml/latest/" -H "accept: application/json"
```

Replace `<Dictionary>` with the collection name (e.g. `Path`, `Resource`, `Note`). Use this response as the source of truth when updating `docs/openapi.yaml` component schemas or when implementing service projections. Do **not** use deprecated paths under `../mentorhub/Specifications/schemas/`.

If the configurator is unavailable, set the task **Status** to `Blocked` and stop — do not fall back to dictionary YAML files in the `mentorhub_mongodb_api` repo.

## OpenAPI Specifications

**Definitive** OpenAPI specifications must come from the **running API** not from files in the `mentorhub_mentee_api` repository.

Start the backing API if needed (`npm run api`), then fetch the latest JSON schema with `curl`:

```bash
curl -X GET "http://localhost:8393/docs/openapi.yaml"
```
the port number can be found in ./DeveloperEdition/docker-compose.yaml

## Sample task file

For a complete example of a well‑formed `Run as needed` task, see:

- `AS_NEEDED.T998.example_update_openapi.md`
