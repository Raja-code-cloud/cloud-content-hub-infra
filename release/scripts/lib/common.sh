#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Shared Library
# ------------------------------------------------------------------------------

set -euo pipefail

readonly RELEASE_FRAMEWORK_VERSION="1.0.0"
readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../../deployment/scripts/lib/common.sh
source "${REPO_ROOT}/deployment/scripts/lib/common.sh"

readonly VALID_PROMOTION_TARGETS=("dev" "stage" "prod")
readonly PROMOTION_PATH_DEV_REF="develop"
readonly PROMOTION_PATH_STAGE_REF="main"

log_promotion() {
  log_info "[PROMOTION] $*"
}

is_valid_promotion_target() {
  local target="$1"
  local candidate
  for candidate in "${VALID_PROMOTION_TARGETS[@]}"; do
    if [[ "$candidate" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

resolve_promotion_target() {
  local target="${1:-}"
  [[ -n "$target" ]] || die "Promotion target is required (dev, stage, prod)."
  is_valid_promotion_target "$target" || die "Invalid promotion target '$target'."
  echo "$target"
}

validate_promotion_path() {
  local target="$1"
  local git_ref="$2"
  local release_tag="${3:-}"

  case "$target" in
    dev)
      log_promotion "Dev promotion: git_ref=$git_ref"
      ;;
    stage)
      if [[ "$git_ref" != "main" && ! "$git_ref" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$ ]]; then
        log_warn "Stage promotion typically uses git_ref=main or an RC tag."
      fi
      ;;
    prod)
      [[ -n "$release_tag" ]] || die "Production promotion requires release_tag."
      [[ "$git_ref" == "$release_tag" ]] || die "Production git_ref must match release_tag."
      [[ "$release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-hotfix\.[0-9]+)?$ ]] || \
        die "Production release_tag must match v*.*.* or v*.*.*-hotfix.* pattern."
      ;;
  esac
}

checkout_git_ref() {
  local git_ref="$1"
  require_command git
  cd "$REPO_ROOT"
  git fetch --tags --quiet 2>/dev/null || true
  git checkout --quiet "$git_ref" || die "Cannot checkout git ref: $git_ref"
  log_promotion "Checked out $git_ref ($(git rev-parse --short HEAD))"
}

normalize_budget_date_placeholder() {
  : # reserved for future date helpers
}

compute_plan_checksum() {
  local plan_file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$plan_file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$plan_file" | awk '{print $1}'
  else
    echo "unavailable"
  fi
}

get_provider_version() {
  local env="$1"
  local provider="${2:-azurerm}"
  local lock_file="${REPO_ROOT}/environments/${env}/.terraform.lock.hcl"
  if [[ -f "$lock_file" ]]; then
    grep -A2 "${provider}" "$lock_file" | grep "version" | head -1 | tr -d '"' | awk '{print $3}' || echo "unknown"
  else
    echo "unknown"
  fi
}
