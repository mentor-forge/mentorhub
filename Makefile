# `make update` reads GitHub org for docker login from product.yaml.
PRODUCT_FILE ?= Specifications/product.yaml
ORG := $(shell yq -r '.organization.git_org' $(PRODUCT_FILE))
.PHONY: help install update verify container push build-package publish-package build-all test-all aws-setup

help:
	@echo "Mentor Hub Developer CLI - Available commands:"
	@echo ""
	@echo "  make install        - Install Homebrew prerequisites and mentorhub CLI tools"
	@echo "  make verify        - Verify build tools and prerequisites"
	@echo "  make update        - Update mentorhub CLI tools and configure Docker/Git"
	@echo "  make aws-setup     - One-time CodeArtifact SSO setup (~/.aws/config)"
	@echo "  make build-package - Build the Mentor Hub welcome page Docker container locally"
	@echo "  make build-all     - Clone/pull architecture.yaml sibling repos; build journey API and SPA containers"
	@echo "  make test-all      - mh up all, then journey API e2e and SPA Cypress"
	@echo ""
	@echo "For more information, see ./CONTRIBUTING.md"

verify:
	@fail=0; \
	echo "=== Verifying installed tools ==="; \
	echo ""; \
	echo "--- Build tools ---"; \
	command -v make >/dev/null 2>&1 && printf "make:    " && make --version | head -1 || { echo "  FAIL: make"; fail=1; }; \
	command -v node >/dev/null 2>&1 && printf "node:    " && node --version || { echo "  FAIL: node"; fail=1; }; \
	command -v npm >/dev/null 2>&1 && printf "npm:     " && npm --version || { echo "  FAIL: npm"; fail=1; }; \
    (vite --version 2>/dev/null || npx vite --version 2>/dev/null) >/dev/null && printf "vite:    " && (vite --version 2>/dev/null || npx vite --version 2>/dev/null) || { echo "  FAIL: vite"; fail=1; }; \
	echo ""; \
	echo "--- Python tools (3.12 required for projects) ---"; \
	PY312=$$(command -v python3.12 2>/dev/null); \
	if [ -n "$$PY312" ] && $$PY312 -c "import sys; exit(0 if sys.version_info[:2] == (3, 12) else 1)" 2>/dev/null; then \
		printf "python3.12: " && $$PY312 --version; \
	else \
		echo "  python3.12: not in PATH (pipenv may use pyenv)"; \
	fi; \
	command -v pipenv >/dev/null 2>&1 && printf "pipenv:  " && pipenv --version || { echo "  FAIL: pipenv"; fail=1; }; \
	PYTEST=$$(mktemp -d); \
	if (cd "$$PYTEST" && pipenv --python 3.12 install >/dev/null 2>&1 && pipenv run python -c "import sys; exit(0 if sys.version_info[:2] == (3, 12) else 1)" >/dev/null 2>&1); then \
		echo "  pipenv+3.12: OK (projects will use 3.12 venv)"; \
	else \
		echo "  FAIL: pipenv cannot use Python 3.12 (install pyenv + 3.12 or python3.12)"; fail=1; \
	fi; \
	rm -rf "$$PYTEST"; \
	echo ""; \
	echo "--- Container tools ---"; \
	command -v docker >/dev/null 2>&1 && printf "docker:  " && docker --version || { echo "  FAIL: docker"; fail=1; }; \
	echo ""; \
	echo "--- GitHub & Git ---"; \
	[ -n "$${GITHUB_TOKEN:-}" ] && printf "GITHUB_TOKEN: set\n" || { echo "  FAIL: GITHUB_TOKEN (set env var)"; fail=1; }; \
	command -v git >/dev/null 2>&1 && printf "git:     " && git --version || { echo "  FAIL: git"; fail=1; }; \
	echo ""; \
	echo "--- AWS (CodeArtifact packages) ---"; \
	command -v aws >/dev/null 2>&1 && printf "aws:     " && aws --version 2>&1 | head -1 || { echo "  FAIL: aws (install AWS CLI v2 — see CONTRIBUTING.md Step 1)"; fail=1; }; \
	if [ -f "$$HOME/.mentorhub/aws-platform.env" ]; then \
		. "$$HOME/.mentorhub/aws-platform.env"; \
		[ -f "$$HOME/.mentorhub/aws-platform.local.env" ] && . "$$HOME/.mentorhub/aws-platform.local.env"; \
		printf "aws-platform.env: installed (profile %s)\n" "$${MH_AWS_PROFILE_SHARED:-mentorhub-shared}"; \
		if aws configure list-profiles 2>/dev/null | grep -qx "$${MH_AWS_PROFILE_SHARED:-mentorhub-shared}"; then \
			echo "  SSO profile: configured (run make aws-setup if package installs fail)"; \
		else \
			echo "  WARN: SSO profile not in ~/.aws/config — run make aws-setup"; \
		fi; \
	else \
		echo "  WARN: ~/.mentorhub/aws-platform.env missing — run make install && make aws-setup"; \
	fi; \
	if command -v aws >/dev/null 2>&1 && [ -f "$$HOME/.mentorhub/aws-platform.env" ]; then \
		. "$$HOME/.mentorhub/aws-platform.env"; \
		[ -f "$$HOME/.mentorhub/aws-platform.local.env" ] && . "$$HOME/.mentorhub/aws-platform.local.env"; \
		if aws codeartifact list-repositories --region "$${AWS_REGION:-us-east-1}" --profile "$${MH_AWS_PROFILE_SHARED:-mentorhub-shared}" --max-results 1 >/dev/null 2>&1; then \
			echo "  CodeArtifact: reachable ($${CODEARTIFACT_PYPI_REPO:-mentorhub-pypi}, $${CODEARTIFACT_NPM_REPO:-mentorhub-npm})"; \
		else \
			echo "  WARN: CodeArtifact not reachable — run mh or make aws-setup"; \
		fi; \
	fi; \
	echo "Checking git global user.name and user.email (recommended)..."; \
	git config --global user.name >/dev/null 2>&1 && echo "  user.name: set" || echo "  user.name: not set (recommended for commits)"; \
	git config --global user.email >/dev/null 2>&1 && echo "  user.email: set" || echo "  user.email: not set (recommended for commits)"; \
	echo ""; \
	echo "--- Utilities ---"; \
	command -v jq >/dev/null 2>&1 && printf "jq:      " && jq --version || { echo "  FAIL: jq"; fail=1; }; \
	command -v yq >/dev/null 2>&1 && printf "yq:      " && yq --version || { echo "  FAIL: yq"; fail=1; }; \
	command -v curl >/dev/null 2>&1 && printf "curl:    " && curl --version | head -1 || { echo "  FAIL: curl"; fail=1; }; \
	echo ""; \
	if [ $$fail -eq 1 ]; then \
		echo "Some prerequisites are missing. See CONTRIBUTING.md for install instructions."; \
		exit 1; \
	fi; \
	echo "=== All prerequisites verified ==="

