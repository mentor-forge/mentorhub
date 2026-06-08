# R104 – Stage0 launch: delete spa_utils and journey api/spa repos

**Status:** As Needed  
**Task Type:** Chore  
**Run Mode:** Run as needed

## Goal

Use **`stage0_launch`** (per Developer Edition / Stage0 docs) to **delete** the shared SPA utils repo and all **journey** API/SPA repos so the team can re-create them after architecture renaming.

**Do not delete** the umbrella `mentorhub` repo or non-journey utilities (e.g. `mentorhub_mongodb_api`, `mentorhub_runbook_api`).

## Context / Input files

**Read first:**

- [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md)
- `Specifications/architecture.yaml` — list of journey domains/repos to delete
- Developer Edition / Stage0 launch documentation for delete workflow
- [R102](./AS_NEEDED.R102.dev_login_pilot.md) — must be **Shipped** (Phase A pilot + Phase B Stage0 templates) before delete/re-launch

## Requirements

### Delete via `stage0_launch`

- [ ] Delete **`mentorhub_spa_utils`**
- [ ] Delete each journey **`mentorhub_{domain}_api`** and **`mentorhub_{domain}_spa`** listed in current `architecture.yaml` (e.g. customer, coordinator, mentor, craftsperson)
- [ ] **Do not** delete:
  - `mentorhub` (umbrella)
  - `mentorhub_mongodb_api`, `mentorhub_runbook_api`, or other schema/utility repos unless explicitly approved

### Documentation

- Record exact `stage0_launch` commands and outcomes in **Implementation notes**
- Optional: short note in umbrella `CONTRIBUTING.md` or launch runbook if your process requires it

### Umbrella git

- No mass code delete in umbrella repo for this task — operational delete of **remote** journey repos only
- Umbrella welcome changes from R102 remain in place

## Testing expectations

- Confirm target repos no longer exist (or are archived) in GitHub/org
- Confirm umbrella and utility repos still present

## Dependencies / Ordering

- Run **after** [R102](./AS_NEEDED.R102.dev_login_pilot.md) is **Shipped** (both phases)
- Run **before** [R105](./AS_NEEDED.R105.architecture_rename_and_relaunch.md)

## Change control checklist

- [ ] Team confirms delete list matches `architecture.yaml`
- [ ] Execute `stage0_launch` delete steps
- [ ] Verify repo state
- [ ] Document commands/results in **Implementation notes**
- [ ] PR or tracked issue referencing **R104** (umbrella doc-only PR if needed)

## Implementation notes

_(Fill in when task is executed.)_

## Testing results

_(Fill in when task is executed.)_
