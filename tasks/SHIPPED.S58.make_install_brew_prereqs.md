# S58 – make install installs Homebrew prereqs on macOS and Linux

Status: Shipped
Type: Feature
Depends On: S57
Description: Extend `make install` so it ensures Homebrew is present (install if missing) and brew-installs Developer Edition CLI prerequisites on macOS and Linux. Add Homebrew to CONTRIBUTING Step 1. Extract brew logic to a bash script if the Makefile would become unwieldy.

## Context

- ../mentorhub/DeveloperEdition/standards/*.md
- ../mentorhub_api_utils/README.md
- ../mentorhub_spa_utils/README.md
- ./README.md
- ./Workshops/README.md
- ./CONTRIBUTING.md (Step 1 lists tools with ad-hoc macOS `brew install` notes; Homebrew itself is not a prerequisite; no Linux brew path)
- ./Makefile (`install` copies `~/.mentorhub` CLI files and patches `~/.zshrc`; it does not install tools)
- ./Makefile `verify` (canonical CLI tool list: make, node, npm, vite, python 3.12, pipenv, docker, git, aws, jq, yq, curl)
- https://docs.brew.sh/Installation (macOS)
- https://docs.brew.sh/Homebrew-on-Linux (Linux / WSL)

## Complexity (extract brew install; keep Makefile as the entrypoint)

`install` is already a multi-step recipe (mkdir, env copy, zshrc). Adding OS detection, Homebrew bootstrap, linuxbrew `shellenv`, and a package list would make the Makefile hard to maintain.

**Required split:** put prereq installation in `scripts/install-prereqs.sh` (repo-root `scripts/`, executable). `make install` calls that script first, then keeps the existing `~/.mentorhub` / `.zshrc` behavior. Do **not** inline brew bootstrap in the Makefile.

Do **not** move clone-all into a script (S57 keeps that loop in the Makefile).

## Goals

- CONTRIBUTING Step 1: add **Homebrew** as a prerequisite for macOS and Linux (WSL counts as Linux). Link official install docs. State that `make install` will install Homebrew if it is missing, then brew-install CLI tools. Windows native is unsupported; use WSL.
- `scripts/install-prereqs.sh`:
  - Detect OS (`uname -s`): Darwin vs Linux. Fail with a clear message on anything else.
  - If `brew` is not on PATH, install Homebrew via the official non-interactive install (`NONINTERACTIVE=1` + the current Homebrew install script). After install, `eval` brew `shellenv` (Apple Silicon `/opt/homebrew`, Intel `/usr/local`, Linux `/home/linuxbrew/.linuxbrew`). If the install needs a sudo password, print that requirement rather than hanging silently.
  - `brew update` is optional; prefer `brew install` of missing packages (idempotent).
  - Brew-install CLI prereqs that Homebrew can provide, aligned with CONTRIBUTING / `make verify`: **git**, **node** (npm comes with node; target Node v24+), **python@3.12**, **pipenv**, **jq**, **yq**, **awscli**, **curl**. Install **make** only if `make` is missing.
  - After node is available: `npm install -g vite` if `vite` / `npx vite` is missing. Cypress: install globally with npm only if CONTRIBUTING still lists it as a host prereq and it is not present; otherwise leave Cypress to per-SPA `npx cypress install`.
  - **Do not** fail the script if Docker Desktop / Mongo Compass are missing — those stay manual (macOS cask / vendor installer). Optionally `brew install --cask docker` on Darwin only if docker is missing **and** the operator can accept a cask GUI app; default is skip Docker and print “install Docker Desktop (see CONTRIBUTING)”.
  - Print each step (brew present / installing, each package skip vs install). Exit non-zero on brew or npm failures for required CLI packages.
  - Use `#!/usr/bin/env bash` and `set -euo pipefail`.
- `make install`:
  - Run `scripts/install-prereqs.sh` first.
  - Then preserve today’s install behavior (`~/.mentorhub`, aws-platform.env copy, `.stage0-launch.yaml` stub, zshrc PATH / GITHUB_TOKEN / env source).
  - Update `help` so `make install` mentions Homebrew prereqs plus CLI install.
- CONTRIBUTING Step 1: Homebrew first among utilities/build tools; note Linuxbrew PATH (`eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`) after first install; `make install` is the supported way to install the brew-backed tool list on both OSes. Keep vendor links for Docker Desktop and Mongo Compass.

## Testing Expectations

- `bash -n scripts/install-prereqs.sh`; `shellcheck` if available.
- `make -n install` shows the prereq script then existing copy/zshrc steps.
- Script dry-review: Darwin and Linux branches exist; non-Darwin/non-Linux fails; missing brew triggers official installer; `spa_ref` / clone-all unchanged.
- Grep CONTRIBUTING — Homebrew listed as a prereq for macOS and Linux; `make install` described as installing brew-backed tools.
- Do not require a live brew install in CI/sandbox if network/sudo is unavailable; syntax + branch review is enough to ship, with a note in Execution Notes.

## Outputs

- `scripts/install-prereqs.sh` — new executable (brew bootstrap + package install).
- `Makefile` — `install` invokes the script, then existing CLI install; help text.
- `CONTRIBUTING.md` — Homebrew prereq (macOS + Linux); `make install` installs those tools.

## Execution Notes

- Implemented `scripts/install-prereqs.sh` with Darwin/Linux validation, non-interactive official Homebrew bootstrap and `shellenv`, idempotent brew package checks, Node v24+ handling, Vite installation, and a non-fatal Docker Desktop reminder.
- Updated `make install` to run the prerequisite script before preserving the existing `~/.mentorhub`, launchpad stub, and `.zshrc` setup. Updated help text.
- Updated CONTRIBUTING Step 1 with macOS/Linux Homebrew guidance, WSL support, the Linuxbrew `shellenv` command, the brew-backed package list, and manual Docker Desktop/Mongo Compass guidance. Clarified that Cypress remains per-SPA rather than a host prerequisite.
- Validation run:
  - `bash -n scripts/install-prereqs.sh` — passed.
  - `shellcheck scripts/install-prereqs.sh` — skipped; `shellcheck` is not installed.
  - `make -n install` — passed; prerequisite script appears first, followed by all existing CLI copy and `.zshrc` steps.
  - `rg -n 'Homebrew|brew-backed|macOS or Linux|Linux install' CONTRIBUTING.md` — passed.
- Did not run the installer live, avoiding Homebrew/npm machine and network mutations as permitted by the testing expectations.
