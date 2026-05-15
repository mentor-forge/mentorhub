# R100 – Update files after architecture.yaml changes

**Status**: As Needed 
**Task Type**: Updates
**Run Mode**: Run as needed

## Goal

Update the Developer Edition docker-compose.yaml, and the welcome page index.html with changes after the architecture.yaml file has been updated with new services.

## Context / Input files

These files must be treated as **inputs** and read before implementation:

- `Specifications/architecture.yaml`

**Target files** (to be updated):

- `DeveloperEdition/docker-compose.yaml`
- `index.html` (welcome page)

## Requirements

Update `DeveloperEdition/docker-compose.yaml` and the welcome page `index.html` to match the services defined in `Specifications/architecture.yaml`.

### docker-compose.yaml

- Add or update service definitions for each new domain in the architecture.
- Do not change the existing welcome, runbook, or schema/mongodb services. 
- Do not create services or links for the common_code domain.
- **Remove** the sample profile and any sample_api/sample_spa services (temporary placeholders).
- **Welcome service** must be included in ALL profiles (every profile in the file). When adding new domains, add their profiles (e.g. `{domain}`, `{domain}-api`) to the welcome service profiles list so the welcome page always starts with any profile.
- **Use ports from architecture.yaml exactly** – The template merge process configures APIs to listen on the port specified in the architecture. Docker-compose ports and API_PORT env must match (e.g. profile_api: 9096, profile_spa: 9097).
- **For each new microservice domain, define two profiles:**
  - `{domain}-api` – API service only (e.g. `profile-api` → profile_api)
  - `{domain}` – API + SPA (e.g. `profile` → profile_api + profile_spa)
- **Add API_PORT** to each API service environment so the app binds correctly.
- **Add IDP_LOGIN_URI** to each SPA (typically the umbrella welcome page base URL, or your IdP) so unauthenticated users have a single redirect target—not a per-SPA login route.
- Ensure backing services (e.g. mongodb) are included in the profiles of any new services.
- Ensure all new services are included in the all profile.

### index.html

**Personas (default merge)**  
The template merge ships **Genny** / **Adam** with static dev JWTs (`developer` / `admin`) and one link per journey SPA per persona—no per-domain token minting at merge time. To align personas, roles, and JWT claims with `Specifications/architecture.yaml` (e.g. journey-named roles), run **Tasks/AS_NEEDED.R101** after merge.

**Layout**

- Each service is one row with **two equal-width columns (50/50)**:
  - **Left column (spa-cell):** SPA/app button; directly **below** it, a small-text source link or label.
  - **Right column (api-cell):** API Explorer button; directly **below** it, a small-text source link or label.
- Use classes: `.service-row`, `.spa-cell`, `.api-cell`, `.cell-link`, `.source-under`.

**Links**

- Add a link for each service SPA (correct port from architecture) and an API Explorer link for each backing API at `/docs/explorer.html` (or `/docs/index.html` where applicable).
- **Source code links:** Each SPA and API has a **repo link** in smaller font **under** its button:
  - Under the SPA button: link text = repo name (e.g. `mentorhub_member_spa`), href = `https://github.com/{git_org}/{repo_name}`.
  - Under the API Explorer button: link text = API repo name (e.g. `mentorhub_member_api`), href = same pattern.
- **Utility SPAs** (mongodb_configurator_spa, stage0_runbook_spa): do **not** add a repo link; show a **reference label** only in `.source-under .utility-ref` (e.g. `mongodb_configurator_spa (utility)`, `stage0_runbook_spa (utility)`).
- Add new domains to the top of the list. Do not create services or links for the common_code domain. Schema and runbook rows keep the same pattern (API repo link under Explorer; SPA side utility ref where applicable).

## Testing expectations

- **None**

## Packaging / build checks

Before marking this task as completed:
- Run ``make container`` and ensure that the container builds cleanly.

## Dependencies / Ordering

- Should run **after**:
  - **None**
- Should run **before**:
  - **None**

## Implementation notes (to be updated by the agent)

**Summary of changes**
