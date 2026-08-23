# S53 – Add git fetch/pull of architecture.yaml repos to `mh pull all`

Status: Shipped
Type: Feature
Depends On: none
Description: When `mh pull all` is used, also iterate repositories listed in `Specifications/architecture.yaml` and run `git fetch && git pull` in each sibling folder, while preserving the existing docker-compose image pull for profile `all`.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md
- ./DeveloperEdition/mh
- ./DeveloperEdition/docker-compose.yaml
- ./Specifications/architecture.yaml
- ./Makefile (`clone-all` sibling folder names)

## Goals

- Add a reusable helper in `DeveloperEdition/mh` that lists real repositories from `$MENTORHUB_PATH/Specifications/architecture.yaml` using `yq`.
  - Query journey-domain repos: `.architecture.["journey-domains"][].repos[]`.
  - Skip entries with `type: spa_ref` (configurator_spa, runbook_spa — not real git folders).
  - Emit at least `name` and `type` (tab-separated is fine).
  - Map each `name` to a sibling folder `$LAUNCHPAD_HOST/mentorhub_<name>` (same naming as `make clone-all`).
  - Fail fast with a clear message if `MENTORHUB_PATH` is unset or `yq` is missing (yq is already a CONTRIBUTING prerequisite).
- When `mh pull` is invoked with parameter `all` (existing `$NEW_PROFILE`):
  - Run the helper and, for each listed repo directory that exists and contains `.git`, `cd` there and run `git fetch && git pull` on the current branch.
  - Log the repo name and command outcome (success or failure, including git stderr).
  - If a mapped folder is missing, log a skip (not cloned) and continue.
  - Continue after a per-repo git failure so remaining repos still update.
  - After the git loop, keep the current behavior: `docker compose --profile all pull` (do not replace image pull with git pull).
- Do **not** change `mh pull` for any profile other than `all`.
- Do **not** switch branches, stash, or reset; only `git fetch && git pull`.
- Extract the architecture.yaml iteration into a named function so S54 (`mh e2e all`) can reuse it.
- Avoid piping `yq` into `while` if that would run the loop in a subshell that loses status; collect names first (zsh array / here-string), then iterate.
- Update the in-script `manual` and `usage` text so `mh pull all` documents both image pull and git sync of architecture.yaml repos.

## Testing Expectations

- `zsh -n DeveloperEdition/mh` — no syntax errors.
- `shellcheck DeveloperEdition/mh` if available (no errors; warnings noted).
- Confirm `yq` query against `Specifications/architecture.yaml` returns real repos only (no `configurator_spa` / `runbook_spa`) and includes `mongodb_api`, `api_utils`, `spa_utils`, `runbook_api`, and all journey API/SPA names.
- Dry-review: `mh pull customer` (or any non-`all` profile) still only runs docker compose pull — no git loop.
- Dry-review or sandboxed run: `mh pull all` logs a git fetch/pull line per mapped folder, then still runs docker compose pull.
- Markdown lint on this task file is not required; no markdown outputs in this task.

## Outputs

- `DeveloperEdition/mh` — architecture.yaml repo helper; `mh pull all` git fetch/pull loop; usage/manual updates.

## Execution Notes

- Plan:
  - Add a reusable architecture repository helper that validates prerequisites
    and emits tab-separated repository names and types.
  - Gate repository synchronization on the exact `all` pull profile, continue
    across missing repositories and git failures, then retain the image pull.
  - Update the command documentation and validate syntax, filtering, and
    profile control flow.
- Commands and results:
  - `zsh -n DeveloperEdition/mh` — passed with no syntax errors.
  - `shellcheck DeveloperEdition/mh` — not run because `shellcheck` is not
    installed.
  - `yq -r '.architecture.["journey-domains"][].repos[] |
    select(.type != "spa_ref") | [.name, .type] | @tsv'
    Specifications/architecture.yaml` — returned 14 real repositories,
    including `mongodb_api`, `api_utils`, `spa_utils`, `runbook_api`, and all
    journey APIs/SPAs; excluded `configurator_spa` and `runbook_spa`.
  - IDE lint check for `DeveloperEdition/mh` — no errors.
  - Dry review of `pull` — the git loop is inside
    `[[ "$NEW_PROFILE" == "all" ]]`; the existing Docker Compose pull remains
    after that condition, so non-`all` profiles skip git and still pull images.
- Follow-ups: none.
