# ------------------------------------------------------------------------------
# Container App Job Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Container Apps Job."
  value       = azurerm_container_app_job.this.id
}

output "name" {
  description = "The name of the Container Apps Job."
  value       = azurerm_container_app_job.this.name
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Container Apps Job."
  value       = azurerm_container_app_job.this.id
}

output "principal_id" {
  description = "Principal ID of the system-assigned managed identity, when configured."
  value       = try(azurerm_container_app_job.this.identity[0].principal_id, null)
}

output "job" {
  description = "Non-sensitive job metadata for downstream composition."
  value = {
    id   = azurerm_container_app_job.this.id
    name = azurerm_container_app_job.this.name
  }
}
