#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Audit Record
#
# Usage: ./release/scripts/record-audit.sh --type promotion|rollback [options]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

RECORD_TYPE=""
TARGET=""
GIT_REF=""
RELEASE_TAG=""
PLAN_ARTIFACT=""
CHECKSUM=""
REASON=""
ACTOR="${USER:-unknown}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) RECORD_TYPE="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --git-ref) GIT_REF="$2"; shift 2 ;;
    --release-tag) RELEASE_TAG="$2"; shift 2 ;;
    --plan-artifact) PLAN_ARTIFACT="$2"; shift 2 ;;
    --checksum) CHECKSUM="$2"; shift 2 ;;
    --reason) REASON="$2"; shift 2 ;;
    --actor) ACTOR="$2"; shift 2 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$RECORD_TYPE" ]] || die "Usage: record-audit.sh --type promotion|rollback --target <env> ..."
[[ -n "$TARGET" ]] || die "--target is required"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
PROVIDER_VERSION="$(get_provider_version "$TARGET" azurerm)"
OUTPUT_DIR="${REPO_ROOT}/audit-records"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="${OUTPUT_DIR}/${RECORD_TYPE}-${TARGET}-${TIMESTAMP}.json"

if [[ "$RECORD_TYPE" == "promotion" ]]; then
  cat > "$OUTPUT_FILE" <<EOF
{
  "record_type": "promotion",
  "promotion_target": "${TARGET}",
  "git_ref": "${GIT_REF}",
  "git_commit": "${GIT_COMMIT}",
  "release_tag": "${RELEASE_TAG}",
  "terraform_version": "${REQUIRED_TERRAFORM_VERSION}",
  "provider_versions": { "azurerm": "${PROVIDER_VERSION}" },
  "plan_artifact": "${PLAN_ARTIFACT}",
  "plan_checksum_sha256": "${CHECKSUM}",
  "promoted_at": "${TIMESTAMP}",
  "actor": "${ACTOR}",
  "framework_version": "${RELEASE_FRAMEWORK_VERSION}"
}
EOF
else
  cat > "$OUTPUT_FILE" <<EOF
{
  "record_type": "rollback",
  "environment": "${TARGET}",
  "to_release_tag": "${RELEASE_TAG}",
  "git_commit": "${GIT_COMMIT}",
  "reason": "${REASON}",
  "terraform_version": "${REQUIRED_TERRAFORM_VERSION}",
  "provider_versions": { "azurerm": "${PROVIDER_VERSION}" },
  "plan_artifact": "${PLAN_ARTIFACT}",
  "plan_checksum_sha256": "${CHECKSUM}",
  "rolled_back_at": "${TIMESTAMP}",
  "actor": "${ACTOR}",
  "framework_version": "${RELEASE_FRAMEWORK_VERSION}"
}
EOF
fi

log_success "Audit record: ${OUTPUT_FILE}"
