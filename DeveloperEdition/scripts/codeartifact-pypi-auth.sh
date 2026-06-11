#!/usr/bin/env sh
# Shared CodeArtifact PyPI auth helpers for API install/lock/build scripts.
set -e

codeartifact_load_env() {
  if [ -f "${HOME}/.mentorhub/aws-platform.env" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.mentorhub/aws-platform.env"
  fi
  if [ -f "${HOME}/.mentorhub/aws-platform.local.env" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.mentorhub/aws-platform.local.env"
  fi
}

codeartifact_ensure_sso() {
  profile="${MH_AWS_PROFILE_SHARED:-mentorhub-shared}"
  region="${AWS_REGION:-us-east-1}"
  export AWS_PROFILE="${profile}"

  if ! aws sts get-caller-identity --profile "${profile}" --region "${region}" >/dev/null 2>&1; then
    echo "AWS SSO session expired — opening login for profile: ${profile}" >&2
    aws sso login --profile "${profile}"
  fi
}

codeartifact_pypi_mirror_url() {
  domain="${CODEARTIFACT_DOMAIN:-mentor-forge}"
  owner="${AWS_SHARED_SERVICES_ACCOUNT_ID:-560167829275}"
  repo="${CODEARTIFACT_PYPI_REPO:-mentorhub-pypi}"
  region="${AWS_REGION:-us-east-1}"
  profile="${MH_AWS_PROFILE_SHARED:-mentorhub-shared}"

  export AWS_PROFILE="${profile}"

  TOKEN=$(aws codeartifact get-authorization-token \
    --domain "${domain}" \
    --domain-owner "${owner}" \
    --region "${region}" \
    --query authorizationToken --output text)

  END=$(aws codeartifact get-repository-endpoint \
    --domain "${domain}" \
    --domain-owner "${owner}" \
    --repository "${repo}" \
    --format pypi \
    --region "${region}" \
    --query repositoryEndpoint --output text)

  HOST="${END#https://}"
  printf '%s' "https://aws:${TOKEN}@${HOST}simple/"
}
