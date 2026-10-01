# Mentor Hub Developer Edition

The Mentor Hub Developer Edition system provides a `mh` Command Line Interface that supports key components of the developer experience. This CLI wraps docker compose commands, and secret management for local development environments. All developers should install this tooling, create and configure tokens, and review the linked standards before contributing to any repo.

NOTE: Native Windows is unsupported; use WSL. 

## Step 1 of 4 - Install Prerequisites

You will need to install the following desktop tools first.
- **Docker Desktop** - [https://www.docker.com/get-started/](https://www.docker.com/get-started/)
- **Mongo Compass** - [https://www.mongodb.com/docs/compass/install/](https://www.mongodb.com/docs/compass/install/)
- **WSL** - For Windows users: [https://learn.microsoft.com/en-us/windows/wsl/install](https://learn.microsoft.com/en-us/windows/wsl/install)

**Recommended:** [GitHub SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for clone/push, and global git identity for commits:

```sh
git config --global user.name "Your Name"
git config --global user.email yourname@example.com
```

## Step 2 of 4 - Install the CLI

The install process will install the following tools on your system:

- **Homebrew** - Package manager used by `make install` on macOS and Linux
- **make** - usually pre-installed - [https://www.gnu.org/software/make/](https://www.gnu.org/software/make/)
- **Node.js** (v24+) - [https://nodejs.org/en/download](https://nodejs.org/en/download)
- **npm** (v11.5+) - Bundled with Node.js
- **Vite** - `npm install -g vite` or use via `npx vite`. [https://vitejs.dev/guide/](https://vitejs.dev/guide/)
- **Python 3.12+** - [https://www.python.org/downloads/](https://www.python.org/downloads/)
- **Pipenv** - [https://pipenv.pypa.io/en/latest/](https://pipenv.pypa.io/en/latest/)
- **git** - [https://git-scm.com/downloads](https://git-scm.com/downloads)
- **AWS CLI v2** - [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **jq** - [https://jqlang.github.io/jq/download/](https://jqlang.github.io/jq/download/)
- **yq** - [https://mikefarah.gitbook.io/yq](https://mikefarah.gitbook.io/yq)
- **curl** - Usually pre-installed. [https://curl.se/download.html](https://curl.se/download.html)
- **zsh shell** - Default on macOS. Linux: [https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)

Use this command to install the brew-backed tools (`git`, Node.js, Python 3.12, Pipenv, `jq`, `yq`, AWS CLI, and `curl`), Vite, and the Developer Edition `mh` command line utility. It installs `make` only when it is missing. Docker Desktop and Mongo Compass remain manual installs using the vendor links above.

```sh
## Install Developer Edition 
make install
```

Remember to  `source ~/.zshrc` before proceeding.

## Step 3 of 4 - Configure access tokens

When local environment values are required (GitHub access tokens, etc.) they are stored in the hidden folder `~/.mentorhub` instead of a being replicated across multiple repo level .env files. 

### GITHUB_TOKEN

We publish `**api-utils**` (PyPI) and `**@mentor-forge/mentorhub_spa_utils**` (npm) to **AWS CodeArtifact**, and container images to **GitHub Container Registry**. Create a GitHub classic access token with `repo`, `workflow`, and `write:packages` privileges. Save it as `GITHUB_TOKEN` in the `~/.mentorhub/` folder.

To create a token, login to GitHub and click your Profile Pic -> Settings -> Developer Settings -> Personal access tokens -> Tokens(classic) -> Create New -> ✅ repo, ✅ workflow, ✅ write:packages. For reference: [ghcr and github tokens](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### CodeArtifact (private packages)

After [Step 2](#step-2-of-4---install-the-cli), run **once** to configure package-registry access:

```sh
make aws-setup
```

This opens a browser login and configures `~/.mentorhub/aws-platform.env` and `~/.aws/config` for profile `mentorhub-shared`. Run bare `mh` (or `make update`) before `pipenv run install` or `npm ci` in journey API/SPA repos so CodeArtifact tokens are fresh (~12 hour lifetime).

## Step 4 of 4 - Finally

After GITHUB_TOKEN and `make aws-setup` are in place, run update to finish the install.

```sh
## Update Developer Edition configurations
make update
```

## Developer Edition — portal vs direct ports

After sign-in at `http://<HOST_NAME>:8080/login.html`, prefer the **Applications** links on the welcome portal (`http://localhost:8080`) so journey SPAs load on the shared **8080** origin — do not bookmark direct SPA ports (e.g. `:8398` for Discovery) as your primary app URL.

Direct service ports are supported on purpose for **Cypress** (per-repo `npm run cypress:run` against `:8388`, `:8390`, etc.) and **API `/docs/` explorers** on each API port (e.g. `:8397/docs/explorer.html`).

## Development Standards

- Local API mocks (`mock_stripe_api`, `mock_cognito`, `mock_mailpit`) — see [Research/local_dev_mocks.md](./Research/local_dev_mocks.md) for ports and env vars.
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

- **Type** is *F*eature or *D*efect
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
- **F-S01** = 1st SRE feature (e.g. Cognito in cloudformation)

### Workflow

Developers should focus on one issue at a time, and should complete the following workflow for the full issue before moving on to the next:

1. Pick an issue from the "On Deck" cards on the [kanban board](https://github.com/orgs/mentor-forge/projects/1), and move it from **On Deck** to **In Progress**
2. Review the issue description, and create a feature branch that references the issue name
3. Use the following prompt to create a plan, make sure you @mention the correct file/folder.
```
Please create @_PLANNING.md tasks to implement <issue links>. Only create files in the @tasks folder
```
4. Review tasks to fully understand the proposed changes, adjust as needed.
5. Use the following prompt to execute the plan
```
Please @_ORCHESTRATE.md all PENDING @tasks
```
6. Review cursors work, run unit and end-to-end testing, fix any problems you find.
7. Request a review of the PR that was opened during orchestration.
8. After approval, merge the PR, delete the branch, locally change back to the main branch and sync.
9. Go back to the [kanban board](https://github.com/orgs/mentor-forge/projects/1/views/2), and make sure your issue moved from **In Progress** to **Done** then loop back up to 1.

## Nvidia GB10 Hosted Dev Env
- https://mentorhub-gb10.tailb0d293.ts.net/discovery/
- Discord: ``@zeroclawagent please deploy the latest code using mh-restart.sh ``

## Repo Developer Commands

```sh
# Verify you have all the developer pre-req's installed
make verify

# Install the developer CLI in your search path
make install

# Configure your AWS account for access to code artifact
make aws-setup

# Update the developer CLI with the latest compose file
make update

# Clone/pull architecture.yaml sibling repos (no container builds)
make clone-all

# clone-all, then build journey API/SPA containers
make build-all

# Start the full Developer Edition stack, then run journey API e2e and SPA Cypress
make test-all

# Build the welcome page container
make container
```

