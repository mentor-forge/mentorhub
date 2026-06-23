# R108 – CodeArtifact Phase 5 cleanup (Stage0 SPA template)

**Status:** Running  
**Task Type:** Refactor / SRE  
**Run Mode:** Run as needed

## Goal

Close [DEPENDENCY_MOVE.md](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) **Phase 5** for Stage0 SPA launches: remove git-based `spa_utils` installs from `stage0_template_vue_vuetify`.

## Scope (this task)

| Repo | Change |
|------|--------|
| `stage0_template_vue_vuetify` | CodeArtifact Dockerfile, `.npmrc`, `scripts/docker-build.sh`, CI workflow, `package.json` semver dep |

## Out of scope (follow-up)

- `stage0_template_umbrella` — DE standards still mention git deps for API; sync after umbrella template port
- `stage0_template_flask_mongo` / API template — if still git-based `api_utils`
- `make update` git URL rewrite — still needed for clone/push/GHCR, not spa_utils install

## Requirements

- [x] `package.json`: `"@…/spa_utils": "0.2.2"` not `github:…#main`
- [x] Dockerfile: no `apk add git`, no `GITHUB_TOKEN` build-arg for deps
- [x] `.npmrc` + BuildKit secret pattern (match journey SPAs)
- [x] `docker-push.yml`: OIDC + CodeArtifact npm token
- [x] `test_expected` synced; test `product.yaml` uses `mentor-forge` org for CodeArtifact scope
- [ ] `make test` in template repo (Docker)
- [x] PR opened — [agile-learning-institute/stage0_template_vue_vuetify #3](https://github.com/agile-learning-institute/stage0_template_vue_vuetify/pull/3)
- [ ] PR merged; re-launch smoke optional

## Branch

`stage0_template_vue_vuetify`: `feature/codeartifact-phase5` — pushed via fork `lutherstill-cpu/stage0_template_vue_vuetify` (`origin`); `upstream` = `agile-learning-institute/stage0_template_vue_vuetify`.

## Implementation notes

- Remote URLs repaired on all three Stage0 template repos (`stage0_template_vue_vuetify`, `stage0_template_vue_utils`, `stage0_template_umbrella`): removed expired embedded PATs; `origin` is now `git@github.com:agile-learning-institute/…`.
- `make test` not run here: `ghcr.io/agile-learning-institute/stage0_runbook_merge:latest` pull denied in this environment.
- `DEPENDENCY_MOVE` step table on [mentorhub_cloudformation](https://github.com/mentor-forge/mentorhub_cloudformation/blob/main/docs/specifications/DEPENDENCY_MOVE.md) (Phase 3 done, Phase 5 in progress).
- PR [#3](https://github.com/agile-learning-institute/stage0_template_vue_vuetify/pull/3) opened from fork (read-only on upstream; `lutherstill-cpu` has `pull` only).

## PR (stage0_template_vue_vuetify)

**Open:** https://github.com/agile-learning-institute/stage0_template_vue_vuetify/pull/3
