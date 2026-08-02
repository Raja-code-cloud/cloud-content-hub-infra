#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Migrate local state to remote backend.
#
# Usage: migrate-state.sh <environment>
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env
  env="$(resolve_environment "${1:-}")"
  local env_dir
  env_dir="$(environment_dir "$env")"

  if [[ -f "${env_dir}/terraform.tfstate" ]]; then
    log_warn "Local state file found. Creating backup before migration."
    cp "${env_dir}/terraform.tfstate" "${env_dir}/terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)"
  fi

  log_info "Migrating state to remote backend for $env"
  "${SCRIPT_DIR}/init-backend.sh" "$env" --migrate-state
  log_success "State migration complete. Verify with: terraform state list"
}

main "$@"
