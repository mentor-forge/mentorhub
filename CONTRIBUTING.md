# Mentor Hub Developer Edition

The Mentor Hub Developer Edition system provides a `mh` Command Line Interface that supports key components of the developer experience. This CLI wraps docker compose commands, and secret management for local development environments. All developers should install this tooling, create and configure tokens, and review the linked standards before contributing to any repo.

NOTE: Native Windows is unsupported; use WSL. 

## Install Developer Edition

1. Install [Homebrew](https://brew.sh) and start [Docker Desktop](https://www.docker.com/get-started/) or an equivalent Docker Engine with Compose. Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) on Windows. [MongoDB Compass](https://www.mongodb.com/docs/compass/install/) is useful for inspecting local data.
2. Clone this repository into the directory where you want the other Mentor Hub repos, then run `make install` from the checkout. It installs the command-line prerequisites through Homebrew and configures zsh for `mh`.
3. Create a [GitHub personal access token (classic)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-npm-registry#authenticating-to-github-packages) with `read:packages` and access to Mentor Forge packages and images. Configure [GitHub SSH access](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) for cloning and pushing the sibling repositories. Save the token alone in `~/.mentorhub/GITHUB_TOKEN` and restrict the file to your account with `chmod 600 ~/.mentorhub/GITHUB_TOKEN`.
4. Start a new zsh session or run `source ~/.zshrc`. From this checkout, run `make update` to install the CLI and Compose configuration, sign in to GitHub Container Registry, and configure scoped npm access.

### Install shared dependencies

In a journey API repo, use its Pipenv install command. Python wheels pinned to public GitHub Release assets download without package credentials.

In a journey SPA repo, run `npm ci` from the configured shell. The token must be exported as `GITHUB_TOKEN`. Run `mh` to refresh npm configuration if needed. It configures GitHub Packages for `@mentor-forge` while other scopes and unscoped packages keep their existing registries. See [API Standards](./DeveloperEdition/standards/api_standards.md#dependency-management) and [SPA Standards](./DeveloperEdition/standards/spa_standards.md#dependency-management) for version pins.

## Developer Edition — portal vs direct ports

After sign-in at `http://<HOST_NAME>:8080/login.html`, prefer the **Applications** links on the welcome portal (`http://localhost:8080`) so journey SPAs load on the shared **8080** origin — do not bookmark direct SPA ports (e.g. `:8398` for Discovery) as your primary app URL.

Direct service ports are supported on purpose for **Cypress** (per-repo `npm run cypress:run` against `:8388`, `:8390`, etc.) and **API** `/docs/` **explorers** on each API port (e.g. `:8397/docs/explorer.html`).

## Development Standards

- Local API mocks — see [Research/local_dev_mocks.md](./Research/local_dev_mocks.md) for ports and env vars.
- Understand a few simple [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- Review the [Data Standards](./DeveloperEdition/standards/data_standards.md).
- Review the [SRE Standards](./DeveloperEdition/standards/sre_standards.md).
- Review the [API Standards](./DeveloperEdition/standards/api_standards.md).
- Review the [SPA Standards](./DeveloperEdition/standards/spa_standards.md).
- Take the [Onboarding Tour](./DeveloperEdition/standards/system_tour.md).



## Developer Workflow



### Issue-Feature-Branch

We utilize an Issue-Feature–Branch pattern for the developer workflow. Our issue naming standards have a prefix to help with organization in the form of 

**Type-UserLayerNumber** where:

- **Type** is *F*eature or *D*efect or *I*nfrastructure
- **User** identifies the bounded domain or platform component:
  - Journey domains (API/SPA repos): mento**R**, ment**E**, **C**ustomer, co**O**rdinator, **D**iscovery, **A**dmin
  - Platform: **W**elcome/Login (mentorhub), **U**tils (api_utils, spa_utils)
  - **S**RE (cloudformation / infra)
- **Layer** is **A**pi, **S**pa, or SR**E** (omit layer for Data-only tickets — see below)
- **Number** is a serial issue number (typically two digits)

**Data dictionary tickets** (`mentorhub_mongodb_api`) use **F-D##** with **no layer letter** — the second **D** means **Data** (configurator / schema), not Discovery. Example: **F-D29** = event type schemas. Do not confuse with **F-DA##** (Discovery Api).

For Example:

- Filter to **F-R** for all Mentor API/SPA features
- Filter to **F-RS** for all SPA features in `mentorhub_mentor_spa`
- **F-RS05** = 5th Feature for the Mentor SPA
- **F-EA04** = 4th feature of the Mentee API
- **F-CA05** = 5th feature of the Customer API
- **F-DA01** = 1st feature of the Discovery API (`mentorhub_discovery_api`)
- **F-DS01** = 1st feature of the Discovery SPA (`mentorhub_discovery_spa`)
- **F-AA01** = 1st feature of the Admin API (`mentorhub_admin_api`)
- **F-D29** = 29th Data (mongodb configurator) feature — not Discovery
- **F-S01** = 1st SRE feature (e.g. deployment infrastructure)



### Workflow

Developers should focus on one issue at a time, and should complete the following workflow for the full issue before moving on to the next:

1. Pick an issue from the "On Deck" cards on the [kanban board](https://github.com/orgs/mentor-forge/projects/1), and move it from **On Deck** to **In Progress**
2. Review the issue description, and create a feature branch that references the issue name
3. Use the following prompt to create a plan, make sure you @mention the correct file/folder.

```
Please create @_PLANNING.md tasks to implement <issue links>. Only create files in the @tasks folder
```

1. Review tasks to fully understand the proposed changes, adjust as needed.
2. Use the following prompt to execute the plan

```
Please @_ORCHESTRATE.md all PENDING @tasks
```

1. Review cursors work, run unit and end-to-end testing, fix any problems you find.
2. Request a review of the PR that was opened during orchestration.
3. After approval, merge the PR, delete the branch, locally change back to the main branch and sync.
4. Go back to the [kanban board](https://github.com/orgs/mentor-forge/projects/1/views/2), and make sure your issue moved from **In Progress** to **Done** then loop back up to 1.



## Nvidia GB10 Hosted Dev Env

- [https://mentorhub-gb10.tailb0d293.ts.net/discovery/](https://mentorhub-gb10.tailb0d293.ts.net/discovery/)
- Discord: `@zeroclawagent please deploy the latest code using mh-restart.sh` 



## Repo Developer Commands

```sh
# Verify you have all the developer pre-req's installed
make verify

# Clone/pull architecture.yaml sibling repos (no container builds)
make clone-all

# clone-all, then build journey API/SPA containers
make build-all

# Start the full Developer Edition stack, then run journey API e2e and SPA Cypress
make test-all

# Build the welcome page container
make container
```

