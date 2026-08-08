#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Regression suite: static, modules, environments, security, compliance.
# Optional plan validation when --with-plan is specified.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

WITH_PLAN=false
ENV=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-plan) WITH_PLAN=true ;;
    --env)
      ENV="$2"
      shift
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

SUITE="regression"
FAILED=0

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

run_regression_gate() {
  local name="$1"
  shift
  if "$@"; then
    record_result "$SUITE" "$name" "passed"
    log_ok "${name} passed"
  else
    record_result "$SUITE" "$name" "failed"
    log_error "${name} failed"
    FAILED=1
  fi
}

run_regression_gate "static analysis" "${SCRIPT_DIR}/run-static-analysis.sh"
run_regression_gate "module tests" "${SCRIPT_DIR}/run-module-tests.sh"
run_regression_gate "environment tests" "${SCRIPT_DIR}/run-environment-tests.sh"
run_regression_gate "security tests" "${SCRIPT_DIR}/run-security-tests.sh"
run_regression_gate "compliance tests" "${SCRIPT_DIR}/run-compliance-tests.sh"
run_regression_gate "unit tests" "${TESTS_DIR}/unit/module-validation.test.sh"
run_regression_gate "integration tests" "${TESTS_DIR}/integration/environment-composition.test.sh"

if [[ "$WITH_PLAN" == true ]]; then
  if [[ -n "$ENV" ]]; then
    run_regression_gate "plan validation (${ENV})" "${SCRIPT_DIR}/run-plan-validation.sh" "$ENV"
  else
    run_regression_gate "plan validation" "${SCRIPT_DIR}/run-plan-validation.sh"
  fi
fi

write_suite_summary "$SUITE" "Regression Test Report"
exit "$FAILED"
