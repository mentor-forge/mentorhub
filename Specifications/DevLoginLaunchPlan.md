# Dev Login & Stage0 Launch Plan

**Status:** Proposed  
**Delivery:** Feature-branch PRs per phase below.  
**Supersedes:** [DevLoginRefactor.md](./DevLoginRefactor.md), [TEMPLATE_UPDATE.md](./TEMPLATE_UPDATE.md) (redirect stubs only).

## Workflow

```text
Phase 1  Implement + test in mentorhub, mentorhub_spa_utils, mentorhub_customer_spa (pilot)
    ↓
Phase 2  Port to stage0 templates; prove generated code matches pilot
    ↓
Phase 3  stage0_launch — delete mentorhub_spa_utils + all journey *_api / *_spa repos
    ↓
Phase 4  Team updates Specifications/architecture.yaml (new domain/repo names)
    ↓
Phase 5  stage0_launch — re-create spa_utils + journey api/spa from templates
```

**Umbrella `mentorhub` is not re-launched** in Phase 3/5. Welcome changes stay in the live umbrella repo (Phase 1).

**Default env:** `VITE_IDP_LOGIN_URI` / `IDP_LOGIN_URI` = `http://127.0.0.1:8080/login.html`

---

## Phase 1 — Pilot implementation (PR 1)

**Repos:** `mentorhub`, `mentorhub_spa_utils`, `mentorhub_customer_spa`  
**Branch:** e.g. `feature/dev-login-pilot`  
**Goal:** End-to-end dev login works for Customer journey before touching templates or other SPAs.

### 1.1 `mentorhub_spa_utils`

- [ ] Add `src/utils/idpRedirect.ts`: `getIdpLoginBaseUrl`, `buildIdpLoginRedirectUrl`, `redirectToIdpLogin`
- [ ] Export from `src/utils/index.ts`; add `tests/utils/idpRedirect.test.ts`
- [ ] (Optional this PR) `cy.loginAsPersona`, `devPersonas` map — can defer to Phase 2
- [ ] `npm run build && npm test` pass

### 1.2 `mentorhub` (welcome + compose)

- [ ] Split welcome: **`index.html`** = catalog only (remove `.welcome-auth`, `setPersonaLink`, `TOKEN_*`)
- [ ] Add **`login.html`** (+ optional `welcome-auth.js`): user dropdown, five role checkboxes, `return_to` validation, client-side HS256 mint on Login
- [ ] `Dockerfile`: `COPY index.html` and `COPY login.html`
- [ ] `DeveloperEdition/docker-compose.yaml`: all journey SPAs `IDP_LOGIN_URI: http://127.0.0.1:8080/login.html`
- [ ] Update `DeveloperEdition/standards/spa_standards.md`, `sre_standards.md`, `api_standards.md` IdP URL examples
- [ ] Rebuild welcome image / `docker compose` smoke

### 1.3 `mentorhub_customer_spa` (pilot SPA)

- [ ] Bump dependency on updated `mentorhub_spa_utils`
- [ ] `src/router/index.ts`: unauthenticated → `redirectToIdpLogin` when `VITE_IDP_LOGIN_URI` set; else `/login` fallback
- [ ] `src/api/client.ts`: `401` → same IdP redirect
- [ ] `src/pages/LoginPage.vue`: auto-redirect to IdP when env set
- [ ] `src/App.vue` `handleLogout`: IdP redirect when env set
- [ ] `Dockerfile` / `.env`: `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- [ ] `npm run build && npm test && npm run cypress:run` pass

### 1.4 Manual verification (record in PR)

- [ ] `http://127.0.0.1:8080/` — catalog links only; Customer SPA link has **no** hash
- [ ] Open `http://127.0.0.1:8388/` unauthenticated → `login.html?return_to=...`
- [ ] Pick user + roles → Login → Customer SPA authenticated; hash stripped
- [ ] Logout → returns to `login.html` with `return_to`
- [ ] `curl` with `e2e_auth.get_auth_token()` still works against customer API

### PR 1 done when

All 1.1–1.4 checkboxes pass; no template or other SPA changes in this PR.

---

## Phase 2 — Templates + parity (PR 2)

