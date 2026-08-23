#!/usr/bin/env bash
set -euo pipefail

os="$(uname -s)"
case "$os" in
  Darwin|Linux)
    ;;
  *)
    echo "Error: unsupported operating system '$os'. Use macOS or Linux (including WSL)." >&2
    exit 1
    ;;
esac

if command -v brew >/dev/null 2>&1; then
  echo "Skip Homebrew: already available ($(command -v brew))"
else
  echo "Install Homebrew: not found"
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required to bootstrap Homebrew. Install curl and retry." >&2
    exit 1
  fi
  if command -v sudo >/dev/null 2>&1 && ! sudo -n true >/dev/null 2>&1; then
    echo "Homebrew may need sudo. NONINTERACTIVE mode cannot request a password;"
    echo "run 'sudo -v' in another terminal first if the installer reports a permission error."
  fi
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "$os" == "Linux" ]]; then
    brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
  elif [[ "$(uname -m)" == "arm64" ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  else
    brew_bin="/usr/local/bin/brew"
  fi

  if [[ ! -x "$brew_bin" ]]; then
    echo "Error: Homebrew installation completed, but brew was not found at $brew_bin." >&2
    exit 1
  fi
  eval "$("$brew_bin" shellenv)"
fi

install_if_missing() {
  local formula="$1"
  local command_name="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    echo "Skip $formula: $command_name is already available"
  else
    echo "Install $formula: $command_name is missing"
    brew install "$formula"
  fi
}

install_if_missing git git

if command -v node >/dev/null 2>&1 && node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 24 ? 0 : 1)'; then
  echo "Skip node: Node $(node --version) satisfies v24+"
else
  echo "Install node: Node v24+ is missing"
  if brew list --formula node >/dev/null 2>&1; then
    brew upgrade node
  else
    brew install node
  fi
fi

if ! command -v node >/dev/null 2>&1 || ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 24 ? 0 : 1)'; then
  echo "Error: Homebrew completed, but Node v24+ is not available on PATH." >&2
  exit 1
fi

install_if_missing python@3.12 python3.12
install_if_missing pipenv pipenv
install_if_missing jq jq
install_if_missing yq yq
install_if_missing awscli aws
install_if_missing curl curl

if ! command -v make >/dev/null 2>&1; then
  echo "Install make: make is missing"
  brew install make
else
  echo "Skip make: already available"
fi

if command -v vite >/dev/null 2>&1 || npx --no-install vite --version >/dev/null 2>&1; then
  echo "Skip vite: already available"
else
  echo "Install vite: npm global package is missing"
  npm install -g vite
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is missing; install Docker Desktop (see CONTRIBUTING.md)."
else
  echo "Skip Docker Desktop: docker is already available"
fi

echo "Required Homebrew and npm prerequisites are installed."
