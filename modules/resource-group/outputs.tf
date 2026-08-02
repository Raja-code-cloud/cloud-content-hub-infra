# ------------------------------------------------------------------------------
# Resource Group Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The ID of the Azure Resource Group."
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "The name of the Azure Resource Group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "The Azure region of the Resource Group."
  value       = azurerm_resource_group.this.location
}

output "resource_group" {
  description = "Resource group object containing id, name, location, and tags."
  value = {
    id       = azurerm_resource_group.this.id
    name     = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
    tags     = azurerm_resource_group.this.tags
  }
}

output "lock_id" {
  description = "The ID of the management lock when create_resource_lock is true. Null when no lock is created."
  value       = var.create_resource_lock ? azurerm_management_lock.this[0].id : null
}

output "lock_level" {
  description = "The applied management lock level when create_resource_lock is true. Null when no lock is created."
  value       = var.create_resource_lock ? azurerm_management_lock.this[0].lock_level : null
}
