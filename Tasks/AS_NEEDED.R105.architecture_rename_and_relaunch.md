# R105 – Architecture rename and Stage0 re-launch (utils + journeys)

**Status:** As Needed  
**Task Type:** Updates  
**Run Mode:** Run as needed

## Goal

After journey repos are deleted ([R104](./AS_NEEDED.R104.stage0_delete_journey_repos.md)):

1. Update **`Specifications/architecture.yaml`** (and related specs) with **team-agreed** domain names, repo names, and ports
2. Align umbrella Developer Edition files with the new architecture ([R100](./AS_NEEDED.R100.after_specs_update.md))
3. **`stage0_launch`** to re-create **`mentorhub_spa_utils`** and all journey **api/spa** pairs from templates updated in [R103](./AS_NEEDED.R103.dev_login_stage0_templates.md)

Umbrella **`mentorhub` is not re-launched** — only spec/compose/catalog updates plus launch of child repos.

## Context / Input files

**Read first:**

- [DevLoginLaunchPlan.md](../Specifications/DevLoginLaunchPlan.md)
- `Specifications/architecture.yaml`, `catalog.yaml`, `product.yaml`, `journeys.yaml`, `stakeholders.yaml`
- `DeveloperEdition/docker-compose.yaml`, `index.html` (catalog ports)
- [R100](./AS_NEEDED.R100.after_specs_update.md) — compose + `index.html` after yaml changes
- [R101](./AS_NEEDED.R101.welcome_personas_from_architecture.md) — if persona defaults on `login.html` need yaml-driven tweaks
- Stage0 templates from R103

## Requirements

### Architecture and umbrella (team input required)

- [ ] Update `Specifications/architecture.yaml` — domain names, repos, ports
- [ ] Update related specification files as needed
- [ ] Update `DeveloperEdition/docker-compose.yaml` for new services/ports
- [ ] Run [R100](./AS_NEEDED.R100.after_specs_update.md) checklist — `index.html` catalog links (plain SPA URLs); `IDP_LOGIN_URI` remains `http://127.0.0.1:8080/login.html`
- [ ] Update architecture diagrams if maintained (`Specifications/ArchitectureDiagram.*`)
- [ ] PR reviewed by team (architecture rename is a **decision** gate)

### `stage0_launch` create

- [ ] Launch **`mentorhub_spa_utils`** from `stage0_template_vue_utils`
- [ ] Launch each **`mentorhub_{domain}_api`** and **`mentorhub_{domain}_spa`** per new `architecture.yaml`
- [ ] Each SPA: `VITE_IDP_LOGIN_URI=http://127.0.0.1:8080/login.html`
- [ ] `npm run build && npm test` on launched repos; `npm run cypress:run` on at least one journey SPA

### Smoke

- [ ] Developer Edition: portal `8080/` → plain SPA link → `login.html?return_to=...` → authenticated app
- [ ] Repeat for **at least two** journey domains
- [ ] Umbrella welcome ports/names match launched services (R100)

## Testing expectations

- CI green on newly launched repos
- Manual dev-login smoke (two domains)
- Optional: spot-check `curl` / `e2e_auth` on one API

## Dependencies / Ordering

- Run **after** [R104](./AS_NEEDED.R104.stage0_delete_journey_repos.md)
- Requires [R103](./AS_NEEDED.R103.dev_login_stage0_templates.md) templates
- Uses [R100](./AS_NEEDED.R100.after_specs_update.md) after yaml stabilizes

## Change control checklist

- [ ] Team sign-off on architecture rename captured in PR
- [ ] Specification + umbrella DE files updated
- [ ] R100 catalog/compose complete
- [ ] `stage0_launch` create steps executed and logged
- [ ] CI + manual smoke documented in **Testing results**
- [ ] PR(s) referencing **R105**

## Implementation notes

_(Fill in when task is executed.)_

**Team architecture decisions** _(domain rename table)_

| Old domain/repo | New domain/repo | Notes |
|-----------------|-----------------|-------|
| _TBD_ | _TBD_ | |

## Testing results

_(Fill in when task is executed.)_
