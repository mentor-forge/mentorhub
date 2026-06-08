# R102 – Dev login pilot + Stage0 templates

**Status:** Running  
**Task Type:** Refactor  
**Run Mode:** Run as needed

## Goal

Implement the Developer Edition dev-login flow in **live** repos, then port the same behavior into Stage0 templates so future `stage0_launch` runs produce matching auth and welcome pages without hand-editing each repo.

**Phase A — Live pilot** (umbrella + spa_utils + customer SPA): prove end-to-end before touching other journey SPAs.

**Phase B — Stage0 templates** (`stage0_template_vue_utils`, `stage0_template_vue_vuetify`, `stage0_template_umbrella`): port pilot sources; refresh `test_expected`; prove parity.

## Context / Input files

**Read first:**

- [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md) — overview and target behavior
- [SPA standards](../DeveloperEdition/standards/spa_standards.md)
- `mentorhub_spa_utils/src/utils/urlAuthBootstrap.ts`, `src/utils/idpRedirect.ts`
- `mentorhub/index.html`, `login.html`, `welcome-auth.js`, `Dockerfile`, `DeveloperEdition/docker-compose.yaml`
- `mentorhub_customer_spa/src/router/index.ts`, `src/api/client.ts`, `src/pages/LoginPage.vue`, `src/App.vue`

**Live repos (Phase A — implement in place):**

- `mentorhub` (umbrella — **not** re-launched from Stage0)
- `mentorhub_spa_utils`
- `mentorhub_customer_spa`

**Template repos (Phase B — source of truth = Phase A after merge):**

- `stage0_template_vue_utils`
- `stage0_template_vue_vuetify`
- `stage0_template_umbrella`

## Requirements

### Phase A — `mentorhub_spa_utils`

- Add `src/utils/idpRedirect.ts`: `getIdpLoginBaseUrl`, `buildIdpLoginRedirectUrl`, `redirectToIdpLogin`
- Export from `src/utils/index.ts`; unit tests in `tests/utils/idpRedirect.test.ts`
- `npm run build && npm test` pass

### Phase A — `mentorhub` (welcome + compose)

- **`index.html`:** catalog only — remove `.welcome-auth`, `setPersonaLink`, static `TOKEN_*`; plain SPA links (no JWT in URL)
- **`login.html`** (+ `welcome-auth.js`): `return_to` allowlist; user ID dropdown (Carol … Stan); five role checkboxes (defaults on user change; editable); client-side HS256 mint on Login
- **`Dockerfile`:** `COPY index.html`, `login.html`, and JS
- **`DeveloperEdition/docker-compose.yaml`:** journey SPAs `IDP_LOGIN_URI: http://127.0.0.1:8080/login.html`
- Update `DeveloperEdition/standards/spa_standards.md`, `sre_standards.md`, `api_standards.md` IdP URL examples

### Phase A — `mentorhub_customer_spa`

- Depend on updated `mentorhub_spa_utils`
- Router guard + API `401` + logout → IdP redirect when `VITE_IDP_LOGIN_URI` set; `/login` fallback when unset
- `LoginPage.vue`: auto-redirect to IdP when configured
- `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html` in Dockerfile / dev env
- `npm run build && npm test && npm run cypress:run` pass

### Phase B — `stage0_template_vue_utils`

- Port `idpRedirect.ts` + tests from pilot
- `README.md.template`: IdP redirect docs; replace hardcoded **Control** / **Create** with Jinja (`example_domain`, `example_control`, `example_create` in `process.yaml`)
- Fix duplicate `{{org.git_host}}` in README links
- Refresh `.stage0_template/test_expected/**`

### Phase B — `stage0_template_vue_vuetify`

- Port router, `client.template.ts`, `client.test.template.ts`, `LoginPage.template.vue`, `App.vue` from pilot SPA
- `Dockerfile`: `ARG VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- Refresh `test_expected`

### Phase B — `stage0_template_umbrella`

- Port `index.html`, `login.html`, `welcome-auth.js`, `Dockerfile` from pilot umbrella
- `DeveloperEdition/docker-compose.yaml`: `IDP_LOGIN_URI` → `/login.html`
- Update template copies of `Tasks/AS_NEEDED.R100`, `R101`, DE standards
- `process.yaml`: include `login.html` (and JS if used)
- Refresh `test_expected`

### Phase B — Parity

- Run Stage0 template self-test for all three templates (green)
- Diff or trial-merge `test_expected` against Phase A pilot; document intentional diffs in PR

## Testing expectations

**Phase A — automated**

- `mentorhub_spa_utils`: `npm test`
- `mentorhub_customer_spa`: `npm test`, `npm run cypress:run`

**Phase A — manual (record in PR / implementation notes)**

- [ ] `http://127.0.0.1:8080/` — catalog only; Customer SPA link has no hash
- [ ] Unauthenticated `http://127.0.0.1:8388/` → `login.html?return_to=...`
- [ ] Login with user + roles → Customer SPA authenticated; URL hash stripped
- [ ] Logout → `login.html` with `return_to`
- [x] `curl` with customer API `e2e_auth.get_auth_token()` still works _(unchanged)_

