# ------------------------------------------------------------------------------
# Key Vault Module
#
# Creates exactly one Azure Key Vault.
# Does NOT create secrets, keys, certificates, RBAC, access policies, or private endpoints.
# See: modules/key-vault/README.md
# ------------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                            = var.vault_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = local.tenant_id
  sku_name                        = var.sku_name
  rbac_authorization_enabled      = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  tags                            = var.tags
}

check "purge_protection_retention" {
  assert {
    condition     = !var.purge_protection_enabled || var.soft_delete_retention_days >= 7
    error_message = "purge_protection_enabled requires soft_delete_retention_days of at least 7."
  }
}
