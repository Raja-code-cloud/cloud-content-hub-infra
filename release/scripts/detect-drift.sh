#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Drift Detection
#
# Usage: ./release/scripts/detect-drift.sh <environment|all>
# Exit codes: 0 = no drift, 1 = error, 2 = drift detected
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

detect_drift() {
  local env="$1"
  local env_dir
  env_dir="$(environment_dir "$env")"
  local report_dir="${REPO_ROOT}/drift-report-${env}-$(date +%Y%m%d%H%M%S)"

  mkdir -p "$report_dir"
  log_info "Drift detection: ${env}"

  cd "$env_dir"
  terraform init -backend=false -input=false

  local varfile="terraform.tfvars.example"
  [[ -f "terraform.tfvars" ]] && varfile="terraform.tfvars"

  set +e
  terraform plan -input=false -no-color -detailed-exitcode -var-file="$varfile" -out="${report_dir}/tfplan" 2>&1 | tee "${report_dir}/plan.log"
  local exit_code=$?
  set -e

  if [[ -f "${report_dir}/tfplan" ]]; then
    terraform show -no-color "${report_dir}/tfplan" > "${report_dir}/plan.txt" || true
  fi

  cat > "${report_dir}/drift-metadata.json" <<EOF
{
  "environment": "${env}",
  "detected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)",
  "drift_detected": $([ "$exit_code" -eq 2 ] && echo true || echo false),
  "exit_code": ${exit_code}
}
EOF

  {
    echo "# Drift Summary — ${env}"
    echo ""
    echo "**Detected at:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "**Exit code:** ${exit_code}"
    echo ""
    if [[ "$exit_code" -eq 0 ]]; then
      echo "No drift detected."
    elif [[ "$exit_code" -eq 2 ]]; then
      echo "⚠️ Drift detected. Review plan.txt in ${report_dir}"
    else
      echo "❌ Error during drift detection."
    fi
  } > "${report_dir}/drift-summary.md"

  log_info "Report: ${report_dir}"
  return "$exit_code"
}

main() {
  local target="${1:-}"
  [[ -n "$target" ]] || die "Usage: $(basename "$0") <environment|all>"

  require_terraform

  if [[ "$target" == "all" ]]; then
    local env
    local overall=0
    for env in "${VALID_ENVIRONMENTS[@]}"; do
      set +e
      detect_drift "$env"
      local code=$?
      set -e
      [[ "$code" -eq 1 ]] && overall=1
      [[ "$code" -eq 2 ]] && overall=2
    done
    exit "$overall"
  fi

  is_valid_environment "$target" || die "Invalid environment: $target"
  set +e
  detect_drift "$target"
  exit $?
}

main "$@"
