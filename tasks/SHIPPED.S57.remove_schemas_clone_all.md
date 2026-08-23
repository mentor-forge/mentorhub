# S57 – Replace hardcoded clone-all with architecture.yaml; remove make schemas

Status: Shipped
Type: Feature
Depends On: none
Description: Delete the `make schemas` target. Rewrite `make clone-all` so it uses `yq` to iterate `Specifications/architecture.yaml` and `git clone`s any missing sibling repos (skip existing local clones).

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md (Umbrella Repo Developer Commands still lists `make schemas`)
- ./Makefile (`schemas` target; `clone-all` is a hardcoded repo list with stale `mentorhub_*` names)
- ./Specifications/architecture.yaml
- ./Specifications/product.yaml (`organization.git_org`: `mentor-forge`)
- ./tasks/PENDING.S53.mh_pull_all_git_sync.md (same yq query and `mentorhub_<name>` folder mapping)

## Complexity (keep clone-all in the Makefile)

The current `clone-all` recipe is a simple foreach. Replacing the hardcoded list with a `yq` query plus “clone if missing” is still a short loop — **leave it in the Makefile**. Do not add `scripts/clone-all.sh` unless error handling grows beyond a single loop (per-repo skip/fail log is fine inline). Brew/prereq install is **not** this task (S58).

## Goals

- Remove `schemas` from `.PHONY`, `help`, and the Makefile body. Do not leave a stub that calls the old catalog.yaml curl loop.
- Rewrite `clone-all`:
  - Require `yq` (fail with a message pointing at CONTRIBUTING / `make install` if missing).
  - Iterate journey-domain repos: `.architecture.["journey-domains"][].repos[]`.
  - Skip `type: spa_ref` (configurator_spa, runbook_spa — not git repositories).
  - Map each `name` to sibling folder `../mentorhub_<name>` (parent of this umbrella), matching S53 and the real workspace (`mentorhub_customer_api`, not `mentorhub_customer_api`).
  - Clone URL: `git@github.com:<git_org>/mentorhub_<name>.git` where `<git_org>` comes from `Specifications/product.yaml` `organization.git_org` (already loaded as `ORG` in the Makefile) — currently `mentor-forge`.
  - If `../mentorhub_<name>/.git` exists, log skip (already cloned) and continue. Do **not** `git pull` here (`mh pull all` / S53 owns updates).
  - If the folder is missing, `git clone` into `../mentorhub_<name>`.
  - If a folder exists but is not a git repo, log a warning and continue (do not clone into a non-empty non-git directory).
  - Continue after a per-repo clone failure; non-zero exit if any clone failed.
- Do **not** clone the umbrella (`mentorhub`) itself. Do **not** add `mentorhub_cloudformation` unless you also iterate `architecture.platform.repo`; default is journey-domain `repos[]` only so the list stays aligned with S53.
- Replace the stale hardcoded `mentorhub_*` names in the current `clone-all` target.
- Update `help` text for `clone-all` to say it clones missing architecture.yaml sibling repos via SSH.
- Update CONTRIBUTING “Umbrella Repo Developer Commands”: remove `make schemas`; add `make clone-all` (clone missing siblings from architecture.yaml; skip existing).

## Testing Expectations

- `make help` — no `schemas`; `clone-all` described as architecture.yaml / skip-if-exists.
- Grep Makefile — no `schemas:` target; no hardcoded `mentorhub_mongodb_api` / `mentorhub_customer_api` clone list.
- `yq` dry query matches S53: includes mongodb_api, api_utils, spa_utils, runbook_api, and journey API/SPA names; excludes configurator_spa and runbook_spa.
- `make clone-all` with an already-cloned sibling logs skip for that folder and does not re-clone.
- `make -n clone-all` (or equivalent dry review) shows `git clone git@github.com:mentor-forge/mentorhub_<name>.git`.
- CONTRIBUTING no longer documents `make schemas`.

## Outputs

- `Makefile` — remove `schemas`; yq-driven `clone-all`; help/.PHONY updates.
- `CONTRIBUTING.md` — drop `make schemas`; document `make clone-all`.

## Execution Notes

- Implemented the task only in `Makefile` and `CONTRIBUTING.md`; no script extraction or prerequisite installation was added.
- Removed `schemas` from `.PHONY`, help, and the Makefile body.
- Reworked `clone-all` to require `yq`, select non-`spa_ref` journey-domain repositories from `Specifications/architecture.yaml`, map them to `../mentorhub_<name>`, skip existing git clones, warn and skip existing non-git paths, continue after clone failures, and exit non-zero if any clone failed.
- Updated the Umbrella Repo Developer Commands to remove `make schemas` and document architecture-driven `make clone-all`.
- Tests run:
  - `make help` — passed; no `schemas`, and `clone-all` describes architecture.yaml and skip-existing behavior.
  - Makefile grep for `schemas:`, `mentorhub_mongodb_api`, and `mentorhub_customer_api` — passed with no matches.
  - CONTRIBUTING grep for `make schemas` — passed with no matches.
  - `yq -r '.architecture.["journey-domains"][].repos[] | select(.type != "spa_ref") | .name' Specifications/architecture.yaml` — passed; returned 14 real repositories including mongodb/api/spa utils, runbook API, and journey APIs/SPAs, while excluding configurator_spa and runbook_spa.
  - `make -n clone-all` — passed; showed the yq query, skip/warning branches, failure aggregation, and SSH clone URL `git@github.com:mentor-forge/mentorhub_<name>.git`.
- Follow-ups: none.
