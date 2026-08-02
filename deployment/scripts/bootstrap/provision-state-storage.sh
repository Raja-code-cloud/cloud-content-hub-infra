#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# provision-state-storage.sh
#
# One-time platform bootstrap: creates Azure Storage for Terraform remote state.
# Run from a subscription with permission to create resource groups and storage.
#
# Usage:
#   ./deployment/scripts/bootstrap/provision-state-storage.sh <subscription-id> <location> [prefix]
#
# Example:
#   ./deployment/scripts/bootstrap/provision-state-storage.sh \
#     "00000000-0000-0000-0000-000000000000" eastus platform
# ------------------------------------------------------------------------------
set -euo pipefail

SUBSCRIPTION_ID="${1:?Usage: $0 <subscription-id> <location> [prefix]}"
LOCATION="${2:?Usage: $0 <subscription-id> <location> [prefix]}"
PREFIX="${3:-platform}"

RG_NAME="rg-${PREFIX}-tfstate"
STORAGE_NAME="st${PREFIX}tfstate"
CONTAINER_NAME="tfstate"

echo "Provisioning Terraform state storage in subscription ${SUBSCRIPTION_ID}..."

az account set --subscription "${SUBSCRIPTION_ID}"

if ! az group show --name "${RG_NAME}" &>/dev/null; then
  az group create --name "${RG_NAME}" --location "${LOCATION}" \
    --tags purpose=terraform-state managed-by=cloud-content-hub-infra
fi

if ! az storage account show --name "${STORAGE_NAME}" --resource-group "${RG_NAME}" &>/dev/null; then
  az storage account create \
    --name "${STORAGE_NAME}" \
    --resource-group "${RG_NAME}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --https-only true \
    --tags purpose=terraform-state
fi

az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_NAME}" \
  --auth-mode login \
  --only-show-errors 2>/dev/null || true

cat <<EOF

State storage provisioned successfully.

Configure each environment backend.hcl:

  resource_group_name  = "${RG_NAME}"
  storage_account_name = "${STORAGE_NAME}"
  container_name       = "${CONTAINER_NAME}"
  key                  = "<environment>.tfstate"

Configure GitHub Environment secrets:

  TF_STATE_RESOURCE_GROUP  = ${RG_NAME}
  TF_STATE_STORAGE_ACCOUNT = ${STORAGE_NAME}
  TF_STATE_CONTAINER       = ${CONTAINER_NAME}
  TF_STATE_KEY             = <environment>.tfstate

Next: ./deployment/scripts/bootstrap/init-backend.sh dev

EOF
