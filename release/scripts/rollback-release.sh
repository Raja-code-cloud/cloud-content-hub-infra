#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Release Framework — Rollback Release
#
# Usage: ./release/scripts/rollback-release.sh <environment> <release_tag> [reason]
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ENV="$(resolve_environment "${1:-}")"
RELEASE_TAG="${2:-}"
REASON="${3:-Manual rollback}"

[[ -n "$RELEASE_TAG" ]] || die "Usage: $(basename "$0") <environment> <release_tag> [reason]"

log_promotion "Rollback: env=$ENV target_tag=$RELEASE_TAG reason=$REASON"

if [[ "$ENV" == "prod" ]]; then
  confirm_phrase "rollback-prod" "Type 'rollback-prod' to confirm production rollback"
else
  confirm_phrase "rollback-${ENV}" "Type 'rollback-${ENV}' to confirm rollback"
fi

checkout_git_ref "$RELEASE_TAG"

"${SCRIPT_DIR}/quality-gates.sh" "$ENV"

ENV_DIR="$(environment_dir "$ENV")"
cd "$ENV_DIR"
terraform init -backend=false -input=false

VARFILE="terraform.tfvars.example"
[[ -f "terraform.tfvars" ]] && VARFILE="terraform.tfvars"

log_promotion "Generating rollback plan at ${RELEASE_TAG}..."
terraform plan -input=false -no-color -var-file="$VARFILE" -out=tfplan
terraform show -no-color tfplan > plan.txt

log_promotion "Review plan.txt before applying rollback."

if [[ "$ENV" == "prod" ]]; then
  confirm_phrase "apply-rollback-prod" "Two-person review complete. Type 'apply-rollback-prod' to apply"
fi

terraform apply -input=false -auto-approve tfplan

CHECKSUM="$(compute_plan_checksum "${ENV_DIR}/tfplan")"

"${SCRIPT_DIR}/record-audit.sh" \
  --type rollback \
  --target "$ENV" \
  --git-ref "$RELEASE_TAG" \
  --release-tag "$RELEASE_TAG" \
  --plan-artifact "${ENV_DIR}/tfplan" \
  --checksum "$CHECKSUM" \
  --reason "$REASON"

log_success "Rollback to ${RELEASE_TAG} on ${ENV} complete."
