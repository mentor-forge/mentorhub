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

if ! grep -q '\[profile '"${MH_AWS_PROFILE_SHARED}"'\]' "$AWS_CONFIG" 2>/dev/null; then
  cat >> "$AWS_CONFIG" <<EOF

# Added by mentorhub aws-sso-setup ($(date +%Y-%m-%d))
[sso-session ${SSO_SESSION_NAME}]
sso_start_url = ${SSO_START_URL}
sso_region = ${SSO_REGION}
sso_registration_scopes = sso:account:access

[profile ${MH_AWS_PROFILE_SHARED}]
sso_session = ${SSO_SESSION_NAME}
sso_account_id = ${AWS_SHARED_SERVICES_ACCOUNT_ID}
sso_role_name = ${MH_AWS_SSO_ROLE_SHARED}
region = ${AWS_REGION}

EOF
  echo "Added profile ${MH_AWS_PROFILE_SHARED} to ${AWS_CONFIG}"
else
  echo "Profile ${MH_AWS_PROFILE_SHARED} already in ${AWS_CONFIG}"
fi

echo "Opening AWS SSO login for ${MH_AWS_PROFILE_SHARED}..."
aws sso login --profile "${MH_AWS_PROFILE_SHARED}"
