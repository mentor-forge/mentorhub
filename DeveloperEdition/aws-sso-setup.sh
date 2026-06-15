#!/usr/bin/env zsh
# One-time (idempotent): CodeArtifact SSO profile in ~/.aws/config + browser login.
# Developers need only mentorhub-shared (Shared-Services / Developer-Packages).
set -e

AWS_CONFIG="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
PLATFORM_ENV="$HOME/.mentorhub/aws-platform.env"

if [[ ! -f "$PLATFORM_ENV" ]]; then
  echo "Error: $PLATFORM_ENV not found. Run make install in mentorhub first." >&2
  exit 1
fi
source "$PLATFORM_ENV"

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI not found. Install AWS CLI v2 (see CONTRIBUTING.md Step 1)." >&2
  exit 1
fi

mkdir -p "${AWS_CONFIG:h}"

profile_block="[profile ${MH_AWS_PROFILE_SHARED}]
sso_session = ${SSO_SESSION_NAME}
sso_account_id = ${AWS_SHARED_SERVICES_ACCOUNT_ID}
sso_role_name = ${MH_AWS_SSO_ROLE_SHARED}
region = ${AWS_REGION}
output = json"

session_block="[sso-session ${SSO_SESSION_NAME}]
sso_start_url = ${SSO_START_URL}
sso_region = ${SSO_REGION}
sso_registration_scopes = sso:account:access"

if grep -q '\[profile '"${MH_AWS_PROFILE_SHARED}"'\]' "$AWS_CONFIG" 2>/dev/null; then
  current_account=$(awk -v p="[profile ${MH_AWS_PROFILE_SHARED}]" '
    $0 == p { found=1; next }
    found && /^\[/ { exit }
    found && /^sso_account_id/ { print $3; exit }
  ' "$AWS_CONFIG")
  if [[ -n "$current_account" && "$current_account" != "${AWS_SHARED_SERVICES_ACCOUNT_ID}" ]]; then
    echo "Fixing ${MH_AWS_PROFILE_SHARED}: was account ${current_account}, need Shared-Services ${AWS_SHARED_SERVICES_ACCOUNT_ID}"
    awk -v p="[profile ${MH_AWS_PROFILE_SHARED}]" '
      $0 == p { skip=1; next }
      skip && /^\[/ { skip=0 }
      skip { next }
      { print }
    ' "$AWS_CONFIG" > "${AWS_CONFIG}.tmp" && mv "${AWS_CONFIG}.tmp" "$AWS_CONFIG"
    printf '%s\n\n' "$profile_block" >> "$AWS_CONFIG"
    echo "Updated profile ${MH_AWS_PROFILE_SHARED} in ${AWS_CONFIG}"
  else
    echo "Profile ${MH_AWS_PROFILE_SHARED} already targets Shared-Services in ${AWS_CONFIG}"
  fi
else
  if ! grep -q '\[sso-session '"${SSO_SESSION_NAME}"'\]' "$AWS_CONFIG" 2>/dev/null; then
    printf '%s\n\n' "$session_block" >> "$AWS_CONFIG"
    echo "Added SSO session ${SSO_SESSION_NAME} to ${AWS_CONFIG}"
  fi
  printf '%s\n\n' "$profile_block" >> "$AWS_CONFIG"
  echo "Added profile ${MH_AWS_PROFILE_SHARED} to ${AWS_CONFIG}"
fi

echo "Opening AWS SSO login for ${MH_AWS_PROFILE_SHARED}..."
aws sso login --profile "${MH_AWS_PROFILE_SHARED}"

echo "Verifying Shared-Services access..."
aws sts get-caller-identity --profile "${MH_AWS_PROFILE_SHARED}" --region "${AWS_REGION}"

echo "Refreshing CodeArtifact pip/npm credentials..."
aws codeartifact login --tool pip \
  --domain "${CODEARTIFACT_DOMAIN}" \
  --domain-owner "${AWS_SHARED_SERVICES_ACCOUNT_ID}" \
  --repository "${CODEARTIFACT_PYPI_REPO}" \
  --profile "${MH_AWS_PROFILE_SHARED}" \
  --region "${AWS_REGION}"
aws codeartifact login --tool npm \
  --domain "${CODEARTIFACT_DOMAIN}" \
  --domain-owner "${AWS_SHARED_SERVICES_ACCOUNT_ID}" \
  --repository "${CODEARTIFACT_NPM_REPO}" \
  --profile "${MH_AWS_PROFILE_SHARED}" \
  --region "${AWS_REGION}"

echo "AWS SSO and CodeArtifact setup complete for ${MH_AWS_PROFILE_SHARED}."
