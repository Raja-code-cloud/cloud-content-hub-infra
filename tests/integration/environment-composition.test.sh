#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Integration tests for environment composition.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
source "${SCRIPT_DIR}/../scripts/lib/common.sh"

FAILED=0

validate_composition() {
  local env="$1"
  local env_dir="${ENVIRONMENTS_DIR}/${env}"
  log_info "Composition test: ${env}"

  if [[ ! -f "${env_dir}/main.tf" ]]; then
    log_error "Missing main.tf for ${env}"
    return 1
  fi

  if ! grep -q 'module "' "${env_dir}/main.tf"; then
    log_warn "Environment ${env} does not declare module blocks yet"
  fi

  if terraform_init_validate "$env_dir"; then
    log_ok "Environment composition ${env} passed"
    return 0
  fi

  log_error "Environment composition ${env} failed"
  return 1
}

while IFS= read -r env; do
  [[ -n "$env" ]] || continue
  validate_composition "$env" || FAILED=1
done < <(discover_environments)

exit "$FAILED"
