#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Static analysis suite: fmt, tflint, terraform-docs.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="static"
FAILED=0

cd "$REPO_ROOT"
ensure_reports_dir
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

require_command terraform

run_gate "$SUITE" "terraform fmt" terraform_fmt_check || FAILED=1

if command -v tflint >/dev/null 2>&1; then
  run_gate "$SUITE" "tflint" bash -c "tflint --init >/dev/null 2>&1 || true; tflint --recursive --format compact" || FAILED=1
else
  record_result "$SUITE" "tflint" "skipped" "tflint not installed"
  log_warn "Skipping tflint (not installed)"
fi

verify_terraform_docs() {
  local module
  local docs_failed=0
  while IFS= read -r module; do
    [[ -n "$module" ]] || continue
    terraform-docs markdown table --config .terraform-docs.yml "modules/${module}" >/dev/null
    if ! git diff --exit-code "modules/${module}/README.md" >/dev/null 2>&1; then
      log_error "Outdated docs: modules/${module}"
      docs_failed=1
    fi
  done < <(discover_modules)
  return "$docs_failed"
}

if command -v terraform-docs >/dev/null 2>&1; then
  run_gate "$SUITE" "terraform-docs" verify_terraform_docs || FAILED=1
else
  record_result "$SUITE" "terraform-docs" "skipped" "terraform-docs not installed"
  log_warn "Skipping terraform-docs (not installed)"
fi

write_suite_summary "$SUITE" "Static Analysis Report"
exit "$FAILED"
