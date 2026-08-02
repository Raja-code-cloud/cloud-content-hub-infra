#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate Terraform configuration and provider versions.
#
# Usage: validate-providers.sh <environment> [--skip-backend]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env skip_backend=false
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-backend) skip_backend=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  require_terraform
  local env_dir
  env_dir="$(environment_dir "$env")"

  if [[ "$skip_backend" == true ]]; then
    "${SCRIPT_DIR}/init-terraform.sh" "$env" --skip-backend
  else
    "${SCRIPT_DIR}/init-backend.sh" "$env"
  fi

  cd "$env_dir"
  log_info "Running terraform validate"
  terraform validate

  log_info "Provider versions:"
  terraform providers

  log_success "Provider validation passed for environment: $env"
}

main "$@"
