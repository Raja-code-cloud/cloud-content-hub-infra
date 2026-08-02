#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Generate Terraform plan and save artifact.
#
# Usage: plan.sh <environment> [--var-file PATH]
# Output: environments/<env>/tfplan, environments/<env>/plan.txt
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env varfile=""
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --var-file)
        varfile="$2"
        shift 2
        ;;
      *) die "Unknown option: $1" ;;
    esac
  done

  require_terraform
  local env_dir
  env_dir="$(environment_dir "$env")"

  "${SCRIPT_DIR}/../bootstrap/init-backend.sh" "$env"

  if [[ -z "$varfile" ]]; then
    if [[ -f "$(var_file_path "$env")" ]]; then
      varfile="$(require_var_file "$env")"
    elif [[ -f "${env_dir}/terraform.tfvars.example" ]]; then
      varfile="${env_dir}/terraform.tfvars.example"
      log_warn "Using example tfvars: $varfile"
    else
      die "No tfvars file found for $env"
    fi
  fi

  cd "$env_dir"
  log_info "Planning environment: $env"
  log_info "Var file: $varfile"

  set -o pipefail
  terraform plan \
    -input=false \
    -no-color \
    -var-file="$varfile" \
    -out=tfplan 2>&1 | tee plan.log

  terraform show -no-color tfplan > plan.txt

  log_success "Plan saved: ${env_dir}/tfplan"
  log_success "Plan text:  ${env_dir}/plan.txt"
}

main "$@"
