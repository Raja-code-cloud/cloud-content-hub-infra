#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Plan validation: init, plan, analyze replacements, provider checks.
#
# Usage: run-plan-validation.sh [environment]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="plan"
FAILED=0
TARGET_ENV="${1:-}"

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

require_command terraform

plan_environment() {
  local env="$1"
  local env_dir="${ENVIRONMENTS_DIR}/${env}"
  local var_file="${env_dir}/terraform.tfvars.example"
  local plan_file="${env_dir}/tfplan-test"
  local plan_log="${REPORTS_DIR}/plan-${env}.log"

  [[ -d "$env_dir" ]] || die "Environment not found: ${env}"
  [[ -f "$var_file" ]] || die "Example var file not found: ${var_file}"

  log_info "Planning ${env}..."
  (
    cd "$env_dir"
    terraform init -backend=false -input=false >/dev/null
    set +e
    terraform plan -input=false -no-color -var-file=terraform.tfvars.example -out="$plan_file" > "$plan_log" 2>&1
    local exit_code=$?
    set -e
    if [[ "$exit_code" -ne 0 && "$exit_code" -ne 2 ]]; then
      cat "$plan_log" >&2
      exit 1
    fi
  ) && "${SCRIPT_DIR}/analyze-plan.sh" "$plan_file" "$env"
}

if [[ -n "$TARGET_ENV" ]]; then
  run_gate "$SUITE" "plan:${TARGET_ENV}" plan_environment "$TARGET_ENV" || FAILED=1
else
  while IFS= read -r env; do
    [[ -n "$env" ]] || continue
    run_gate "$SUITE" "plan:${env}" plan_environment "$env" || FAILED=1
  done < <(discover_environments)
fi

write_suite_summary "$SUITE" "Plan Validation Report"
exit "$FAILED"
