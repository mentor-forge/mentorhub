# `make update` reads GitHub org for docker login from product.yaml.
PRODUCT_FILE ?= Specifications/product.yaml
ORG := $(shell yq -r '.organization.git_org' $(PRODUCT_FILE))
.PHONY: help install update verify schemas container push build-package publish-package stage0-launch-ui clone-all aws-setup

help:
	@echo "Mentor Hub Developer CLI - Available commands:"
	@echo ""
	@echo "  make install        - Install mentorhub CLI tools to ~/.mentorhub"
	@echo "  make verify        - Verify build tools and prerequisites"
	@echo "  make update        - Update mentorhub CLI tools and configure Docker/Git"
	@echo "  make aws-setup     - One-time CodeArtifact SSO setup (~/.aws/config)"
	@echo "  make schemas       - Fetch JSON schemas for all data dictionaries, assumes mongodb_api is running"
	@echo "  make build-package - Build the Mentor Hub welcome page Docker container locally"
	@echo "  make clone-all     - git clone all repos (except umbrella) into parent folder via SSH"
	@echo "  make stage0-launch-ui - Stage0 Launch web UI, detached (export GITHUB_TOKEN; optional DELETE_ENABLED=True)"
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
	cp ./DeveloperEdition/mh ~/.mentorhub/mh && \
	chmod +x ~/.mentorhub/mh && \
	cp ./DeveloperEdition/scripts/codeartifact-pypi-auth.sh ~/.mentorhub/codeartifact-pypi-auth.sh && \
	chmod +x ~/.mentorhub/codeartifact-pypi-auth.sh && \
	cp ./DeveloperEdition/docker-compose.yaml ~/.mentorhub/docker-compose.yaml && \
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

schemas:
	@echo "Fetching JSON schemas for all data dictionaries..."
	@mkdir -p ./Specifications/schemas
	@yq -r '.data_dictionaries[].name' ./Specifications/catalog.yaml | \
	while IFS= read -r name; do \
		[ -z "$$name" ] && continue; \
		echo "Fetching schema for $${name}"; \
		curl -s "localhost:8180/api/configurations/json_schema/$${name}.yaml/0.1.0.0" > "./Specifications/schemas/$${name}.schema.json" \
		|| echo "Warning: Failed to fetch schema for $${name}"; \
	done
	@echo "Schema fetching complete."

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

clone-all:
	@echo "Cloning mentor-forge repos (except umbrella) into .."
	@cd .. && for repo in \
		mentorhub_mongodb_api \
		mentorhub_api_utils \
		mentorhub_spa_utils \
		mentorhub_customer_api \
		mentorhub_customer_spa \
		mentorhub_coordinator_api \
		mentorhub_coordinator_spa \
		mentorhub_mentor_api \
		mentorhub_mentor_spa \
		mentorhub_mentee_api \
		mentorhub_mentee_spa \
		mentorhub_runbook_api; \
	do \
		if [ -d "$$repo/.git" ]; then \
			echo "Skip (exists): $$repo"; \
		else \
			git clone "git@github.com:mentor-forge/$$repo.git" "$$repo"; \
		fi; \
	done
	@echo "Clone complete."

stage0-launch-ui:
	@[ -n "$$GITHUB_TOKEN" ] || (echo "Error: export GITHUB_TOKEN first (never commit tokens)."; exit 1)
	@echo "Starting Stage0 Launch: http://localhost:8080"
	docker run -d --rm --name stage0_launch_ui \
		-p 8080:8080 \
		-v "$(abspath $(CURDIR)/..):/launchpad" \
		-v "$(CURDIR)/Specifications:/specifications" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e LAUNCHPAD_DIR=/launchpad \
		-e SPECIFICATIONS=/specifications \
		-e STAGE0_LAUNCH_CONTAINER_NAME=stage0_launch_ui \
		-e GITHUB_TOKEN \
		-e GH_TOKEN=$$GITHUB_TOKEN \
		-e GH_USERNAME \
		-e GITHUB_USERNAME \
		ghcr.io/agile-learning-institute/stage0_launch:latest

delete-package:
	@gh api -X DELETE /orgs/mentor-forge/packages/container/mentorhub