**Repos:** `stage0_template_vue_utils`, `stage0_template_vue_vuetify`, `stage0_template_umbrella`  
**Branch:** e.g. `feature/dev-login-templates` (can stack on Phase 1 merge or parallel after Phase 1 lands)  
**Goal:** Template output matches Phase 1 pilot code.

### 2.1 `stage0_template_vue_utils`

- [ ] Port `idpRedirect.ts` + tests from `mentorhub_spa_utils`
- [ ] `README.md.template`: IdP docs; replace hardcoded **Control** / **Create** with Jinja (`example_domain`, `example_control`, `example_create` in `process.yaml`)
- [ ] Fix `{{org.git_host}}/{{org.git_host}}` link typos in README template
- [ ] Refresh `.stage0_template/test_expected/**`

### 2.2 `stage0_template_vue_vuetify`

- [ ] Port router, `client.template.ts`, `client.test.template.ts`, `LoginPage.template.vue`, `App.vue` from pilot `customer_spa`
- [ ] `Dockerfile`: `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- [ ] Refresh `test_expected`

### 2.3 `stage0_template_umbrella`

- [ ] Port `index.html`, `login.html`, `welcome-auth.js`, `Dockerfile` from pilot `mentorhub`
- [ ] `DeveloperEdition/docker-compose.yaml`: `IDP_LOGIN_URI` → `/login.html`
- [ ] Update `Tasks/AS_NEEDED.R100`, `R101`, DE standards in template
- [ ] `process.yaml`: include `login.html` (and JS if used)
- [ ] Refresh `test_expected`

### 2.4 Parity check

- [ ] Run Stage0 template tests for all three templates (green)
- [ ] Merge templates against **current** `mentorhub` `architecture.yaml` into a temp dir OR diff `test_expected` against Phase 1 pilot files for equivalent behavior (auth redirect, welcome split, persona UI)
- [ ] Document any intentional diffs in PR 2 description

### PR 2 done when

Templates pass self-test and parity section signed off.

---

## Phase 3 — Delete journey repos (PR 3)

**Repo:** `mentorhub` (launch config / runbook only — no code delete in umbrella git)  
**Branch:** e.g. `feature/stage0-delete-journey-repos`  
**Prerequisite:** Phase 1 merged; Phase 2 merged (templates ready for Phase 5).

### 3.1 `stage0_launch` delete

- [ ] Delete **`mentorhub_spa_utils`**
- [ ] Delete each journey **`mentorhub_*_api`** and **`mentorhub_*_spa`** (customer, coordinator, mentor, craftsperson — all domains in `architecture.yaml` except schema/common_code utilities)
- [ ] Do **not** delete umbrella `mentorhub`, `mentorhub_mongodb_api`, `mentorhub_runbook_api`, or other non-journey repos
- [ ] Record launch commands / checklist in PR (exact `stage0_launch` invocations per your DE docs)

### PR 3 done when

Target repos removed from GitHub (or org); umbrella specs unchanged except optional launch notes.

---

## Phase 4 — Architecture rename (PR 4)

**Repo:** `mentorhub`  
**Branch:** e.g. `feature/architecture-rename`  
**Prerequisite:** Team agrees new domain names, ports, repo names.

### 4.1 Specification updates

- [ ] Update `Specifications/architecture.yaml` (domain names, repos, ports)
- [ ] Update `Specifications/catalog.yaml`, `product.yaml`, journeys/stakeholders as needed
- [ ] Update `DeveloperEdition/docker-compose.yaml` for new service names/ports (welcome service unchanged)
- [ ] Update `index.html` catalog ports/links (R100) — **not** `login.html` persona logic unless roles change
- [ ] Update architecture diagrams if maintained (`ArchitectureDiagram.*`)
- [ ] Run **R100** task checklist after yaml stabilizes

### PR 4 done when

Architecture PR reviewed and merged; launch inputs documented for Phase 5.

---

## Phase 5 — Re-launch journey repos (PR 5)

**Repo:** `mentorhub` (+ new repos created by launch)  
**Branch:** N/A — launch ops; track in issue/PR with created repo list  
**Prerequisite:** Phase 3 complete; Phase 4 merged; templates from Phase 2.

### 5.1 `stage0_launch` create

- [ ] Launch **`mentorhub_spa_utils`** from `stage0_template_vue_utils`
- [ ] Launch each journey **`mentorhub_{domain}_api`** and **`mentorhub_{domain}_spa`** from api/spa templates per new `architecture.yaml`
- [ ] Verify each new SPA: `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- [ ] `npm run build && npm test` (and `cypress:run` on one SPA) on launched repos

