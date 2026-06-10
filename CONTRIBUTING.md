# Mentor Hub Developer Edition

The Mentor Hub Developer Edition system provides a ``mh`` Command Line Interface that supports key components of the developer experience. This CLI wraps docker compose commands, and secret management for local development environments. All developers should install this tooling, create and configure tokens, and review the linked standards before contributing to any repo.

## Step 1 of 4 - Install Prerequisites

Run `make verify` to check that all prerequisites are installed. If any fail, install them using the links below.

### Build tools
- **make** - usually pre-installed - https://www.gnu.org/software/make/
- **Node.js** (v24+) - https://nodejs.org/en/download
- **npm** (v11.5+) - Bundled with Node.js
- **cypress** (v)
- **Vite** - `npm install -g vite` or use via `npx vite`. https://vitejs.dev/guide/

### Python tools
- **Python 3.12+** - https://www.python.org/downloads/
- **Pipenv** - https://pipenv.pypa.io/en/latest/ (`pip install pipenv`)

### Container tools
- **Docker Desktop** - https://www.docker.com/get-started/

### GitHub & Git
- **GITHUB_TOKEN** - See [Configuring AccessToken](#configure-access-tokens)
- **git** - https://git-scm.com/downloads

**Recommended:** [GitHub SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for clone/push, and global git identity for commits:
```sh
git config --global user.name "Your Name"
git config --global user.email yourname@example.com
```

### Utilities
- **jq** - https://jqlang.github.io/jq/download/ (macOS: `brew install jq`)
- **yq** - https://mikefarah.gitbook.io/yq (macOS: `brew install yq`)
- **curl** - Usually pre-installed. https://curl.se/download.html

### Other
- **zsh shell** - Default on macOS. Linux: https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH
- **Mongo Compass** - https://www.mongodb.com/docs/compass/install/
- **WSL** - For Windows users: https://learn.microsoft.com/en-us/windows/wsl/install

## Step 2 of 4 - Install the CLI
Use these commands to install the Developer Edition ``mh`` command line utility. 
```sh
## Install Developer Edition 
make install
```
Remember to  ``source ~/.zshrc`` before proceeding.

## Step 3 of 4 - Configure access tokens
When local environment values are required (GitHub access tokens, etc.) they are stored in the hidden folder ``~/.mentorhub`` instead of a being replicated across multiple repo level .env files. 

### GITHUB_TOKEN
We are using GitHub to publish the api_utils pypi package, the spa_utils npm package, and GitHub Container Registry to publish containers. Create a GitHub classic access token with `repo` `workflow`, and `write:packages` privileges. Save it as `GITHUB_TOKEN` in the ``~/.mentorhub/`` folder.

To create a token, login to GitHub and click your Profile Pic -> Settings -> Developer Settings -> Personal access tokens -> Tokens(classic) -> Create New -> ✅ repo, ✅ workflow, ✅ write:packages. For reference: [ghcr and github tokens](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### AWS SSO and CodeArtifact (Shared-Services)

MentorHub uses **two regions** — do not swap them. See [Specifications/aws-platform.yaml](./Specifications/aws-platform.yaml).

| Purpose | Region |
|--------|--------|
| IAM Identity Center sign-in (`sso_region` in `aws configure sso`) | **`us-east-2`** |
| CodeArtifact, GitHub Actions, workloads (profile `region`, `--region`) | **`us-east-1`** |

1. Install the [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configure SSO profiles (one-time). Use the **same SSO session** for both profiles so one login covers Shared-Services and MentorHub-Dev:

| Prompt | Value |
|--------|--------|
| SSO session name | `mentor-forge` |
| SSO start URL | `https://d-906780e571.awsapps.com/start` |
| SSO region | `us-east-2` (Identity Center home region — **not** `us-east-1`) |
| SSO registration scopes | `sso:account:access` (accept the default) |
| CLI default region (per profile) | `us-east-1` |

SREs can confirm start URL and SSO region from the Management account: **IAM Identity Center → Settings**.

Then create each CLI profile:

```sh
aws configure sso --profile mentorhub-shared   # account: Shared-Services, role: Developer-Packages or SRE
aws configure sso --profile mentorhub-dev      # account: MentorHub-Dev, role: Developer or SRE
```

When configuring the second profile, reuse SSO session `mentor-forge` (same start URL, SSO region, and scopes). Set each profile's default **CLI region** to `us-east-1`.

3. Before `pipenv install` / `npm ci` against private packages (after CodeArtifact migration):

```sh
aws sso login --profile mentorhub-shared
# future: mh codeartifact login
```

Platform defaults (`AWS_REGION=us-east-1`, profile names, CodeArtifact domain/repos) are in `DeveloperEdition/aws-platform.env` and installed to `~/.mentorhub/aws-platform.env` by `make update`. Override account-specific values in `~/.mentorhub/aws-platform.local.env` (not committed).

GitHub Actions org variable **`AWS_REGION`** should be set to **`us-east-1`** in the `mentor-forge` organization (Settings → Secrets and variables → Actions → Variables).

## Step 4 of 4 - Finally
After you have everything installed and your token in place, run update to finish the install.
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
We utilize an Issue–Feature–Branch pattern for the developer workflow:
- Pick up an issue from the code base and assign yourself. If someone else is assigned to the issue you should check with them before starting any work. 
- Create a branch for the feature you are working on, reference the issue # in the branch name. 
- Commit and push your changes frequently while you are working. 
- When your work is feature complete, and **all unit/integration/blackbox testing** is passing with appropriate coverage, open a pull request (PR) from the feature branch back to main. 

These pull requests must be peer reviewed before being merged back into the main branch of the repository. This review process may require additional updates before it is approved. This "merge to main" event is what drives CI automation. If you are asked to review a PR, do your best to accommodate a prompt review.

If you have questions about implementing a feature, create your feature branch and open a draft PR with detailed questions and request a review of that PR, and then post a link to the PR in the General channel on Discord.

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