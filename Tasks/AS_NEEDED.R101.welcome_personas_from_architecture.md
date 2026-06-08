# R101 – Welcome page personas and JWT roles from architecture

**Status**: As Needed  
**Task Type**: Refactor  
**Run Mode**: Run as needed

## Goal

Align welcome **persona** data with `Specifications/architecture.yaml` and the dev-login design in [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md). Primary JWT minting moves to **`login.html`** in [R102](./AS_NEEDED.R102.dev_login_pilot.md); `index.html` becomes catalog-only (no persona matrix).

Target personas: **Carol** (`coordinator`), **Maria** (`mentor`), **Cat** (`customer`), **Mark** (`mentee`), **Stan** (`admin` / SRE)—five personas, five roles, one JWT each. Use this task when architecture or persona definitions change; implement welcome/login split in R102.

## Context / Input files

**Inputs** (read first):

- `Specifications/architecture.yaml` — domains where `is_journey: true`, repo `type: spa` (ports), and any fields you add for personas (see below).
- `index.html` — persona markup, `spaAuthHash` / link wiring, JWT constants in the script block.
- API **e2e / dev defaults**: `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`, `JWT_ALGORITHM` must match token claims (see flask mongo template `test/e2e/e2e_auth.py` and Pipfile `dev` / `e2e` scripts).

**Optional** (only if you extend the spec):

- Product slug / naming: `Specifications/product.yaml` — affects repo naming, not JWT directly.

## Requirements

1. **Drive SPA links from architecture**  
   Keep (or reapply) loops over journey domains and SPA repos so every journey SPA gets persona anchor(s) with stable `id`s (e.g. `{domain}-{personaKey}`).

2. **Replace Genny/Adam with five personas**  
   - Carol, Maria, Cat, Mark, Stan — each with a single role (`coordinator`, `mentor`, `customer`, `mentee`, `admin`).  
   - See [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md#reference--target-behavior) for `sub` and journey hints.

3. **JWT and URL `roles` must agree**  
   `login.html` mints JWTs at Login from the user dropdown + role checkboxes. Payload `roles` array must match hash `roles` (comma-separated). Default roles per persona are in [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md#reference--target-behavior); users may override checkboxes before Login.

4. **Mint tokens with the real dev secret**  
   Use the same secret as running APIs (e.g. PyJWT, `HS256`). Default Developer Edition and compose use `local-dev-jwt-secret-fixed` (no product slug in the string). After changing `JWT_SECRET` or claims, re-run this task and update inlined tokens in `index.html`.

5. **Document in-repo**  
   Add a short comment in `index.html` above persona constants describing iss/aud/sub/roles and that tokens are **dev-only**.

6. **Do not break non-persona sections**  
   Service list, API Explorer, and `spa_ref` URL wiring should stay correct for `schema` and journey domains.

## Suggested approaches

- **Minimal static map in HTML**: Jinja `welcome_persona_jwt` dict keyed by `domain.name`, plus optional admin variants; mint offline when domains change.  
- **Spec-driven (future)**: Add explicit optional fields under each journey domain for persona labels or token placeholders, then map in Jinja — only if your team wants YAML to own that data.

## Testing expectations

- Open the welcome page locally (`welcome` service / port from Developer Edition).  
- For each journey SPA, sign in as the matching persona (Cat → customer, Carol → coordinator, Maria → mentor, Mark → craftsperson/mentee, Stan → admin routes).  
- APIs accept tokens when `JWT_SECRET` matches; use Stan for admin-gated endpoints.  
- After changes, run umbrella `make test` if you are working in the template repo.

## Dependencies / Ordering

- Run after merge when `architecture.yaml` lists final journey domains and ports.  
- Complements **R100** (compose + welcome layout/services); R100 updates structure for new services; **R101** focuses on **persona UX and JWTs**.

## Change control checklist

- [ ] Read current `architecture.yaml` journey domains and SPA ports.  
- [ ] Confirm five personas (Carol … Stan) and roles per DevLoginLaunchPlan.  
- [ ] Mint JWTs; update `index.html` script and markup.  
- [ ] Manually verify one SPA per journey.  
- [ ] Note completion and date in implementation notes below.

## Implementation notes

_(Fill in when task is executed.)_

## Testing results

_(Fill in when task is executed.)_