#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Quality Gates
#
# Usage: ./release/scripts/quality-gates.sh <environment>
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ENV="$(resolve_environment "${1:-}")"
ENV_DIR="$(environment_dir "$ENV")"
SUMMARY_FILE="${REPO_ROOT}/quality-gates-summary-${ENV}.md"

run_gate() {
  local name="$1"
  shift
  log_info "Gate: $name"
  if "$@"; then
    echo "| $name | passed |" >> "$SUMMARY_FILE"
    log_success "$name passed"
    return 0
  else
    echo "| $name | failed |" >> "$SUMMARY_FILE"
    log_error "$name failed"
    return 1
  fi
}

main() {
  require_terraform
  cd "$REPO_ROOT"

  cat > "$SUMMARY_FILE" <<EOF
# Quality Gates Summary — ${ENV}

| Gate | Result |
|------|--------|
EOF

  local failed=0

  run_gate "Format" terraform fmt -check -recursive || failed=1

  run_gate "Validate (${ENV})" bash -c "
    cd '${ENV_DIR}' &&
    terraform init -backend=false -input=false &&
    terraform validate
  " || failed=1

  if command -v tflint >/dev/null 2>&1; then
    run_gate "Lint" bash -c "tflint --init && tflint --recursive" || failed=1
  else
    echo "| Lint | skipped (tflint not installed) |" >> "$SUMMARY_FILE"
    log_warn "TFLint not installed — skipping"
  fi

  if command -v checkov >/dev/null 2>&1; then
    run_gate "Security (Checkov)" checkov -d . --framework terraform --quiet || failed=1
  else
    echo "| Security (Checkov) | skipped |" >> "$SUMMARY_FILE"
    log_warn "Checkov not installed — skipping"
  fi

  run_gate "Plan (${ENV})" bash -c "
    cd '${ENV_DIR}' &&
    terraform init -backend=false -input=false &&
    set +e &&
    terraform plan -input=false -no-color -var-file=terraform.tfvars.example -out=tfplan &&
    plan_exit=\$? &&
    set -e &&
    [[ \$plan_exit -eq 0 || \$plan_exit -eq 2 ]]
  " || failed=1

  if [[ "$failed" -ne 0 ]]; then
    log_error "Quality gates failed for ${ENV}. See ${SUMMARY_FILE}"
    exit 1
  fi

  log_success "All quality gates passed for ${ENV}"
  cat "$SUMMARY_FILE"
}

main "$@"
