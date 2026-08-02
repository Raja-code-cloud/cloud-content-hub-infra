#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Promote
#
# Usage: ./release/scripts/promote.sh <target> <git_ref> [release_tag]
#
# Examples:
#   ./release/scripts/promote.sh dev develop
#   ./release/scripts/promote.sh stage main
#   ./release/scripts/promote.sh prod v1.2.3 v1.2.3
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

TARGET="$(resolve_promotion_target "${1:-}")"
GIT_REF="${2:-}"
RELEASE_TAG="${3:-}"

[[ -n "$GIT_REF" ]] || die "Usage: $(basename "$0") <target> <git_ref> [release_tag]"

validate_promotion_path "$TARGET" "$GIT_REF" "$RELEASE_TAG"

log_promotion "Starting promotion: target=$TARGET git_ref=$GIT_REF release_tag=${RELEASE_TAG:-none}"

checkout_git_ref "$GIT_REF"

"${SCRIPT_DIR}/quality-gates.sh" "$TARGET"

ENV_DIR="$(environment_dir "$TARGET")"
PLAN_FILE="${ENV_DIR}/tfplan"

log_promotion "Generating plan artifact..."
cd "$ENV_DIR"
terraform init -backend=false -input=false

VARFILE="terraform.tfvars.example"
if [[ -f "terraform.tfvars" ]]; then
  VARFILE="terraform.tfvars"
fi

terraform plan -input=false -no-color -var-file="$VARFILE" -out=tfplan
terraform show -no-color tfplan > plan.txt

CHECKSUM="$(compute_plan_checksum "$PLAN_FILE")"
log_promotion "Plan checksum: $CHECKSUM"

if [[ "$TARGET" == "dev" ]]; then
  log_promotion "Dev promotion: applying automatically..."
  confirm "Apply plan to ${TARGET}?" && terraform apply -input=false -auto-approve tfplan
elif [[ "$TARGET" == "stage" ]]; then
  log_promotion "Stage promotion: plan ready for review."
  log_promotion "Review plan.txt then run: cd ${ENV_DIR} && terraform apply tfplan"
  confirm "Apply plan to ${TARGET}?" && terraform apply -input=false -auto-approve tfplan
else
  log_promotion "Production promotion: plan ready for two-person review."
  log_promotion "Review plan.txt. Two approvers required before apply."
  confirm_phrase "apply-prod" "Type 'apply-prod' after two-person review to apply"
  terraform apply -input=false -auto-approve tfplan
fi

"${SCRIPT_DIR}/record-audit.sh" \
  --type promotion \
  --target "$TARGET" \
  --git-ref "$GIT_REF" \
  --release-tag "${RELEASE_TAG:-}" \
  --plan-artifact "$PLAN_FILE" \
  --checksum "$CHECKSUM"

log_success "Promotion to ${TARGET} complete."
