# Dev Login / Welcome Page Refactor

**Status:** Proposed  
**Scope:** Developer Edition only (`index.html`, `login.html`, welcome nginx container, journey SPA auth redirects)  
**Prerequisite:** Complete [TEMPLATE_UPDATE.md](./TEMPLATE_UPDATE.md) Parts A–B and re-launch `*_spa_utils` / `*_spa` repos. **Umbrella:** implement this spec **in place** on `mentorhub` (no umbrella re-launch); new products receive the same split from `stage0_template_umbrella` Part E.  
**Related:** [TEMPLATE_UPDATE.md](./TEMPLATE_UPDATE.md), [SPA standards](../DeveloperEdition/standards/spa_standards.md), [API standards](../DeveloperEdition/standards/api_standards.md), [SRE standards](../DeveloperEdition/standards/sre_standards.md), [R101](../Tasks/AS_NEEDED.R101.welcome_personas_from_architecture.md)

## Executive summary

**Yes, this can work.** The platform already defines an IdP-shaped contract: the welcome page issues tokens via URL hash; SPAs call `bootstrapAuthFromUrl()` before the router mounts. Extending that with a **return URL** (link-back) from router guards makes the welcome page behave like a dev IdP and removes the need for the welcome page to hardcode every journey SPA port for sign-in.

**Yes, link-back addresses the port-number problem** for authentication: the SPA passes its full origin (`http://localhost:8388`, etc.) when redirecting to welcome; after login, the browser returns to that exact origin with the hash bootstrap. The welcome page no longer needs a persona matrix keyed by port—only a service catalog (R100) still reads ports from `architecture.yaml`.

**Gap today:** Standards say unauthenticated users should go to `VITE_IDP_LOGIN_URI` (welcome). Implementation still sends users to each SPA’s `/login` route, and `index.html` embeds **Genny/Adam persona links** (`setPersonaLink`) that bake tokens and ports into the catalog—**that pattern is removed**.