install:
	@./scripts/install-prereqs.sh
	@echo "Installing mentorhub CLI..."
	@mkdir -p ~/.mentorhub
	@cp ./DeveloperEdition/aws-platform.env ~/.mentorhub/aws-platform.env
	@if [ ! -f ../.stage0-launch.yaml ]; then \
		printf 'umbrella: mentorhub\n' > ../.stage0-launch.yaml && \
		echo "Created ../.stage0-launch.yaml (launchpad stub for interactive mode)"; \
	fi
	@if ! grep -q "Added by mentorhub CLI install" ~/.zshrc 2>/dev/null; then \
		echo "\n# Added by mentorhub CLI install" >> ~/.zshrc; \
		echo "export PATH=\$$PATH:~/.mentorhub" >> ~/.zshrc; \
		echo "export GITHUB_TOKEN=\$$(cat ~/.mentorhub/GITHUB_TOKEN)" >> ~/.zshrc; \
		echo "source \$$HOME/.mentorhub/aws-platform.env" >> ~/.zshrc; \
		echo "[ -f \$$HOME/.mentorhub/aws-platform.local.env ] && source \$$HOME/.mentorhub/aws-platform.local.env" >> ~/.zshrc; \
		echo "Added ~/.mentorhub to PATH in ~/.zshrc"; \
	else \
		echo "~/.mentorhub already in PATH"; \
	fi
	@echo "Installation complete. Run 'source ~/.zshrc' or restart your terminal."

