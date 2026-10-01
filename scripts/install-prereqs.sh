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

if ! command -v brew >/dev/null 2>&1; then
  echo "Error: Homebrew is not on PATH." >&2
  echo "Install Homebrew manually (CONTRIBUTING.md Step 1), open a new terminal, and rerun make install." >&2
  echo "Do not run sudo make install." >&2
  if [[ "$os" == "Linux" && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    echo "Homebrew is installed but not on PATH. Add this to ~/.zshrc:" >&2
    echo '  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >&2
  elif [[ "$os" == "Darwin" && "$(uname -m)" == "arm64" && -x /opt/homebrew/bin/brew ]]; then
    echo "Homebrew is installed but not on PATH. Add this to ~/.zprofile or ~/.zshrc:" >&2
    echo '  eval "$(/opt/homebrew/bin/brew shellenv)"' >&2
  elif [[ -x /usr/local/bin/brew ]]; then
    echo "Homebrew is installed but not on PATH. Add this to ~/.zprofile or ~/.zshrc:" >&2
    echo '  eval "$(/usr/local/bin/brew shellenv)"' >&2
  fi
  exit 1
fi

echo "Using Homebrew: $(command -v brew)"

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

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is missing; install Docker Desktop (see CONTRIBUTING.md)."
else
  echo "Skip Docker Desktop: docker is already available"
fi

echo "Required Homebrew packages are installed."
