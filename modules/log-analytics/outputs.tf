# ------------------------------------------------------------------------------
# Log Analytics Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Workspace ID (Customer ID / GUID) for the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "name" {
  description = "The name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_resource_id" {
  description = "The Azure Resource Manager ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "customer_id" {
  description = "The Customer ID (Workspace ID GUID) used by agents and diagnostic settings."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "The primary shared key for Log Analytics agent and API authentication. Treat as confidential."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "The secondary shared key for Log Analytics agent and API authentication. Treat as confidential."
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}

output "retention_in_days" {
  description = "Configured data retention period in days."
  value       = azurerm_log_analytics_workspace.this.retention_in_days
}

output "sku" {
  description = "Configured Log Analytics Workspace SKU."
  value       = azurerm_log_analytics_workspace.this.sku
}

output "workspace" {
  description = "Non-sensitive workspace metadata for downstream module composition."
  value = {
    id                  = azurerm_log_analytics_workspace.this.workspace_id
    name                = azurerm_log_analytics_workspace.this.name
    resource_id         = azurerm_log_analytics_workspace.this.id
    location            = azurerm_log_analytics_workspace.this.location
    resource_group_name = azurerm_log_analytics_workspace.this.resource_group_name
    retention_in_days   = azurerm_log_analytics_workspace.this.retention_in_days
    sku                 = azurerm_log_analytics_workspace.this.sku
  }
}
