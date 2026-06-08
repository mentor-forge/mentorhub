# R103 – Dev login Stage0 templates (utils, vuetify, umbrella)

**Status:** As Needed  
**Task Type:** Refactor  
**Run Mode:** Run as needed

## Goal

Port the [R102](./AS_NEEDED.R102.dev_login_pilot.md) pilot into Stage0 templates so future `stage0_launch` runs produce the same auth and welcome behavior without hand-editing each repo.

Update and pass self-tests for:

- `stage0_template_vue_utils`
- `stage0_template_vue_vuetify`
- `stage0_template_umbrella`

Prove **parity**: template `test_expected` (or a trial merge) matches pilot behavior.

## Context / Input files

**Read first:**

- [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md)
- Completed **R102** implementation (source of truth for porting):
  - `mentorhub_spa_utils` — `idpRedirect.ts` and tests
  - `mentorhub_customer_spa` — router, client, LoginPage, App.vue
  - `mentorhub` — `index.html`, `login.html`, `welcome-auth.js`, `Dockerfile`, compose, DE standards

**Template repos:**

- `/Users/mikestorey/source/agile-learning-institute/stageZero/stage0_template_vue_utils`
- `/Users/mikestorey/source/agile-learning-institute/stageZero/stage0_template_vue_vuetify`
- `/Users/mikestorey/source/agile-learning-institute/stageZero/stage0_template_umbrella`

## Requirements

### `stage0_template_vue_utils`

- Port `idpRedirect.ts` + tests
- `README.md.template`: IdP redirect docs; replace hardcoded **Control** / **Create** with Jinja (`example_domain`, `example_control`, `example_create` in `process.yaml`)
- Fix duplicate `{{org.git_host}}` in README links
- Refresh `.stage0_template/test_expected/**`

### `stage0_template_vue_vuetify`

- Port router, `client.template.ts`, `client.test.template.ts`, `LoginPage.template.vue`, `App.vue` from pilot SPA
- `Dockerfile`: `ARG VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- Refresh `test_expected`

### `stage0_template_umbrella`

- Port `index.html`, `login.html`, `welcome-auth.js`, `Dockerfile` from pilot umbrella
- `DeveloperEdition/docker-compose.yaml`: `IDP_LOGIN_URI` → `/login.html`
- Update template copies of `Tasks/AS_NEEDED.R100`, `R101`, DE standards
- `process.yaml`: include `login.html` (and JS if used)
- Refresh `test_expected`

### Parity

- Run Stage0 template self-test for all three templates (green)
- Diff or trial-merge `test_expected` against R102 pilot; document intentional diffs in PR

## Testing expectations

- Each template: Stage0 harness / `test_expected` sync passes
- No requirement to launch repos in this task — only template sources and expected outputs

## Dependencies / Ordering

- Run **after** [R102](./AS_NEEDED.R102.dev_login_pilot.md) is **Shipped**
- Run **before** [R105](./AS_NEEDED.R105.architecture_rename_and_relaunch.md) (re-launch consumes templates)

## Change control checklist

- [ ] Read R102 pilot diffs
- [ ] Update all three templates + `test_expected`
- [ ] Template self-tests pass
- [ ] Parity section signed off in PR description
- [ ] Open PR (e.g. `feature/dev-login-templates`); commits reference **R103**

## Implementation notes

_(Fill in when task is executed.)_

## Testing results

_(Fill in when task is executed.)_
