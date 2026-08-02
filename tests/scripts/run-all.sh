#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Run the complete Terraform testing framework.
#
# Usage:
#   ./tests/scripts/run-all.sh [--suite all|static|modules|environments|security|compliance|plan|regression] [--env dev] [--with-plan]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="all"
ENV=""
WITH_PLAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite)
      SUITE="$2"
      shift
      ;;
    --env)
      ENV="$2"
      shift
      ;;
    --with-plan)
      WITH_PLAN=true
      ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --suite <name>   all | static | modules | environments | security | compliance | plan | regression
  --env <name>     Target environment for plan suite (dev, stage, prod)
  --with-plan      Include plan validation in regression suite
  -h, --help       Show help
EOF
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

cd "$REPO_ROOT"
ensure_reports_dir

FAILED=0

run_suite() {
  local name="$1"
  shift
  log_info "=== Running suite: ${name} ==="
  if "$@"; then
    log_ok "Suite ${name} passed"
  else
    log_error "Suite ${name} failed"
    FAILED=1
  fi
}

case "$SUITE" in
  all)
    run_suite "static" "${SCRIPT_DIR}/run-static-analysis.sh"
    run_suite "modules" "${SCRIPT_DIR}/run-module-tests.sh"
    run_suite "environments" "${SCRIPT_DIR}/run-environment-tests.sh"
    run_suite "security" "${SCRIPT_DIR}/run-security-tests.sh"
    run_suite "compliance" "${SCRIPT_DIR}/run-compliance-tests.sh"
    run_suite "unit" "${TESTS_DIR}/unit/module-validation.test.sh"
    run_suite "integration" "${TESTS_DIR}/integration/environment-composition.test.sh"
    if [[ "$WITH_PLAN" == true ]]; then
      if [[ -n "$ENV" ]]; then
        run_suite "plan" "${SCRIPT_DIR}/run-plan-validation.sh" "$ENV"
      else
        run_suite "plan" "${SCRIPT_DIR}/run-plan-validation.sh"
      fi
    fi
    ;;
  static) run_suite "static" "${SCRIPT_DIR}/run-static-analysis.sh" ;;
  modules) run_suite "modules" "${SCRIPT_DIR}/run-module-tests.sh" ;;
  environments) run_suite "environments" "${SCRIPT_DIR}/run-environment-tests.sh" ;;
  security) run_suite "security" "${SCRIPT_DIR}/run-security-tests.sh" ;;
  compliance) run_suite "compliance" "${SCRIPT_DIR}/run-compliance-tests.sh" ;;
  plan)
    if [[ -n "$ENV" ]]; then
      run_suite "plan" "${SCRIPT_DIR}/run-plan-validation.sh" "$ENV"
    else
      run_suite "plan" "${SCRIPT_DIR}/run-plan-validation.sh"
    fi
    ;;
  regression)
    local args=()
    [[ "$WITH_PLAN" == true ]] && args+=(--with-plan)
    [[ -n "$ENV" ]] && args+=(--env "$ENV")
    run_suite "regression" "${SCRIPT_DIR}/run-regression-tests.sh" "${args[@]}"
    ;;
  *)
    die "Unknown suite: ${SUITE}"
    ;;
esac

"${SCRIPT_DIR}/generate-report.sh"

if [[ "$FAILED" -ne 0 ]]; then
  die "One or more test suites failed. See ${REPORTS_DIR}/"
fi

log_ok "All requested test suites passed"
exit 0
