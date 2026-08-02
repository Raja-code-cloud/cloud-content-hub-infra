# ------------------------------------------------------------------------------
# Remote State Backend — stage
#
# Backend type : azurerm
# State key    : stage.tfstate
#
# Placeholder values only — populate when the state storage account is
# provisioned. Do NOT commit real subscription or storage account values.
#
# See: docs/terraform/backend-strategy.md
# ------------------------------------------------------------------------------

terraform {
  backend "azurerm" {
    resource_group_name  = "<placeholder-resource-group>"
    storage_account_name = "<placeholder-storage-account>"
    container_name       = "tfstate"
    key                  = "stage.tfstate"
  }
}