uninstall:
	@echo "Uninstalling mentorhub CLI..."
	@if [ -f ~/.zshrc ]; then \
		grep -v -e 'Added by mentorhub CLI install' \
			-e 'export PATH=.*~/.mentorhub' \
			-e 'export GITHUB_TOKEN=.*mentorhub/GITHUB_TOKEN' \
			-e 'source.*aws-platform\.env' \
			-e 'aws-platform\.local\.env.*source' \
			~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc && \
		echo "Removed mentorhub lines from ~/.zshrc"; \
	else \
		echo "~/.zshrc not found, skipping"; \
	fi
	@rm -rf ~/.mentorhub && echo "Removed ~/.mentorhub"
	@echo "Uninstall complete. Run 'source ~/.zshrc' or restart your terminal."

update: verify
	@echo "Updating mentorhub CLI..."
	@if [ ! -f ~/.mentorhub/GITHUB_TOKEN ]; then \
		echo "Error: GITHUB_TOKEN not found! - See ./DeveloperEdition/README.md"; \
		exit 1; \
	fi
	@export GITHUB_TOKEN=$$(cat ~/.mentorhub/GITHUB_TOKEN) && \
	printf '%s\n' "$(abspath $(CURDIR))" > ~/.mentorhub/MENTORHUB_PATH && \
	cp ./DeveloperEdition/mh ~/.mentorhub/mh && \
	chmod +x ~/.mentorhub/mh && \
	cp ./DeveloperEdition/scripts/codeartifact-pypi-auth.sh ~/.mentorhub/codeartifact-pypi-auth.sh && \
	chmod +x ~/.mentorhub/codeartifact-pypi-auth.sh && \
	cp ./DeveloperEdition/docker-compose.yaml ~/.mentorhub/docker-compose.yaml && \
	cp ./nginx.conf ~/.mentorhub/nginx.conf && \
	rm -rf ~/.mentorhub/cognito-local && \
	cp -R ./DeveloperEdition/cognito-local ~/.mentorhub/cognito-local && \
	cp ./DeveloperEdition/aws-platform.env ~/.mentorhub/aws-platform.env && \
	if ! grep -q "aws-platform.env" ~/.zshrc 2>/dev/null; then \
		echo "source \$$HOME/.mentorhub/aws-platform.env" >> ~/.zshrc; \
		echo "[ -f \$$HOME/.mentorhub/aws-platform.local.env ] && source \$$HOME/.mentorhub/aws-platform.local.env" >> ~/.zshrc; \
	fi && \
	git config --global --unset-all url."https://@github.com/".insteadOf 2>/dev/null || true && \
	git config --global url."https://x-access-token:$$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/" && \
	echo "Git URL configured" && \
	. $$HOME/.mentorhub/aws-platform.env && \
	[ -f $$HOME/.mentorhub/aws-platform.local.env ] && . $$HOME/.mentorhub/aws-platform.local.env; \
	MH_GHCR_ORG=$(ORG) ~/.mentorhub/mh && \
	echo "Updates completed"

aws-setup:
	@zsh ./DeveloperEdition/aws-sso-setup.sh

container:
	@echo "Building Mentor Hub container..."
	@DOCKER_BUILDKIT=0 docker build -t ghcr.io/mentor-forge/mentorhub:latest .
	@echo "Container built successfully: ghcr.io/mentor-forge/mentorhub:latest"

push:
	@echo "Pushing Mentor Hub container..."
	@docker push ghcr.io/mentor-forge/mentorhub:latest
	@echo "Container Pushed successfully: ghcr.io/mentor-forge/mentorhub:latest"

build-publish: container push

build-package: container
publish-package: push

