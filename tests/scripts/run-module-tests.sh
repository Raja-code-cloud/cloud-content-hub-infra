#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Validate every module independently.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="modules"
FAILED=0
MODULE="${1:-}"

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

require_command terraform

validate_module() {
  local module="$1"
  local module_dir="${MODULES_DIR}/${module}"
  [[ -d "$module_dir" ]] || die "Module not found: ${module}"
  run_gate "$SUITE" "validate:${module}" terraform_init_validate "$module_dir"
}

if [[ -n "$MODULE" ]]; then
  validate_module "$MODULE" || FAILED=1
else
  while IFS= read -r module; do
    [[ -n "$module" ]] || continue
    validate_module "$module" || FAILED=1
  done < <(discover_modules)
fi

write_suite_summary "$SUITE" "Module Validation Report"
exit "$FAILED"
