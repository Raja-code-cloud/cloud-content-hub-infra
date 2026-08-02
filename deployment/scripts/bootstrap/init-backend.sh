#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Initialize remote azurerm backend.
#
# Usage: init-backend.sh <environment> [--reconfigure] [--migrate-state]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env reconfigure=false migrate=false
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --reconfigure) reconfigure=true ;;
      --migrate-state) migrate=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  require_terraform
  local env_dir backend_config
  env_dir="$(environment_dir "$env")"
  backend_config="$(require_backend_config "$env")"

  cd "$env_dir"
  log_info "Initializing backend for $env"
  log_info "Backend config: $backend_config"

  local init_args=(-backend-config="$backend_config" -input=false)
  [[ "$reconfigure" == true ]] && init_args+=(-reconfigure)
  [[ "$migrate" == true ]] && init_args+=(-migrate-state)

  terraform init "${init_args[@]}"
  log_success "Backend initialized for environment: $env"
}

main "$@"
