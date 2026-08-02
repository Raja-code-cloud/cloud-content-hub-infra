#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Rollback to a previous Git ref by re-planning and applying.
#
# Usage: rollback.sh <environment> <git-ref> [--auto-confirm]
#
# Example: rollback.sh dev v1.2.2
#          rollback.sh stage HEAD~1
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

main() {
  local env git_ref auto_confirm=false
  env="$(resolve_environment "${1:-}")"
  git_ref="${2:-}"
  shift 2 || true

  [[ -n "$git_ref" ]] || die "Usage: rollback.sh <environment> <git-ref> [--auto-confirm]"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto-confirm) auto_confirm=true ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  require_command git
  local current_ref
  current_ref="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"

  log_warn "Rollback: $env → git ref $git_ref (current: $current_ref)"

  if [[ "$env" == "prod" ]]; then
    confirm_phrase "rollback-prod" "Type 'rollback-prod' to confirm production rollback"
  fi

  log_info "Checking out $git_ref (detached HEAD)"
  git -C "$REPO_ROOT" checkout "$git_ref"

  # Trap to return to original ref on failure
  cleanup() {
    log_info "Returning to $current_ref"
    git -C "$REPO_ROOT" checkout "$current_ref" 2>/dev/null || true
  }
  trap cleanup EXIT

  "${SCRIPT_DIR}/../validate/run-all.sh" "$env" || die "Validation failed at $git_ref"

  "${SCRIPT_DIR}/../deploy/plan.sh" "$env"

  local env_dir
  env_dir="$(environment_dir "$env")"
  log_warn "Review plan at ${env_dir}/plan.txt before proceeding."

  if [[ "$auto_confirm" == true ]]; then
    "${SCRIPT_DIR}/../deploy/apply.sh" "$env" --auto-confirm
  else
    confirm "Apply rollback plan?" && "${SCRIPT_DIR}/../deploy/apply.sh" "$env" --auto-confirm
  fi

  trap - EXIT
  log_info "Rollback apply complete. Consider creating a branch from $git_ref."
  log_success "Rollback finished for $env at $git_ref"
}

main "$@"
