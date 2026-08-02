# ------------------------------------------------------------------------------
# Application Insights Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Application Insights application ID (GUID)."
  value       = azurerm_application_insights.this.app_id
}

output "instrumentation_key" {
  description = "The instrumentation key for Application Insights SDK configuration. Treat as confidential."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for Application Insights SDK configuration. Treat as confidential."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Application Insights resource."
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "The name of the Application Insights resource."
  value       = azurerm_application_insights.this.name
}

output "workspace_id" {
  description = "The resource ID of the linked Log Analytics Workspace."
  value       = azurerm_application_insights.this.workspace_id
}

output "application_insights" {
  description = "Non-sensitive Application Insights metadata for downstream module composition."
  value = {
    id           = azurerm_application_insights.this.app_id
    resource_id  = azurerm_application_insights.this.id
    name         = azurerm_application_insights.this.name
    workspace_id = azurerm_application_insights.this.workspace_id
    location     = azurerm_application_insights.this.location
  }
}
