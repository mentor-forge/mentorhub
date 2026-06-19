# SPA Task Automation Framework

This folder contains coding tasks that an agent can execute, based on the context and instructions in each task file. All of these tasks will only make changes in this SPA repo. The agent will orchestrate execution of all Pending Tasks to implement a Feature. 

## Orchestration model: Feature Workflow
Before starting the workflow, check to make sure you are not on the main branch, and that you can push on the branch you are on. If you fail this test, pause and ask the developer how you should proceed, and then select or create a branch as instructed before starting the first task.

Now orchestrate all Pending Tasks as outlined below. Use an **orchestration agent** that spawns a **fresh agent per task**:

1. **Orchestrator** discovers all tasks, respects dependencies, and determines execution order.
  - **Task Selection**: Select only `PENDING.*` tasks.
  - **Execution order**: Review all PENDING tasks and order dependencies first
  - Schedule **concurrent** agents if no dependencies exist.
2. **For each task**, the orchestrator launches a new agent with:
  - The task file path
  - Any outputs from prior tasks (e.g. "R160 complete; template_service.py updated")
3. **Sub-agent** executes only that task: read context, implement, test, update task notes.
4. **Commit Changes** The orchestrators is responsible for a commit, with a meaningful message, and a push changes.
5. **Mark Shipped** by updating the task status, and renaming the task file like `SHIPPED.T999_the_task.md` 
6. **Orchestrator** After the commit, the orchestrator moves to the next task. 

**Task Failure Case** In the event a task fails, execution should halt and the developer should receive a summary of the current state and error condition that caused the failure. 

**All Tasks Complete** Once all tasks have successfully completed, the orchestration agent should create a Pull Request with a meaningful summary of all the commits made during the workflow. You can then notify the developer that the workflows was completed and provide a link to the PR for details. 

## Task File Layout

Each Task file must contain the following Sections under H1 and H2 headings. 
- Under the top H1 task header 
  - Each task file should declare `Status:` **inside the file**, and also encode the status in the **filename prefix** so tasks are visually grouped in the IDE.
  - **Lifecycle statuses (in‑file)**:
    - `Pending`: Not yet started.
    - `Running`: Work is currently being done in the active session.
    - `Blocked`: Waiting on some external dependency or decision.
    - `Shipped`: Implemented, tested, and merged/committed as per the change control process.
    - `Run as needed`: Not part of the main long‑running sequence; to be run manually or opportunistically.

  - **Filename status prefixes (for grouping)**:
    - `AS_NEEDED.` – Tasks that should **not** be part of the main long‑running sequence.
    - `BLOCKED.` – Tasks currently blocked.
    - `PENDING.` – Tasks that are ready to be picked up when their turn comes.
    - `RUNNING.` – (Optional) Tasks currently being executed in this session.
    - `SHIPPED.` – Tasks that are fully implemented and completed.
  - **Type**: `Feature` | `Defect` to describe why we are running this task
  - **Depends On**: `T999_do_this_first` the required predecessor task for sequential tasks, or `none` for parallel tasks
  - **Description**: A brief human description of the task. 
- Under a **Context** H2 header:
  - A list of context files. This list should always include
  - ../DeveloperEdition/standards/spa_standards.md
  - ./README_SPA.md
  - Any other "input" files for the execution of the task
- Under a **Goals** H2 header:
  - A list of desired outcomes for the task
  - Each item should describe the outcome (the page shows XYZ)
  - You can have multiple goals, or clarifying goals.
- Under a **Testing Expectations** H2 header: 
  - Can include the creation of new tests for new features.
  - Can include changing existing tests because of modified features.
  - Should always include a description of the tests that should be used to verify completion. 
    - In this repo, that typically means some combination of:
    - ``npm run test`` - to run unit testing
    - ``npm run api`` - to start backing services
    - ``npm run dev`` - to run the dev server (captures command)
    - ``npm run cypress:run`` to run the end-to-end testing headlessly (long running)
  - Should always include the **Packaging verification** step:
    - ``npm run container`` to test building the container image
    - ``npm run service`` to run the app and backing services in containers
    - ``npm run cypress:run`` to ensure success against the packaged runtime.
  - All Test Files should be identified in Outputs (below)
- Under an **Outputs** H2 header:
  - A list of the files that will be created/updated/moved/renamed/etc. 
  - File_Name.xy will be updated to <XYZ> in support of <Goal>
  - List all files including new files to be created. 
  - The agent will not update files not listed.
- Under an **Execution Notes** H2 header:
  - This area is reserved for the task execution agent to update with notes about the execution of the task

- **Recommended filename pattern**:
  - `STATUS.RNNN.short_task_name.md`
  - Examples:
    - `AS_NEEDED.R900.example_add_healthcheck.md`
    - `PENDING.R010.add_healthcheck_endpoint.md`
    - `RUNNING.R050.implement_bulk_import.md`
    - `SHIPPED.R100.configure_ci_pipeline.md`

- **Path Anchoring** 
  - All paths in task files are relative to **this SPA repository root** (the directory that contains `package.json`).
  - Sibling repos (mentorhub umbrella, api's, etc) must all be sibling folders.
  - Standards: `../mentorhub/DeveloperEdition/standards/spa_standards.md`
  - Backing API OpenAPI: `../mentorhub_<domain>_api/docs/openapi.yaml`
  - In-repo simply `README.md`, `src/...`, `cypress/...`, `Tasks/...`

### Sample task file

For a complete example of a well‑formed `Run as needed` task (including context files, testing expectations, change control checklist, and implementation notes), see:
- `AS_NEEDED.T999.example_add_fields.md`

## Task execution workflow

The steps below apply to the agent that executes a task.

1. **Review the current tasks**
  - Each task is a markdown file in this folder (e.g., `PENDING.T001_update_api_from_openapi.md`).
  - For each task, read the entire file before starting work.

2. **Change control for each task**
  For every task, the agent should:
  - **Review Context and Goals**: Read all referenced input/context files.
  - **Plan changes**: Summarize the planned approach in the Execution Notes section of the task file.
  - **Implement changes**: Update code, configuration, docs, etc., as required.
  - **Testing**: Follow the instructions in the task file’s **Testing expectations** section.

4. **Completion and documentation**
  - After successful testing
  - Update the task file’s **implementation notes**.
  - If follow‑ups are discovered, add them as new FOR_REVIEW tasks instead of over‑expanding the current one.
