# Mentor Hub Developer Edition

The Mentor Hub Developer Edition system provides a `mh` Command Line Interface that supports key components of the developer experience. This CLI wraps docker compose commands, and secret management for local development environments. All developers should install this tooling, create and configure tokens, and review the linked standards before contributing to any repo.

## Step 1 of 4 - Install Prerequisites

Run `make verify` to check that all prerequisites are installed. If any fail, install them using the links below.

### Build tools

- **make** - usually pre-installed - [https://www.gnu.org/software/make/](https://www.gnu.org/software/make/)
- **Node.js** (v24+) - [https://nodejs.org/en/download](https://nodejs.org/en/download)
- **npm** (v11.5+) - Bundled with Node.js
- **cypress** (v)
- **Vite** - `npm install -g vite` or use via `npx vite`. [https://vitejs.dev/guide/](https://vitejs.dev/guide/)



### Python tools

- **Python 3.12+** - [https://www.python.org/downloads/](https://www.python.org/downloads/)
- **Pipenv** - [https://pipenv.pypa.io/en/latest/](https://pipenv.pypa.io/en/latest/) (`pip install pipenv`)



### Container tools

- **Docker Desktop** - [https://www.docker.com/get-started/](https://www.docker.com/get-started/)



### GitHub & Git

- **GITHUB_TOKEN** - See [Configuring AccessToken](#configure-access-tokens)
- **git** - [https://git-scm.com/downloads](https://git-scm.com/downloads)

**Recommended:** [GitHub SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for clone/push, and global git identity for commits:

```sh
git config --global user.name "Your Name"
git config --global user.email yourname@example.com
```



### AWS CLI (CodeArtifact packages)

- **AWS CLI v2** - [https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (macOS: `brew install awscli`)



### Utilities

- **jq** - [https://jqlang.github.io/jq/download/](https://jqlang.github.io/jq/download/) (macOS: `brew install jq`)
- **yq** - [https://mikefarah.gitbook.io/yq](https://mikefarah.gitbook.io/yq) (macOS: `brew install yq`)
- **curl** - Usually pre-installed. [https://curl.se/download.html](https://curl.se/download.html)



### Other

- **zsh shell** - Default on macOS. Linux: [https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
- **Mongo Compass** - [https://www.mongodb.com/docs/compass/install/](https://www.mongodb.com/docs/compass/install/)
- **WSL** - For Windows users: [https://learn.microsoft.com/en-us/windows/wsl/install](https://learn.microsoft.com/en-us/windows/wsl/install)



## Step 2 of 4 - Install the CLI

Use these commands to install the Developer Edition `mh` command line utility. 

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

---

## Development Standards

- Understand a few simple [Architecture Principles](./DeveloperEdition/standards/ArchitecturePrinciples.md)
- Review the [Data Standards](./DeveloperEdition/standards/data_standards.md).
- Review the [SRE Standards](./DeveloperEdition/standards/sre_standards.md).
- Review the [API Standards](./DeveloperEdition/standards/api_standards.md).
- Review the [SPA Standards](./DeveloperEdition/standards/spa_standards.md).
- Take the [Onboarding Tour](./DeveloperEdition/standards/system_tour.md).

## Developer Workflow

We utilize an Issue-Feature–Branch pattern for the developer workflow. Our issue names have a prefix to help with organization in the form of Type-UserLayerNumber where:

- Type is *F*eature or *D*efect
- User is mento*R*, mente*E*, *C*ustomer, co*O*rdinator
- Layer is *D*ata, *A*pi, *S*pa
- Number is a 2-digit number for the issue.

So F-RS05 would be the 5th Feature for the Mentor SPA, and F-EA04 would be the 4th feature of the Mentee API. 

Developers should focus on a one feature at a time, and should complete the following workflow for the full feature before moving on to the next:

1. Pick an issue from the "On Deck" cards on the [kanban board](https://github.com/orgs/mentor-forge/projects/1/views/2).
2. Review the issue description, and create a feature branch that references the issue number
3. Create a LLM Prompt to create a set of tasks for automation. See below for advice on how to do this.
4. If you want Mike's review of your prompt, DM him with it on Discord.
5. Open a **new** Cursor Chat and submit your Create Tasks prompt. 
6. Review tasks to fully understand the proposed changes, adjust as needed.
7. If you want Mike to review your tasks, open a Draft PR and request the review.
8. Ask Cursor to "Orchestrate all pending tasks using the process outlined in tasks/README.md"
9. Review cursors work, run unit and end-to-end testing, fix any problems you find. 
10. Open a Pull Request (or mark your PR as no longer a draft) - request a review.
11. After approval, merge the PR, delete the branch, locally change back to the main branch and sync.

The Step 2 prompt is critical. It's not a book, but should contain clear instructions about what the intended outcome of the changes is. Most prompts will look something like:

```
Please review @standards, @README and @README for context, and create new tasks starting with <number> to <Implement Feature>. 
...details of what you expect...
Only create tasks, do not execute any tasks, or edit any files outside of the tasks folder.
```

## Umbrella Repo Developer Commands

```sh
# Verify you have all the developer pre-req's installed
make verify

# Install the developer CLI in your search path
make install

# Update the developer CLI with the latest compose file
make update

# Generate data schemas for all collections in catalog.yaml
make schemas

# Build the welcome page container
make container

# Open the Stage0 Launch Utility
make stage0-launch-ui
```

