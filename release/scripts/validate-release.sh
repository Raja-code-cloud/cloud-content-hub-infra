#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Validate Release Tag
#
# Usage: ./release/scripts/validate-release.sh <release_tag>
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

RELEASE_TAG="${1:-}"
[[ -n "$RELEASE_TAG" ]] || die "Usage: $(basename "$0") <release_tag>"

[[ "$RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+|-hotfix\.[0-9]+)?$ ]] || \
  die "Invalid release tag format: $RELEASE_TAG"

log_promotion "Validating release tag: $RELEASE_TAG"

checkout_git_ref "$RELEASE_TAG"

for env in "${VALID_ENVIRONMENTS[@]}"; do
  log_info "Validating environment: $env"
  cd "$(environment_dir "$env")"
  terraform init -backend=false -input=false
  terraform validate
done

"${SCRIPT_DIR}/quality-gates.sh" prod

log_success "Release ${RELEASE_TAG} validation complete."