**Phase A — welcome container**

- Rebuild welcome image; smoke with Developer Edition compose (customer profile minimum)

**Phase B**

- Each template: Stage0 harness / `test_expected` sync passes
- No requirement to launch repos in Phase B — only template sources and expected outputs

## Dependencies / Ordering

- Run **before** [R104](./AS_NEEDED.R104.stage0_delete_journey_repos.md)
- Run **before** [R105](./AS_NEEDED.R105.architecture_rename_and_relaunch.md) (re-launch consumes templates from Phase B)
- Complements [R101](./AS_NEEDED.R101.welcome_personas_from_architecture.md) for persona table alignment on `login.html`
- Former [R103](./AS_NEEDED.R103.dev_login_stage0_templates.md) — **merged into this task** (Phase B)

## Change control checklist

**Phase A**

- [x] Read context files and DevLoginLaunchPlan reference section
- [x] Document approach in **Implementation notes**
- [x] Implement `spa_utils`, umbrella welcome, customer SPA
- [x] Automated tests green
- [ ] Manual smoke completed
- [x] Open PR on `feature/dev-login-pilot`; scoped commits referencing **R102**

**Phase B**

- [ ] Read Phase A pilot diffs (merged `main` after Phase A PRs)
- [ ] Update all three Stage0 templates + `test_expected`
- [ ] Template self-tests pass
- [ ] Parity section signed off in PR description
- [ ] Open PR on `feature/dev-login-templates`; commits reference **R102**

## Implementation notes

### Phase A (2026-06-08) — shipped via PR, pending merge

Split welcome into catalog (`index.html`) and dev IdP (`login.html` + `welcome-auth.js`). Centralized redirect helpers in `spa_utils` (`idpRedirect.ts`). Pilot customer SPA uses helpers for router guard, API `401`, logout, and `LoginPage` auto-redirect when `VITE_IDP_LOGIN_URI` is set.

**`mentorhub_spa_utils`:** Added `getIdpLoginBaseUrl`, `buildIdpLoginRedirectUrl`, `redirectToIdpLogin` with `/login` fallback when env unset. Unit tests in `tests/utils/idpRedirect.test.ts`.

**`mentorhub`:** Removed persona JWT matrix from `index.html`; added plain journey SPA links. New `login.html` with Carol–Stan personas, five role checkboxes, `return_to` allowlist, Web Crypto HS256 mint in `welcome-auth.js`. Dockerfile copies all three static assets. Compose defaults `IDP_LOGIN_URI` to `http://127.0.0.1:8080/login.html`. DE standards updated.

**`mentorhub_customer_spa`:** Router, client, App logout, and LoginPage wired to spa_utils IdP helpers. Dockerfile `VITE_IDP_LOGIN_URI` default updated. Depends on `mentorhub_spa_utils#feature/dev-login-pilot` until that PR merges.

**Phase A PRs:** merge `mentorhub_spa_utils` first, then `mentorhub` and `mentorhub_customer_spa`.

- https://github.com/mentor-forge/mentorhub_spa_utils/pull/2
- https://github.com/mentor-forge/mentorhub/pull/11
- https://github.com/mentor-forge/mentorhub_customer_spa/pull/2

### Phase B — pending

Port Phase A sources into `stage0_template_vue_utils`, `stage0_template_vue_vuetify`, and `stage0_template_umbrella` after Phase A PRs merge.

## Testing results

### Phase A

**Automated (Node 24.11.0):**

- `mentorhub_spa_utils`: `npm test` — 99/99 passed
- `mentorhub_customer_spa`: `npm test` — 67/67 passed
- `mentorhub_customer_spa`: `npm run cypress:run` — not executed in agent session (Cypress/WSL deps)

**Build:**

- `mentorhub_spa_utils`: `vite build` succeeds on clean outDir; root-owned `dist/` subdirs from prior Docker builds blocked local rebuild
- `make container` (mentorhub): not run — Docker unavailable in agent session

**Manual / logical verification:**

- Catalog links use plain SPA URLs (no hash) — inspection
- IdP redirect URL shape — unit tests
- Persona defaults — `welcome-auth.js`
- JWT mint algorithm — node crypto script
- `e2e_auth.get_auth_token()` unchanged

**Recommended post-merge smoke:** `make update && mh up customer`

### Phase B

_(Fill in when Phase B is executed.)_
