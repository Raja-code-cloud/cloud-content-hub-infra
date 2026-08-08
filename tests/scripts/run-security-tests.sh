#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Security scanning: Checkov, Trivy, secret detection.
# Note: tfsec was deprecated in favor of Checkov. See docs/terraform/DEPRECATED_TFSEC.md.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="security"
FAILED=0

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

run_gate "$SUITE" "secret scan" "${SCRIPT_DIR}/check-secrets.sh" || FAILED=1
run_gate "$SUITE" "sensitive outputs" "${SCRIPT_DIR}/check-sensitive-outputs.sh" || FAILED=1

if command -v checkov >/dev/null 2>&1; then
  run_gate "$SUITE" "checkov" bash -c \
    "checkov -d . --framework terraform --config-file .checkov.yml --quiet --output json > '${REPORTS_DIR}/checkov.json'" \
    || FAILED=1
else
  record_result "$SUITE" "checkov" "skipped" "checkov not installed"
  log_warn "Skipping checkov (not installed)"
fi

if command -v trivy >/dev/null 2>&1; then
  run_gate "$SUITE" "trivy" bash -c \
    "trivy config . --severity HIGH,CRITICAL --exit-code 1 --format json --output '${REPORTS_DIR}/trivy.json' --ignorefile .trivyignore" \
    || FAILED=1
else
  record_result "$SUITE" "trivy" "skipped" "trivy not installed"
  log_warn "Skipping trivy (not installed)"
fi

write_suite_summary "$SUITE" "Security Scan Report"
exit "$FAILED"
