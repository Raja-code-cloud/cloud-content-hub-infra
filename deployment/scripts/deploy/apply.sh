#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Apply saved Terraform plan with confirmation gate.
#
# Usage: apply.sh <environment> [--auto-confirm] [--plan-file PATH]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env auto_confirm=false plan_file=""
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto-confirm) auto_confirm=true ;;
      --plan-file)
        plan_file="$2"
        shift
        ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  require_terraform
  local env_dir
  env_dir="$(environment_dir "$env")"
  plan_file="${plan_file:-${env_dir}/tfplan}"

  [[ -f "$plan_file" ]] || die "Plan file not found: $plan_file — run plan.sh first."

  "${SCRIPT_DIR}/../bootstrap/init-backend.sh" "$env"

  # Confirmation gate
  if [[ "$auto_confirm" != true ]]; then
    if [[ "$env" == "prod" ]]; then
      log_warn "PRODUCTION APPLY — dual approval required in CI; local apply is break-glass only."
      confirm_phrase "$env" "Type environment name to confirm PRODUCTION apply"
      confirm_phrase "apply-prod" "Type 'apply-prod' to confirm"
    elif [[ "$env" == "stage" ]]; then
      confirm_phrase "$env" "Type environment name to confirm STAGING apply"
    else
      confirm_phrase "$env" "Type environment name to confirm apply"
    fi
  fi

  cd "$env_dir"
  log_info "Applying plan for environment: $env"
  log_info "Plan file: $plan_file"

  terraform apply -input=false -auto-approve "$plan_file"

  log_success "Apply complete for environment: $env"
  log_info "Outputs:"
  terraform output
}

main "$@"