**Welcome UX (target):** Split the welcome container into two static pages—**catalog** vs **sign-in** (see [Two-page welcome (static nginx)](#two-page-welcome-static-nginx)). Personas and `return_to` live only on **`login.html`**, not on `index.html`.

**Personas (target):** Replace **Genny** / **Adam** with five named dev personas—each maps to exactly **one** JWT role (see [Developer personas and roles](#developer-personas-and-roles)).

---

## Two-page welcome (static nginx)

**No Flask, no monorepo auth service**—still the existing **nginx** welcome image; add a second static file.

| Page | URL (port 8080) | Purpose |
|------|-----------------|--------|
| **Developer portal** | `/` → `index.html` | Service catalog only: API explorers, GitHub repos, schema links. **Plain** links to each SPA origin (e.g. `http://127.0.0.1:8388/`) with **no** JWT hash and **no** `setPersonaLink` / persona-return_to buttons. |
| **Dev sign-in (IdP)** | `/login.html` → `login.html` | IdP-style UI: pick persona (and optional role controls), **Login** → `{return_to}#access_token=...`. Parses `?return_to=` from query string. Link back to `/` (“Developer portal”). |

**`VITE_IDP_LOGIN_URI` / `IDP_LOGIN_URI` default** (compose, SPA Dockerfile):

```text
http://127.0.0.1:8080/login.html
```

(trailing slash optional; helpers should normalize.)

**How users reach sign-in**

1. **From catalog:** Click unauthenticated SPA link → SPA loads → guard / `401` → redirect to `login.html?return_to=<SPA URL>`.
2. **Direct:** Open a deep link on the SPA → same redirect to `login.html`.
3. **Logout:** SPA clears storage → redirect to `login.html?return_to=...` (optional `clear_stored_auth` on SPA first).

**Per-SPA `LoginPage.vue` (after [TEMPLATE_UPDATE](./TEMPLATE_UPDATE.md)):** Not where personas are chosen—only redirects to `login.html` when `VITE_IDP_LOGIN_URI` is set (or a minimal fallback when unset). Product “login” for Developer Edition is **`login.html` on the welcome host**, not the Vue `/login` route.

**Dockerfile:** `COPY index.html` and `COPY login.html` into `/usr/share/nginx/html/`.

**What we are explicitly not doing on `index.html`**

- No Genny/Adam (or Carol … Stan) matrix links that open SPAs with pre-built hash URLs.
- No `return_to` / Login controls on the catalog page.
- No mint API on welcome nginx (optional dev-only client sign stays on `login.html` only if ever needed).

---

## Developer personas and roles

### Persona defaults (user ID → default roles)

| Display name (dropdown label) | JWT `sub` | Default role(s) checked on select | Primary journey (catalog hint) |
|-------------------------------|-----------|-----------------------------------|--------------------------------|
| **Carol** | `carol` | `coordinator` | Coordinator SPA |
| **Maria** | `maria` | `mentor` | Mentor SPA |
| **Cat** | `cat` | `customer` | Customer SPA |
| **Mark** | `mark` | `mentee` | Craftsperson SPA (mentee user journey) |
| **Stan** | `stan` | `admin` | SRE / cross-cutting; SPA `/admin` and elevated API checks |

**Allowed roles in the UI (checkboxes):** `coordinator`, `mentor`, `customer`, `mentee`, `admin` — the five product roles. User can check any combination before **Login** (e.g. Stan with `admin` only, or Cat with `customer` + `mentee` for experiments).

### Sign-in UI (`login.html` only)

1. **User ID** — `<select>` (dropdown): Carol, Maria, Cat, Mark, Stan. Value = `sub`. On `change`, reset role checkboxes to that persona’s **default** row in the table above (replace previous checks, do not merge).
2. **Roles** — five checkboxes (or multi-select) labeled with the role names. User may **add or remove** roles after picking a user; defaults are a starting point only.
3. **Login** — enabled when `return_to` is valid and at least one role is checked. Build JWT with selected `sub` + `roles[]`, then redirect to `return_to` + hash.

**JWT / hash must agree:**

- Claim: `roles: ["customer", "mentee"]` (array).
- Hash: `roles=customer,mentee` (comma-separated, same order as `bootstrapAuthFromUrl` / SPA `localStorage`).

**Token at Login time (not five static strings):** Because roles are editable, **Login always mints** a fresh HS256 JWT for the chosen `sub` + role set. Recommended for Developer Edition: **client-side sign** in `login.html` using the same dev secret as compose (`local-dev-jwt-secret-fixed`) and claims `iss: dev-idp`, `aud: dev-api`, long `exp`. Optional: precompute default tokens only for a “quick login” shortcut—secondary to the dropdown + checkbox flow.

**`index.html`:** No tokens, no sign-in controls.

Persona table and secret alignment: [R101](../Tasks/AS_NEEDED.R101.welcome_personas_from_architecture.md). **Production welcome image must not embed the signing secret** (dev-only banner on `login.html`).

**RBAC follow-on (not blocked by welcome UI):** Journey code and APIs today still reference template roles such as `developer`, `staff`, and `admin` in services and tests. Align domain RBAC and `requiresRole` checks to the five product roles (`customer`, `mentor`, `coordinator`, `mentee`, `admin`) in a separate pass; until then, **Stan (`admin`)** remains the persona for `/admin` and admin-gated API tests, and domain personas exercise each journey’s nominal role.

**Cypress / curl defaults:**

| Use case | Persona |
|----------|---------|
| Domain feature specs | `cy.loginAsPersona('cat')`, `cy.loginAsPersona('carol')`, etc. |
| Admin page / admin API | `cy.loginAsPersona('stan')` or `get_auth_token()` minting `sub: stan`, `roles: [admin]` |
| Generic automated JWT | Keep `cypress-user` only if a test needs a non-product subject |

---

## Current state

### Welcome container (port 8080)

| Asset | Today | Target |
|-------|-------|--------|
| **`index.html`** | Catalog + Genny/Adam persona links (`setPersonaLink`) | **Catalog only** — plain SPA/API/repo links (R100 ports in script) |
| **`login.html`** | Does not exist | **Dev IdP** — personas, `return_to`, Login redirect |
| **Tokens in HTML** | `TOKEN_GENNY` / `TOKEN_ADAM` on index | **`login.html` mints JWT on Login** from user + role checkboxes (dev secret in page) |

### SPA auth (standards vs code)

| Layer | Intended (standards) | Actual (journey SPAs) |
|--------|----------------------|------------------------|
| Unauthenticated navigation | Redirect to `VITE_IDP_LOGIN_URI` (welcome) | `router.beforeEach` → local `{ name: 'Login', query: { redirect } }` |
| Token delivery | Hash on SPA origin | Welcome opens SPA with hash (manual links) |
| `401` from API client | Login base URL | `window.location.href = '/login?redirect=...'` |
| Post-auth | `bootstrapAuthFromUrl()` in `initAuth.ts` | Already in place |

`bootstrapAuthFromUrl()` ([`mentorhub_spa_utils`](../mentorhub_spa_utils/src/utils/urlAuthBootstrap.ts)) already:

- Reads `#access_token`, `expires_at`, `roles` into `localStorage`.
- Strips the hash from the URL (no token left in history).
- Supports `?clear_stored_auth=1` for logout / re-login flows.

Per-SPA `LoginPage.vue` only **links** to welcome (`target="_blank"`) without `return_to`, so the IdP flow is disconnected from guards.

---

## Target experience

### Journey A — start from developer portal

1. Developer opens **`http://127.0.0.1:8080/`** (`index.html`) — links only, no sign-in form.
2. Clicks **Customer SPA** (plain `http://127.0.0.1:8388/`, no token in URL).
3. SPA guard redirects to dev sign-in:

   ```text
   http://127.0.0.1:8080/login.html?return_to=<url-encoded SPA URL>
   ```

4. On **`login.html`**, user picks **User ID** (e.g. Cat) → roles default to `customer`; user may toggle other role checkboxes, then **Login**.
5. Browser navigates **same window** to:

   ```text
   {return_to}#access_token=JWT&expires_at=ISO8601&roles=customer
   ```

   (If multiple roles checked: `roles=customer,mentee`, etc.)

6. `bootstrapAuthFromUrl()` runs; user continues in the SPA at the intended path.

### Journey B — deep link (skip catalog)

1. Open `http://127.0.0.1:8388/subscriptions` without a token.
2. Guard → `login.html?return_to=...` (same as steps 4–6 above).

### `login.html` UX

- Commercial IdP look: focused card, “Mentor Hub – Development Sign-In”, local-dev disclaimer.
- **User ID** dropdown (Carol … Stan).
- **Roles** checkboxes for all five product roles; defaults applied on user change; user can edit before Login.
- **Login** disabled if no roles selected or `return_to` invalid.
- If `return_to` missing or invalid: show error or message to open an app from the portal first.
- Footer link: **Back to developer portal** → `/`.

### `index.html` UX

- Keep existing service blocks (Schema, Customer, …) and API Explorer links.
- SPA links: **origin only** (or `/` path)—authentication is always SPA → `login.html` → hash callback.
- Optional small text: “SPAs will prompt for sign-in” — no persona buttons.

### Automation IDs (`login.html`)

| Element | `data-automation-id` |
|---------|----------------------|
| User ID dropdown | `welcome-login-user-id` |
| Role checkbox | `welcome-login-role-coordinator`, … `welcome-login-role-admin` |
| Login button | `welcome-login-submit` |
| Back to portal | `welcome-back-to-portal` |

---

## Link-back (`return_to`) and the port problem

### Problem today

`setPersonaLink()` on **`index.html`** duplicates SPA ports and embeds tokens in catalog links. That goes away: catalog uses **plain hrefs**; ports for links still come from `architecture.yaml` (R100), but **auth ports** come only from `return_to` when the SPA sends the user to **`login.html`**.

### Why link-back fixes auth ports

| Concern | Persona matrix (today) | Link-back (proposed) |
|---------|------------------------|----------------------|
| Who knows SPA port? | Welcome script | **Calling SPA** (guard builds `return_to` from `window.location.origin`) |
| Deep link after login | New tab; user may lose context | Same tab; `return_to` preserves path |
| New journey domain | Update welcome + architecture | Guard only; welcome unchanged for auth |
| Hash bootstrap host | Must match SPA origin | `return_to` origin is always correct |

**Service catalog links** (Schema, Customer API explorer, etc.) still need ports from architecture (R100)—that is unrelated to auth link-back.

### Parameter name

Prefer **`return_to`** (clear, common in dev IdPs) or align with OAuth2 **`redirect_uri`**. Pick one name in code and standards; document it in `spa_standards.md` when implemented.

---

## SPA changes (journey SPAs + `spa_utils`)

> **Template-first:** Items 1–4 and LoginPage/logout behavior are specified in [TEMPLATE_UPDATE.md](./TEMPLATE_UPDATE.md) for `stage0_template_vue_utils` and `stage0_template_vue_vuetify`. After re-launch, verify Mentor Hub repos match; patch manually only if a domain repo diverged from template.

### 1. Centralize “redirect to IdP” helper

Add to `@mentor-forge/mentorhub_spa_utils` (e.g. `buildIdpLoginRedirectUrl(baseUrl: string, returnTo?: string): string`):

- `baseUrl` from `import.meta.env.VITE_IDP_LOGIN_URI` (trim trailing slash).
- Append `?return_to=` + `encodeURIComponent(returnTo ?? window.location.href)` (or origin + pathname only if hash in `href` is undesirable).

### 2. Router guard

Replace local login redirect when `VITE_IDP_LOGIN_URI` is set:

```typescript
// Pseudocode — Developer Edition
if (to.meta.requiresAuth && !isAuthenticated.value) {
  const idp = import.meta.env.VITE_IDP_LOGIN_URI
  if (idp) {
    window.location.assign(buildIdpLoginRedirectUrl(idp, window.location.href))
    return
  }
  next({ name: 'Login', query: { redirect: to.fullPath } })
}
```

Production keeps real IdP URL in `VITE_IDP_LOGIN_URI`; same helper can pass `return_to` if the commercial IdP supports it.

### 3. API client `401` handler

Use the same IdP redirect instead of `/login` when configured (matches [SRE Authentication Redirect Pattern](../DeveloperEdition/standards/sre_standards.md)).

### 4. Per-SPA `/login` route

**Option A (recommended for Developer Edition):** Remove or reduce to a 302-style page that immediately redirects to `VITE_IDP_LOGIN_URI` with `return_to` (bookmarks to `/login` still work).

**Option B:** Keep `LoginPage.vue` for production messaging only when `VITE_IDP_LOGIN_URI` is unset.

### 5. E2E / Cypress

- Unauthenticated visit → assert redirect to `login.html?return_to=...` (not catalog `/`).
- `login.html` Login → assert landing on SPA with token in `localStorage` and hash stripped.
- Update navigation tests that expect `/login`.

---

## Welcome page changes

### 1. Split and simplify `index.html`

- Remove entire **welcome-auth** / persona sections and `setPersonaLink`, `TOKEN_*`, `spaAuthHash` from index.
- Keep service catalog script (ports for API explorer + SPA **plain** links).
- Add optional link: “Sign in” → `/login.html` (no `return_to`) for manual IdP visit.

### 2. Add `login.html`

- Shared styles with index (copy or small `welcome.css`).
- Parse `return_to` on load; validate (see security).
- If present: headline “Sign in to continue” + hint from `return_to` host/port (e.g. Customer SPA on `:8388`).
- If missing: show form only; **Login** disabled or shows “Open an application from the [developer portal](/) first” (no automatic redirect into a SPA with a token).

### 3. Login form → redirect builder

Move `spaAuthHash(token, rolesComma)` to `login.html` (or shared `welcome-auth.js`). Target URL is `return_to + spaAuthHash(...)`, **same window** (`window.location.assign`).

### 4. Token mint on Login (client-side, dev-only)

| Approach | Fits editable roles? |
|----------|----------------------|
| **Client-side HS256 sign** (`login.html` + dev secret) | **Yes — recommended** |
| Static preset JWT per persona | Only default role combo; breaks when user changes checkboxes |
| Mint API on nginx | No — out of scope |

**Implementation sketch (`welcome-auth.js` or inline):**

- `PERSONAS` map: `{ carol: { label: 'Carol', defaultRoles: ['coordinator'] }, ... }`.
- `ALL_ROLES = ['coordinator','mentor','customer','mentee','admin']`.
- On user dropdown `change`: set checkboxes to `defaultRoles`.
- On Login: read checked roles → `signDevJwt({ sub, roles })` → `spaAuthHash(token, roles.join(','))` → `location.assign(return_to + hash)`.
- Use a small browser JWT library (e.g. bundled `jose` or minimal HS256) or prebuilt sign function; keep bundle size modest for a dev page.

JWT claims: `iss`, `aud`, `sub`, `exp`, `roles` (array matching checkboxes). Hash `roles` comma-separated. At least one role required.

### 5. Logout / switch user

SPAs clear `localStorage`; redirect to:

```text
http://127.0.0.1:8080/login.html?return_to=...
```

(Optional: SPA visits self with `?clear_stored_auth=1` before that redirect.)

### 6. Service catalog (`index.html` only)

R100 port wiring for API explorer and **unauthenticated** SPA links only.

---

## Security (Developer Edition)

- **`return_to` validation (required):** Allow only `http://127.0.0.1:*` and `http://localhost:*` (and optionally `http://{window.location.hostname}:*` when welcome is opened via LAN hostname). Reject missing host, `javascript:`, external hosts, and userinfo tricks. This is an **open-redirect** guard; production IdP uses registered redirect URIs instead.
- **Dev-only tokens:** Never ship HS256 signing secret in production welcome builds.
- **APIs still do not mint tokens** ([API standards](../DeveloperEdition/standards/api_standards.md)); welcome is not a domain API.

---

## Standards alignment (post-implementation updates)

Update these when code lands:

1. **`spa_standards.md`** — Document `return_to` on `VITE_IDP_LOGIN_URI`, guard behavior, deprecate per-SPA login as default in Developer Edition.
2. **`api_standards.md`** — Welcome issues hash to `return_to` origin; persona matrix optional.
3. **`sre_standards.md`** — Authentication redirect example with query params.
4. **`Tasks/AS_NEEDED.R101`** — Five personas (Carol … Stan) and roles; port loops only for catalog.

---

## Implementation phases

### Phase 1 — Wire redirects (high value, low UI change)

- [ ] ~~`spa_utils`: `buildIdpLoginRedirectUrl`~~ → [TEMPLATE_UPDATE.md](./TEMPLATE_UPDATE.md) Part A
- [ ] ~~Journey SPAs: guard + `401` → welcome with `return_to`~~ → TEMPLATE_UPDATE Part B (via re-launch)
- [ ] Add `login.html` + update `Dockerfile` (COPY both files)
- [ ] Simplify `index.html` (catalog + plain SPA links only)
- [ ] `login.html`: user dropdown, role checkboxes, client-side mint on Login; retire Genny/Adam
- [ ] Manual test: cold open `8388` → `8080` → login → land authenticated on deep link

### Phase 2 — IdP-like UX

- [ ] Restyle `login.html`; automation IDs
- [ ] Strip auth from `index.html` (confirm no persona / `setPersonaLink` remnants)
- [ ] Logout → `login.html?return_to=...`
- [ ] Update compose / SPA `VITE_IDP_LOGIN_URI` to `http://127.0.0.1:8080/login.html`
- [ ] Update [SRE / SPA standards](../DeveloperEdition/standards/) IdP URL examples

### Phase 3 — Personas in build (R101)

- [ ] Jinja-inject `PERSONAS` defaults into `login.html` (labels / default roles; secret stays dev-only constant or build-arg for DE image only)
- [ ] Align `test/e2e/e2e_auth.py` default to **Stan** (`sub: stan`, `roles: [admin]`)
- [ ] API/service RBAC: replace template `developer` / `staff` checks with product roles where required

### Phase 4 — Hygiene

- [ ] Cypress: shared auth-flow spec + `registerAuthCommands` tweaks (see **Cypress E2E** below)
- [ ] Cypress smoke across one journey SPA + welcome (optional `cy.origin`)
- [ ] Align `IDP_LOGIN_URI` defaults (`localhost` vs `127.0.0.1`) in compose and Docker `ARG VITE_IDP_LOGIN_URI`
- [ ] Trim or redirect per-SPA `LoginPage` copy

---

## Cypress E2E

### Already standardized (keep this for most specs)

All journey SPAs and the `spa_utils` demo share the same stack:

| Piece | Location | Role |
|-------|----------|------|
| `registerJwtSignTask` | `spa_utils/cypress/plugins/registerJwtSignTask.ts` | Node `signCypressJwt` task |
| `signCypressJwt` | `spa_utils/cypress/tasks/signCypressJwt.ts` | HS256 JWT (`iss`/`aud`/`sub: cypress-user`, `roles`) |
| `e2eDefaultJwtSecret()` | `spa_utils/cypress/config/jwtDefaults.ts` | `local-dev-jwt-secret-fixed` |
| `registerAuthCommands` | `spa_utils/cypress/support/registerAuthCommands.ts` | **`cy.login(roles?)`** — seeds `localStorage` in `onBeforeLoad`, then visits `/` |
| Per-SPA wiring | `cypress.config.ts` + `cypress/support/e2e.ts` | Identical across customer/coordinator/mentor/craftsperson |

**Design intent:** E2E does **not** drive the welcome IdP UI or `/login` — it mirrors how APIs use `e2e_auth`: programmatic credentials, fast and stable. **Do not replace `cy.login()` with welcome clicks** for domain specs.

### Impact of welcome / guard refactor

| Area | Impact |
|------|--------|
| **`cy.login()` in `beforeEach`** | **Low** — token is set before the app boots; guards should see `isAuthenticated` and not redirect. |
| **`expectNotLoginPath: '/login'`** | **Medium** — if unauthenticated navigation redirects to `8080` instead of `/login`, this assertion is wrong only when login **fails** to seed storage. Consider `expectNotLoginPath` optional or env-specific. |
| **Logout tests** | **High** — today logout often ends on `/login` with `?redirect=`. After IdP redirect, logout may set `window.location` to welcome; product SPAs rarely test full logout flow (demo `spa_utils` does). |
| **Hash bootstrap path** | **Untested** in journey SPAs today — only `bootstrapAuthFromUrl` in app code; Cypress never visits `#access_token=...`. |

### Simplification / standardization opportunities

1. **`cy.loginViaHash(roles?, visitPath?)`** (spa_utils) — `cy.visit(\`${path}#access_token=...\`)` using the same task output as `cy.login`, asserting hash is stripped and `localStorage` matches. One shared spec per repo or a single umbrella `auth-bootstrap.cy.ts` documents the production callback path without cross-origin welcome.

2. **Extend `signCypressJwt` / `cy.login`** — optional `sub` + `roles`, or persona key from the five-persona table.

3. **`registerLogoutCommand()`** in spa_utils — extract demo `cy.logout()` from `cypress/support/commands.ts` so journey SPAs can import it instead of duplicating drawer logic; update logout expectations when `VITE_IDP_LOGIN_URI` is set.

4. **`cy.loginAsPersona('carol' | 'maria' | 'cat' | 'mark' | 'stan')`** — maps to `sub` + single role per [Developer personas and roles](#developer-personas-and-roles); use the persona that matches the SPA under test (e.g. `cat` on customer SPA).

5. **Dedicated `auth-idp.cy.ts` (small suite)** — unauthenticated `cy.visit('/subscriptions')` → `cy.origin` **`http://127.0.0.1:8080`** → `login.html?return_to=...` → Login → assert SPA hash bootstrap. Not `index.html`.

6. **Cypress env** — `CYPRESS_IDP_LOGIN_URI`, `CYPRESS_BASE_URL`; document that `baseUrl` stays the SPA port while IdP tests use `cy.origin('http://127.0.0.1:8080')`.

7. **Do not** — run full stack welcome in CI for every `beforeEach`; do not duplicate JWT signing in each SPA (already centralized).

### Recommended test split after refactor

| Suite | Auth mechanism |
|-------|----------------|
| Domain CRUD / navigation (existing) | `cy.loginAsPersona('cat')` etc., or `cy.login(['customer'])` |
| Admin routes | `cy.loginAsPersona('stan')` |
| Auth plumbing (new, small) | `cy.loginViaHash()` + optional IdP redirect spec |
| Logout (extend demo pattern to one journey SPA) | `registerLogoutCommand` + updated redirect expectation |

---

## API curl and API Explorer (out of band from SPAs)

SPAs and command-line / Swagger clients all use the **same JWT contract** (`Authorization: Bearer`, `iss`/`aud`/`sub`/`roles`, shared `JWT_SECRET`). The welcome refactor changes **how humans obtain** that string for browsers; it does not change what APIs accept.

### curl and scripts — minimal breakage

| Source today | After refactor |
|--------------|----------------|
| `test/e2e/e2e_auth.py` `get_auth_token()` | Update default to **Stan** (`sub: stan`, `roles: [admin]`); preferred for curl/scripts |
| `mentorhub_api_utils` `E2E_ACCESS_TOKEN` static | Re-mint to match **Stan** welcome token |
| Copy JWT from welcome persona map | Five tokens; use Stan for admin API exploration |
| Copy from browser after SPA login (`localStorage.access_token`) | Still valid — same token works on **any** API port |

Example (domain API):

```bash
export TOKEN="$(python -c 'from test.e2e.e2e_auth import get_auth_token; print(get_auth_token())')"
curl -s "http://127.0.0.1:8387/api/config" -H "Authorization: Bearer $TOKEN"
```

**Not affected by `return_to`:** curl never hits welcome; link-back is browser-only. Removing the welcome persona port matrix does not remove script-based minting.

**Optional welcome enhancements (Phase 2+):**

- **Copy token** control on the sign-in card (shows raw JWT for the selected user id + roles).
- **`return_to` absent** flow: after Login, show token + curl one-liner instead of redirecting.

Fix stale README one-liners that reference `E2E_ACCESS_TOKEN` where repos only export `get_auth_token()` (e.g. customer API).

### API Explorer (`/docs/explorer.html`)

Each domain API serves static **Swagger UI** from `docs/explorer.html` via `create_explorer_routes()` (`api_utils`). OpenAPI defines `components.securitySchemes.bearerAuth`; operations declare `security: [bearerAuth: []]`. The explorer does **not** call welcome, does not read URL hash, and does not use `localStorage` today—developers paste a JWT into Swagger’s **Authorize** dialog manually.

Welcome catalog links (R100) stay as plain `http://{host}:{apiPort}/docs/explorer.html` — no SPA port map required for those links.

**Integration gap:** `bootstrapAuthFromUrl()` is SPA-only (`mentorhub_spa_utils`). API Explorer runs on the **API origin** (e.g. `:8387`), so redirecting from welcome with `return_to=.../docs/explorer.html#access_token=...` does nothing until explorer HTML learns to consume the hash (or a query param).

**Recommended explorer integration (optional Phase 2):**

1. Extend shared `explorer.html` (in `api_utils`, copied per API) to mirror SPA bootstrap on load:
   - If location hash contains `access_token`, call Swagger UI `persistAuthorization` / preauthorize **http bearer** with that JWT.
   - Strip hash from the URL after apply (same hygiene as SPA).
2. Welcome **API Explorer** links become IdP entry points, e.g.  
   `http://127.0.0.1:8080/login.html?return_to=http://127.0.0.1:8387/docs/explorer.html`  
   User signs in → lands on explorer with token already authorized for “Try it out”.
3. Catalog can also offer **“Open explorer (authenticated)”** only when `return_to` validation allows API localhost ports.

**Without explorer changes:** workflow stays copy token from welcome (or `e2e_auth`) → Authorize in Swagger — unchanged, just fewer welcome persona shortcuts.

**mongodb / schema API:** schema uses `/docs/index.html` on its port; same bearer pattern if that spec includes `bearerAuth`.

### Summary

| Client | Uses welcome IdP + `return_to`? | Token source after refactor |
|--------|----------------------------------|-----------------------------|
| Journey SPA | Yes (primary) | Hash → `localStorage` via `bootstrapAuthFromUrl` |
| curl / CI | No | `e2e_auth.get_auth_token()` or copied JWT |
| API Explorer | Only if explorer hash bootstrap added | Manual Authorize, or hash bootstrap from welcome redirect |

---

## Open questions

1. **`return_to` absent on `login.html`:** **Resolved for Phase 1** — show persona form but disable Login (or message: use [developer portal](/) to open an app first). No token issued without a validated `return_to`.
2. **`return_to` scope:** Full `href` vs `origin + pathname` (exclude existing hash).
3. **Hostname consistency:** Compose defaults mix `localhost` and `127.0.0.1`; pick one for docs and env examples to avoid duplicate localStorage origins.
4. **Schema / configurator SPA (8384):** Same guard pattern if it gains `requiresAuth` routes.

---

## Assessment

| Question | Answer |
|----------|--------|
| Can this work? | **Yes** — builds on existing hash bootstrap and standards intent. |
| Does link-back fix ports for login? | **Yes** — `return_to` carries the SPA origin; welcome does not need per-journey port map for auth. |
| Main work | SPA redirects + welcome form; not API or new services. |
| Main risk | Open redirect if `return_to` is not validated; mitigated by localhost allowlist in dev. |

---

## References

- Portal: [`index.html`](../index.html) — catalog only (remove persona / `setPersonaLink`)
- Sign-in: **`login.html`** (new) — personas, `return_to`, `spaAuthHash`, five JWTs (Carol … Stan)
- Bootstrap: [`urlAuthBootstrap.ts`](../mentorhub_spa_utils/src/utils/urlAuthBootstrap.ts)
- Example guard: [`mentorhub_customer_spa/src/router/index.ts`](../mentorhub_customer_spa/src/router/index.ts)
- Compose welcome + `IDP_LOGIN_URI`: [`DeveloperEdition/docker-compose.yaml`](../DeveloperEdition/docker-compose.yaml)
