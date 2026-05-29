#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BP_SCRIPT_DIR="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/audit.sh
source "${SCRIPT_DIR}/lib/audit.sh"
# shellcheck source=lib/org-ruleset.sh
source "${SCRIPT_DIR}/lib/org-ruleset.sh"
# shellcheck source=lib/repo-ruleset.sh
source "${SCRIPT_DIR}/lib/repo-ruleset.sh"
# shellcheck source=lib/verify.sh
source "${SCRIPT_DIR}/lib/verify.sh"
# shellcheck source=lib/apply.sh
source "${SCRIPT_DIR}/lib/apply.sh"

bp_load_config "$SCRIPT_DIR"

usage() {
  cat <<'EOF'
Configure mentor-forge branch protection via GitHub CLI.

Usage:
  configure-branch-protection.sh audit   [options]
  configure-branch-protection.sh plan    --phase soft|hard|full [options]
  configure-branch-protection.sh apply   --phase soft|hard|full [options]
  configure-branch-protection.sh verify  [options]

Commands:
  audit    Read-only report of rulesets, CI workflows, and readiness
  plan     Preview changes (--dry-run apply)
  apply    Create or update GitHub rulesets
  verify   Confirm rulesets are active

See DeveloperEdition/scripts/branch-protection/README.md
EOF
}

main() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    usage
    exit 1
  fi
  shift || true

  case "$cmd" in
    audit) audit_main "$@" ;;
    plan) plan_main "$@" ;;
    apply) apply_main "$@" ;;
    verify) verify_main "$@" ;;
    -h | --help | help)
      usage
      ;;
    *)
      bp_die "unknown command: $cmd"
      ;;
  esac
}

main "$@"
