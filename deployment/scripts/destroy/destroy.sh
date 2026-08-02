#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Safely destroy infrastructure for non-production environments.
#
# Usage: destroy.sh <environment> [--plan-only] [--auto-confirm]
# Production (prod) is permanently blocked.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env plan_only=false auto_confirm=false
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan-only) plan_only=true ;;
      --auto-confirm) auto_confirm=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  [[ "$env" != "prod" ]] || die "Destroy is permanently blocked for production."

  require_terraform
  local env_dir varfile
  env_dir="$(environment_dir "$env")"

  if [[ -f "$(var_file_path "$env")" ]]; then
    varfile="$(require_var_file "$env")"
  elif [[ -f "${env_dir}/terraform.tfvars.example" ]]; then
    varfile="${env_dir}/terraform.tfvars.example"
    log_warn "Using example tfvars: $varfile"
  else
    die "No tfvars file found for $env"
  fi

  "${SCRIPT_DIR}/../bootstrap/init-backend.sh" "$env"

  cd "$env_dir"

  # Pre-destroy state backup
  local backup_file="terraform.tfstate.pre-destroy.$(date +%Y%m%d%H%M%S)"
  log_info "Backing up state to $backup_file"
  terraform state pull > "$backup_file"

  local expected_phrase="destroy-${env}"

  if [[ "$auto_confirm" != true ]]; then
    log_warn "DESTRUCTIVE OPERATION — this will destroy all resources in $env"
    confirm_phrase "$expected_phrase" "Type '$expected_phrase' to confirm destroy"
  fi

  if [[ "$plan_only" == true ]]; then
    log_info "Planning destroy for $env"
    terraform plan -destroy -input=false -no-color -var-file="$varfile"
    log_success "Destroy plan complete (not executed)"
    exit 0
  fi

  log_info "Destroying environment: $env"
  terraform destroy -input=false -auto-approve -var-file="$varfile"

  log_success "Destroy complete for environment: $env"
  log_info "State backup retained at: ${env_dir}/${backup_file}"
}

main "$@"
