# ------------------------------------------------------------------------------
# Azure Container Registry Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Container Registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "The name of the Container Registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "The login server URL for the Container Registry (e.g. myregistry.azurecr.io)."
  value       = azurerm_container_registry.this.login_server
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Container Registry."
  value       = azurerm_container_registry.this.id
}

output "sku" {
  description = "The SKU tier of the Container Registry."
  value       = azurerm_container_registry.this.sku
}

output "admin_username" {
  description = "The admin username when admin_enabled is true. Null when admin user is disabled."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_username : null
  sensitive   = true
}

output "admin_password" {
  description = "The admin password when admin_enabled is true. Null when admin user is disabled. Store in Key Vault — never commit."
  value       = var.admin_enabled ? azurerm_container_registry.this.admin_password : null
  sensitive   = true
}

output "registry" {
  description = "Non-sensitive registry metadata for downstream module composition."
  value = {
    id           = azurerm_container_registry.this.id
    name         = azurerm_container_registry.this.name
    login_server = azurerm_container_registry.this.login_server
    sku          = azurerm_container_registry.this.sku
    location     = azurerm_container_registry.this.location
  }
}
