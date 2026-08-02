#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Run all validation gates for an environment.
#
# Usage: run-all.sh <environment> [--skip-backend] [--skip-security] [--skip-lint]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env skip_backend=false skip_security=false skip_lint=false
  env="$(resolve_environment "${1:-}")"
  shift || true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-backend) skip_backend=true ;;
      --skip-security) skip_security=true ;;
      --skip-lint) skip_lint=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  require_terraform
  local failed=0

  log_info "=== Validation: terraform fmt ==="
  if terraform fmt -recursive -check -diff; then
    log_success "fmt passed"
  else
    log_error "fmt failed — run: terraform fmt -recursive"
    failed=1
  fi

  log_info "=== Validation: terraform validate ==="
  if [[ "$skip_backend" == true ]]; then
    "${SCRIPT_DIR}/../bootstrap/validate-providers.sh" "$env" --skip-backend
  else
    "${SCRIPT_DIR}/../bootstrap/validate-providers.sh" "$env"
  fi

  if [[ "$skip_lint" != true ]] && command -v tflint >/dev/null 2>&1; then
    log_info "=== Validation: tflint ==="
    cd "$REPO_ROOT"
    tflint --init 2>/dev/null || true
    if tflint --recursive --format compact; then
      log_success "tflint passed"
    else
      log_warn "tflint reported issues"
      failed=1
    fi
  else
    log_warn "Skipping tflint (not installed or --skip-lint)"
  fi

  if [[ "$skip_security" != true ]]; then
    cd "$REPO_ROOT"
    if command -v checkov >/dev/null 2>&1; then
      log_info "=== Validation: checkov ==="
      if checkov -d "environments/${env}" --framework terraform --config-file .checkov.yml --quiet; then
        log_success "checkov passed"
      else
        log_warn "checkov reported findings"
        failed=1
      fi
    else
      log_warn "Skipping checkov (not installed)"
    fi

    if command -v tfsec >/dev/null 2>&1; then
      log_info "=== Validation: tfsec ==="
      if tfsec "environments/${env}" --minimum-severity HIGH; then
        log_success "tfsec passed"
      else
        log_warn "tfsec reported findings"
        failed=1
      fi
    else
      log_warn "Skipping tfsec (not installed)"
    fi

    if command -v trivy >/dev/null 2>&1; then
      log_info "=== Validation: trivy ==="
      if trivy config "environments/${env}" --severity HIGH,CRITICAL --exit-code 1; then
        log_success "trivy passed"
      else
        log_warn "trivy reported findings"
        failed=1
      fi
    else
      log_warn "Skipping trivy (not installed)"
    fi
  else
    log_warn "Skipping security scans (--skip-security)"
  fi

  if [[ $failed -eq 0 ]]; then
    log_success "All validation gates passed for $env"
  else
    die "One or more validation gates failed for $env"
  fi
}

main "$@"
