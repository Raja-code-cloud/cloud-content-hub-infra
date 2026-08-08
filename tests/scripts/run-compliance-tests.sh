#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Repository compliance checks against enterprise standards.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SUITE="compliance"
FAILED=0

cd "$REPO_ROOT"
ensure_reports_dir
require_jq
: > "${REPORTS_DIR}/${SUITE}-results.jsonl"

check_module_structure() {
  local module
  local file
  local missing=0
  while IFS= read -r module; do
    [[ -n "$module" ]] || continue
    while IFS= read -r file; do
      file="$(strip_cr "$file")"
      [[ -n "$file" ]] || continue
      [[ -f "${MODULES_DIR}/${module}/${file}" ]] || {
        log_error "Missing ${file} in modules/${module}"
        missing=1
      }
    done < <(jq -r '.repository_standards.module_required_files[]' "$COMPLIANCE_FILE")
    [[ ! -f "${MODULES_DIR}/${module}/providers.tf" ]] || {
      log_error "modules/${module}/providers.tf violates provider inheritance standard"
      missing=1
    }
  done < <(discover_modules)
  return "$missing"
}

check_environment_structure() {
  local env
  local file
  local missing=0
  while IFS= read -r env; do
    [[ -n "$env" ]] || continue
    while IFS= read -r file; do
      file="$(strip_cr "$file")"
      [[ -n "$file" ]] || continue
      [[ -f "${ENVIRONMENTS_DIR}/${env}/${file}" ]] || {
        log_error "Missing ${file} in environments/${env}"
        missing=1
      }
    done < <(jq -r '.repository_standards.environment_required_files[]' "$COMPLIANCE_FILE")
  done < <(discover_environments)
  return "$missing"
}

check_forbidden_committed_files() {
  local pattern
  local hits=0
  while IFS= read -r pattern; do
    pattern="$(strip_cr "$pattern")"
    [[ -n "$pattern" ]] || continue
    if git ls-files "$pattern" 2>/dev/null | grep -v '\.example$' | grep -q .; then
      log_error "Forbidden committed file pattern matched: ${pattern}"
      hits=1
    fi
  done < <(jq -r '.repository_standards.forbidden_committed_files[]' "$COMPLIANCE_FILE")
  return "$hits"
}

check_naming_module_present() {
  [[ -d "${MODULES_DIR}/naming" && -f "${MODULES_DIR}/naming/main.tf" ]]
}

run_gate "$SUITE" "module structure" check_module_structure || FAILED=1
run_gate "$SUITE" "environment structure" check_environment_structure || FAILED=1
run_gate "$SUITE" "forbidden committed files" check_forbidden_committed_files || FAILED=1
run_gate "$SUITE" "naming module present" check_naming_module_present || FAILED=1

write_suite_summary "$SUITE" "Compliance Report"
exit "$FAILED"
