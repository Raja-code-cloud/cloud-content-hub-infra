# ------------------------------------------------------------------------------
# Container Apps Environment Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Container Apps Environment."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "The name of the Container Apps Environment."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "The default domain suffix for container apps deployed in this environment."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip" {
  description = "The static IP address of the Container Apps Environment when VNet integration is configured. Null for consumption-only environments without infrastructure subnet."
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Container Apps Environment."
  value       = azurerm_container_app_environment.this.id
}

output "location" {
  description = "The Azure region of the Container Apps Environment."
  value       = azurerm_container_app_environment.this.location
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the linked Log Analytics Workspace."
  value       = azurerm_container_app_environment.this.log_analytics_workspace_id
}

output "container_app_environment" {
  description = "Non-sensitive Container Apps Environment metadata for downstream module composition."
  value = {
    id                         = azurerm_container_app_environment.this.id
    name                       = azurerm_container_app_environment.this.name
    default_domain             = azurerm_container_app_environment.this.default_domain
    static_ip                  = azurerm_container_app_environment.this.static_ip_address
    location                   = azurerm_container_app_environment.this.location
    log_analytics_workspace_id = azurerm_container_app_environment.this.log_analytics_workspace_id
    resource_group_name        = azurerm_container_app_environment.this.resource_group_name
  }
}
