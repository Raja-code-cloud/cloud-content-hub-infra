# ------------------------------------------------------------------------------
# Key Vault Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "vault_uri" {
  description = "The URI of the Key Vault for data plane operations."
  value       = azurerm_key_vault.this.vault_uri
}

output "name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.this.name
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "location" {
  description = "The Azure region of the Key Vault."
  value       = azurerm_key_vault.this.location
}

output "tenant_id" {
  description = "The Azure AD Tenant ID associated with the Key Vault."
  value       = azurerm_key_vault.this.tenant_id
}

output "vault" {
  description = "Non-sensitive Key Vault metadata for downstream module composition."
  value = {
    id        = azurerm_key_vault.this.id
    name      = azurerm_key_vault.this.name
    vault_uri = azurerm_key_vault.this.vault_uri
    location  = azurerm_key_vault.this.location
    tenant_id = azurerm_key_vault.this.tenant_id
    sku_name  = azurerm_key_vault.this.sku_name
  }
}
