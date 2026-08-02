#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Analyze Terraform plan for forced replacements and provider issues.
#
# Usage: analyze-plan.sh <plan-file> [environment]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

PLAN_FILE="${1:-}"
ENV="${2:-unknown}"

[[ -n "$PLAN_FILE" && -f "$PLAN_FILE" ]] || die "Plan file required: analyze-plan.sh <plan-file>"

require_command jq
ensure_reports_dir

PLAN_JSON="${REPORTS_DIR}/plan-${ENV}.json"
terraform show -json "$PLAN_FILE" > "$PLAN_JSON"

REPLACEMENTS="$(jq '[.resource_changes[]? | select(.change.actions | index("delete") and index("create")) | .address] | length' "$PLAN_JSON")"
CREATES="$(jq '[.resource_changes[]? | select(.change.actions | index("create")) | .address] | length' "$PLAN_JSON")"
UPDATES="$(jq '[.resource_changes[]? | select(.change.actions | index("update")) | .address] | length' "$PLAN_JSON")"
DELETES="$(jq '[.resource_changes[]? | select(.change.actions | index("delete")) | .address] | length' "$PLAN_JSON")"

FAIL_ON_REPLACEMENT="$(manifest_value '.plan_gates.fail_on_forced_replacement')"
MAX_REPLACEMENTS="$(manifest_value '.plan_gates.max_forced_replacements')"

{
  echo "# Plan Analysis — ${ENV}"
  echo ""
  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Creates | ${CREATES} |"
  echo "| Updates | ${UPDATES} |"
  echo "| Deletes | ${DELETES} |"
  echo "| Replacements | ${REPLACEMENTS} |"
} > "${REPORTS_DIR}/plan-analysis-${ENV}.md"

if [[ "$FAIL_ON_REPLACEMENT" == "true" && "$REPLACEMENTS" -gt "$MAX_REPLACEMENTS" ]]; then
  jq -r '.resource_changes[]? | select(.change.actions | index("delete") and index("create")) | .address' "$PLAN_JSON" >&2
  die "Plan for ${ENV} contains ${REPLACEMENTS} forced replacements (max ${MAX_REPLACEMENTS})."
fi

log_ok "Plan analysis passed for ${ENV} (replacements=${REPLACEMENTS})"
exit 0
