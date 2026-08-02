#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate environment root modules (dev, stage, prod).
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="environments"
FAILED=0
ENV="${1:-}"

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

require_command terraform

validate_environment() {
  local env="$1"
  local env_dir="${ENVIRONMENTS_DIR}/${env}"
  [[ -d "$env_dir" ]] || die "Environment not found: ${env}"
  run_gate "$SUITE" "validate:${env}" terraform_init_validate "$env_dir"
}

if [[ -n "$ENV" ]]; then
  validate_environment "$ENV" || FAILED=1
else
  while IFS= read -r env; do
    [[ -n "$env" ]] || continue
    validate_environment "$env" || FAILED=1
  done < <(discover_environments)
fi

write_suite_summary "$SUITE" "Environment Validation Report"
exit "$FAILED"
