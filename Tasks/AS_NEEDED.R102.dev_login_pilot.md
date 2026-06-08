# R102 – Dev login pilot (umbrella + spa_utils + customer SPA)

**Status:** As Needed  
**Task Type:** Refactor  
**Run Mode:** Run as needed

## Goal

Prove the Developer Edition dev-login flow end-to-end in **live** repos before updating Stage0 templates or touching other journey SPAs.

Deliver:

- Umbrella **developer portal** (`index.html`) and **dev sign-in** (`login.html`) on the welcome nginx container
- `mentorhub_spa_utils` IdP redirect helpers
- `mentorhub_customer_spa` as the **pilot** SPA (guards, `401`, logout, `LoginPage` stub → `login.html`)

## Context / Input files

**Read first:**

- [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md) — overview and target behavior
- [SPA standards](../DeveloperEdition/standards/spa_standards.md)
- `mentorhub_spa_utils/src/utils/urlAuthBootstrap.ts`
- `mentorhub/index.html`, `Dockerfile`, `DeveloperEdition/docker-compose.yaml`
- `mentorhub_customer_spa/src/router/index.ts`, `src/api/client.ts`, `src/pages/LoginPage.vue`, `src/App.vue`

**Repos (implement in place):**

- `mentorhub` (umbrella — **not** re-launched from Stage0)
- `mentorhub_spa_utils`
- `mentorhub_customer_spa`

## Requirements

### `mentorhub_spa_utils`

- Add `src/utils/idpRedirect.ts`: `getIdpLoginBaseUrl`, `buildIdpLoginRedirectUrl`, `redirectToIdpLogin`
- Export from `src/utils/index.ts`; unit tests in `tests/utils/idpRedirect.test.ts`
- `npm run build && npm test` pass

### `mentorhub` (welcome + compose)

- **`index.html`:** catalog only — remove `.welcome-auth`, `setPersonaLink`, static `TOKEN_*`; plain SPA links (no JWT in URL)
- **`login.html`** (+ optional `welcome-auth.js`): `return_to` allowlist; user ID dropdown (Carol … Stan); five role checkboxes (defaults on user change; editable); client-side HS256 mint on Login
- **`Dockerfile`:** `COPY index.html` and `COPY login.html` (and JS if used)
- **`DeveloperEdition/docker-compose.yaml`:** journey SPAs `IDP_LOGIN_URI: http://127.0.0.1:8080/login.html`
- Update `DeveloperEdition/standards/spa_standards.md`, `sre_standards.md`, `api_standards.md` IdP URL examples

### `mentorhub_customer_spa`

- Depend on updated `mentorhub_spa_utils`
- Router guard + API `401` + logout → IdP redirect when `VITE_IDP_LOGIN_URI` set; `/login` fallback when unset
- `LoginPage.vue`: auto-redirect to IdP when configured
- `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html` in Dockerfile / dev env
- `npm run build && npm test && npm run cypress:run` pass

## Testing expectations

**Automated**

- `mentorhub_spa_utils`: `npm test`
- `mentorhub_customer_spa`: `npm test`, `npm run cypress:run`

**Manual (record in PR / implementation notes)**

- [ ] `http://127.0.0.1:8080/` — catalog only; Customer SPA link has no hash
- [ ] Unauthenticated `http://127.0.0.1:8388/` → `login.html?return_to=...`
- [ ] Login with user + roles → Customer SPA authenticated; URL hash stripped
- [ ] Logout → `login.html` with `return_to`
- [ ] `curl` with customer API `e2e_auth.get_auth_token()` still works

**Welcome container**

- Rebuild welcome image; smoke with Developer Edition compose (customer profile minimum)

## Dependencies / Ordering

- Run **before** [R103](./AS_NEEDED.R103.dev_login_stage0_templates.md) (templates port from this pilot)
- Run **before** [R104](./AS_NEEDED.R104.stage0_delete_journey_repos.md)
- Complements [R101](./AS_NEEDED.R101.welcome_personas_from_architecture.md) for persona table alignment on `login.html`

## Change control checklist

- [ ] Read context files and DevLoginLaunchPlan reference section
- [ ] Document approach in **Implementation notes** before large edits
- [ ] Implement `spa_utils`, umbrella welcome, customer SPA
- [ ] Automated tests green
- [ ] Manual smoke completed
- [ ] Open PR on feature branch (e.g. `feature/dev-login-pilot`); scoped commit(s) referencing **R102**

## Implementation notes

_(Fill in when task is executed.)_

## Testing results

_(Fill in when task is executed.)_
