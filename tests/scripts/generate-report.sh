#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Aggregate test reports into a module health summary.
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

cd "$REPO_ROOT"
ensure_reports_dir

SUMMARY_FILE="${REPORTS_DIR}/test-framework-summary.md"
HEALTH_FILE="${REPORTS_DIR}/module-health-summary.md"

{
  echo "# Terraform Test Framework Summary"
  echo ""
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "Framework version: ${TEST_FRAMEWORK_VERSION}"
  echo ""
  echo "## Suite Results"
  echo ""
} > "$SUMMARY_FILE"

for suite_file in "${REPORTS_DIR}"/*-summary.md; do
  [[ -f "$suite_file" ]] || continue
  [[ "$suite_file" == "$SUMMARY_FILE" ]] && continue
  {
    echo "### $(basename "$suite_file" -summary.md)"
    echo ""
    tail -n +3 "$suite_file"
    echo ""
  } >> "$SUMMARY_FILE"
done

{
  echo "# Module Health Summary"
  echo ""
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "| Module | Validate | Docs | Notes |"
  echo "|--------|----------|------|-------|"
} > "$HEALTH_FILE"

while IFS= read -r module; do
  [[ -n "$module" ]] || continue
  local_validate="unknown"
  local_docs="unknown"
  local_notes=""

  if [[ -f "${REPORTS_DIR}/modules-results.jsonl" ]]; then
    if grep -F "\"name\":\"validate:${module}\"" "${REPORTS_DIR}/modules-results.jsonl" | grep -q '"status":"passed"'; then
      local_validate="passed"
    elif grep -F "\"name\":\"validate:${module}\"" "${REPORTS_DIR}/modules-results.jsonl" | grep -q '"status":"failed"'; then
      local_validate="failed"
    fi
  fi

  if [[ -f "${MODULES_DIR}/${module}/README.md" ]]; then
    local_docs="present"
  else
    local_docs="missing"
    local_notes="Missing README.md"
  fi

  echo "| ${module} | ${local_validate} | ${local_docs} | ${local_notes} |" >> "$HEALTH_FILE"
done < <(discover_modules)

log_ok "Reports written to ${REPORTS_DIR}"
exit 0