build-all:
	@command -v yq >/dev/null 2>&1 || { \
		echo "Error: yq is required. See CONTRIBUTING.md prerequisites, then run make install."; \
		exit 1; \
	}
	@echo "Cloning, pulling, and building architecture.yaml repos in .."
	@entries=$$(yq -r '.architecture.["journey-domains"][] | .is_journey as $$j | .repos[] | select(.type != "spa_ref") | [.name, .type, ($$j == true)] | join(" ")' Specifications/architecture.yaml) || exit 1; \
	fail=0; \
	set -- $$entries; \
	while [ "$$#" -ge 3 ]; do \
		name=$$1; type=$$2; is_journey=$$3; \
		shift 3; \
		repo="mentorhub_$$name"; \
		path="../$$repo"; \
		if [ -d "$$path/.git" ]; then \
			echo "==> Pull $$repo"; \
			if ! git -C "$$path" pull; then \
				echo "Warning: Failed to pull $$repo"; \
				fail=1; \
			fi; \
		elif [ -e "$$path" ]; then \
			echo "Warning: $$path exists but is not a git repository; skipping"; \
			fail=1; \
			continue; \
		else \
			echo "==> Clone $$repo"; \
			if ! git clone "git@github.com:$(ORG)/$$repo.git" "$$path"; then \
				echo "Warning: Failed to clone $$repo"; \
				fail=1; \
				continue; \
			fi; \
		fi; \
		if [ "$$is_journey" != "true" ]; then \
			continue; \
		fi; \
		if [ "$$type" = "api" ]; then \
			echo "==> pipenv run container ($$repo)"; \
			if ! (cd "$$path" && pipenv run container); then \
				echo "Warning: Container build failed for $$repo"; \
				fail=1; \
			fi; \
		elif [ "$$type" = "spa" ]; then \
			echo "==> npm run container ($$repo)"; \
			if ! (cd "$$path" && npm run container); then \
				echo "Warning: Container build failed for $$repo"; \
				fail=1; \
			fi; \
		fi; \
	done; \
	if [ $$fail -ne 0 ]; then \
		echo "Build completed with failures."; \
		exit $$fail; \
	fi; \
	echo "Build complete."

test-all:
	@command -v yq >/dev/null 2>&1 || { \
		echo "Error: yq is required. See CONTRIBUTING.md prerequisites, then run make install."; \
		exit 1; \
	}
	@mh_bin=$$(command -v mh 2>/dev/null); \
	if [ -z "$$mh_bin" ] && [ -x "$$HOME/.mentorhub/mh" ]; then \
		mh_bin="$$HOME/.mentorhub/mh"; \
	fi; \
	if [ -z "$$mh_bin" ] || [ ! -x "$$mh_bin" ]; then \
		echo "Error: mh is required. Run make install && make update, then source ~/.zshrc."; \
		exit 1; \
	fi; \
	echo "==> mh up all"; \
	"$$mh_bin" up all || exit 1; \
	fail=0; \
	apis=$$(yq -r '.architecture.["journey-domains"][] | select(.is_journey == true) | .repos[] | select(.type == "api") | .name' Specifications/architecture.yaml) || exit 1; \
	for name in $$apis; do \
		repo="mentorhub_$$name"; \
		path="../$$repo"; \
		echo "==> pipenv run e2e ($$repo)"; \
		if [ ! -d "$$path" ]; then \
			echo "Warning: $$path is missing"; \
			fail=1; \
			continue; \
		fi; \
		if ! (cd "$$path" && pipenv run e2e); then \
			echo "Warning: e2e failed for $$repo"; \
			fail=1; \
		fi; \
	done; \
	spas=$$(yq -r '.architecture.["journey-domains"][] | select(.is_journey == true) | .repos[] | select(.type == "spa") | .name' Specifications/architecture.yaml) || exit 1; \
	for name in $$spas; do \
		repo="mentorhub_$$name"; \
		path="../$$repo"; \
		echo "==> npm run cypress:run ($$repo)"; \
		if [ ! -d "$$path" ]; then \
			echo "Warning: $$path is missing"; \
			fail=1; \
			continue; \
		fi; \
		if ! (cd "$$path" && npm run cypress:run); then \
			echo "Warning: Cypress failed for $$repo"; \
			fail=1; \
		fi; \
	done; \
	if [ $$fail -ne 0 ]; then \
		echo "Tests completed with failures."; \
		exit $$fail; \
	fi; \
	echo "Tests complete."

delete-package:
	@gh api -X DELETE /orgs/mentor-forge/packages/container/mentorhub
