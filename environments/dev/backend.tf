# ------------------------------------------------------------------------------
# Remote State Backend — dev
#
# Backend type : azurerm
# State key    : dev.tfstate
#
# Placeholder values only — populate when the state storage account is
# provisioned. Do NOT commit real subscription or storage account values.
#
# See: docs/terraform/backend-strategy.md
# ------------------------------------------------------------------------------

terraform {
  backend "azurerm" {
    # Values supplied at init time via -backend-config (see backend.hcl.example).
    # Local validate/plan without remote state: terraform init -backend=false
  }
}