### 5.2 Roll out remaining SPAs (if not all launched in 5.1)

- [ ] Apply same auth pattern to coordinator, mentor, craftsperson SPAs (should be generated from template; fix only if launch drift)

### 5.3 Umbrella alignment

- [ ] Confirm live `mentorhub` welcome + compose still match launched SPAs (ports from R100)
- [ ] Optional: small PR to umbrella if catalog ports/names need post-launch tweaks only

### Phase 5 done when

All journey api/spa pairs exist, CI green, manual smoke: portal → SPA → `login.html` → authenticated app for at least two domains.

---

## Reference — target behavior

### Welcome (static nginx, port 8080)

| File | URL | Purpose |
|------|-----|---------|
| `index.html` | `/` | Catalog: API explorers, repos, **plain** SPA links (no JWT) |
| `login.html` | `/login.html` | Dev IdP: `?return_to=` + user/roles + Login → hash on SPA origin |

No Flask. No token mint API.

### Personas (`login.html`)

| User (dropdown) | `sub` | Default roles |
|-----------------|-------|---------------|
| Carol | `carol` | `coordinator` |
| Maria | `maria` | `mentor` |
| Cat | `cat` | `customer` |
| Mark | `mark` | `mentee` |
| Stan | `stan` | `admin` |

On user change: reset checkboxes to defaults. User may add/remove roles before Login. Mint JWT client-side (`local-dev-jwt-secret-fixed`, `iss: dev-idp`, `aud: dev-api`). Hash `roles` comma-separated; must match JWT `roles` array.

`return_to`: allowlist `http://127.0.0.1:*` and `http://localhost:*` only. Login disabled without valid `return_to`.

### SPA / `spa_utils`

- `bootstrapAuthFromUrl()` in `initAuth.ts` (unchanged)
- Guards + `401` + logout → `buildIdpLoginRedirectUrl(VITE_IDP_LOGIN_URI, window.location.href)`
- Vue `/login` = redirect stub when IdP configured; not the persona picker

### Cypress / curl

- **E2E:** keep `cy.login()` / `cy.login(roles)` — do not drive `login.html` in domain specs
- **curl:** `test/e2e/e2e_auth.get_auth_token()` (default Stan/admin after RBAC alignment)
- **API Explorer:** manual Authorize or optional future hash bootstrap (out of scope unless requested)

### Automation IDs (`login.html`)

`welcome-login-user-id`, `welcome-login-role-coordinator` … `welcome-login-role-admin`, `welcome-login-submit`, `welcome-back-to-portal`

---

## PR checklist summary

| PR | Scope | Merge gate |
|----|--------|------------|
| **1** | `mentorhub` + `spa_utils` + `customer_spa` | Manual smoke + unit/E2E green |
| **2** | Three Stage0 templates + parity | Template self-test green |
| **3** | `stage0_launch` delete | Repos deleted per list |
| **4** | `architecture.yaml` + R100 | Team review |
| **5** | `stage0_launch` create | New repos CI + smoke |

---

## Key paths (pilot)

| Repo | Files |
|------|--------|
| `mentorhub` | `index.html`, `login.html`, `welcome-auth.js`, `Dockerfile`, `DeveloperEdition/docker-compose.yaml`, DE standards |
| `mentorhub_spa_utils` | `src/utils/idpRedirect.ts`, tests, exports |
| `mentorhub_customer_spa` | `src/router/index.ts`, `src/api/client.ts`, `LoginPage.vue`, `App.vue`, `Dockerfile` |
| Templates | `stage0_template_vue_utils`, `stage0_template_vue_vuetify`, `stage0_template_umbrella` |

---

## Related

- [R101](../Tasks/AS_NEEDED.R101.welcome_personas_from_architecture.md) — persona defaults on `login.html`
- [R100](../Tasks/AS_NEEDED.R100.after_specs_update.md) — catalog ports after architecture changes
- [SPA standards](../DeveloperEdition/standards/spa_standards.md)
