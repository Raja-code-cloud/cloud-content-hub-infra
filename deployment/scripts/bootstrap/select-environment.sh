#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Select and validate target environment.
#
# Usage: select-environment.sh <dev|stage|prod>
# Output: Exports TF_ENV and prints environment directory path.
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

  [[ -d "$env_dir" ]] || die "Environment directory not found: $env_dir"

  export TF_ENV="$env"
  log_success "Environment selected: $env"
  log_info "Directory: $env_dir"
  echo "$env_dir"
}

main "$@"
