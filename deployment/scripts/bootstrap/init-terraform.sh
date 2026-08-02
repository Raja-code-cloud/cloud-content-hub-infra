#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Initialize Terraform (providers and modules).
#
# Usage: init-terraform.sh <environment> [--skip-backend]
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
  local env_dir backend_config
  env_dir="$(environment_dir "$env")"

  cd "$env_dir"
  log_info "Initializing Terraform in $env_dir"

  if [[ "$skip_backend" == true ]]; then
    terraform init -backend=false -input=false
  else
    backend_config="$(require_backend_config "$env")"
    terraform init -backend-config="$backend_config" -input=false
  fi

  log_success "Terraform initialized for environment: $env"
}

main "$@"
