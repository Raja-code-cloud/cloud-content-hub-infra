#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Deployment validation entry point — delegates to tests/scripts/run-all.sh
#
# Usage: run-all.sh <environment> [--skip-backend] [--skip-security] [--skip-lint]
# Legacy flags are mapped to test suite options where possible.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TEST_RUNNER="${REPO_ROOT}/tests/scripts/run-all.sh"

main() {
  local env="${1:-dev}"
  shift || true

  local skip_security=false
  local with_plan=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-backend) ;;
      --skip-security) skip_security=true ;;
      --skip-lint) ;;
      --with-plan) with_plan=true ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
  done

  if [[ ! -x "$TEST_RUNNER" ]]; then
    chmod +x "$TEST_RUNNER" "${REPO_ROOT}/tests/scripts/"*.sh 2>/dev/null || true
  fi

  local args=(--suite regression --env "$env")
  [[ "$with_plan" == true ]] && args+=(--with-plan)

  if [[ "$skip_security" == true ]]; then
    "$REPO_ROOT/tests/scripts/run-static-analysis.sh"
    "$REPO_ROOT/tests/scripts/run-module-tests.sh"
    "$REPO_ROOT/tests/scripts/run-environment-tests.sh" "$env"
    "$REPO_ROOT/tests/scripts/run-compliance-tests.sh"
    "$REPO_ROOT/tests/scripts/generate-report.sh"
  else
    "$TEST_RUNNER" "${args[@]}"
  fi
}

main "$@"
