# ------------------------------------------------------------------------------
# Output Values — stage
# ------------------------------------------------------------------------------

output "environment" {
  description = "The deployed environment identifier."
  value       = module.common.environment
}

output "location" {
  description = "The primary Azure region for this deployment."
  value       = module.common.location
}

output "resource_prefix" {
  description = "Standard resource prefix for this deployment."
  value       = module.common.resource_prefix
}

output "resource_group_name" {
  description = "Platform resource group name."
  value       = module.resource_group.name
}

output "resource_group_lock_id" {
  description = "Management lock ID protecting the platform resource group."
  value       = module.resource_group.lock_id
}

output "container_app_url" {
  description = "HTTPS URL for the deployed Container App when ingress is available."
  value       = module.container_app.ingress_url
}

output "container_app_id" {
  description = "Azure Resource Manager ID of the Container App."
  value       = module.container_app.id
}

output "container_app_fqdn" {
  description = "FQDN of the latest Container App revision."
  value       = module.container_app.fqdn
}

output "container_app_environment_id" {
  description = "Container Apps Environment resource ID."
  value       = module.container_app_environment.id
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = module.acr.login_server
}

output "storage_account_name" {
  description = "Platform storage account name."
  value       = module.storage.name
}

output "key_vault_uri" {
  description = "Key Vault URI for data plane operations."
  value       = module.key_vault.vault_uri
}

output "postgresql_fqdn" {
  description = "PostgreSQL Flexible Server FQDN."
  value       = module.postgresql_flexible_server.fqdn
}

output "application_insights_connection_string" {
  description = "Application Insights connection string for application telemetry."
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "managed_identity_principal_id" {
  description = "Principal ID of the platform user-assigned managed identity."
  value       = module.managed_identity.principal_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace resource ID."
  value       = module.log_analytics.workspace_resource_id
}

output "private_networking_enabled" {
  description = "Whether private networking modules were deployed."
  value       = local.networking_enabled
}

output "private_endpoint_ids" {
  description = "Map of private endpoint keys to resource IDs when private endpoints are enabled."
  value       = local.private_endpoints_enabled ? module.private_endpoint[0].private_endpoint_ids : {}
}

output "managed_identity_resource_id" {
  description = "Azure Resource Manager ID of the platform user-assigned managed identity."
  value       = module.managed_identity.resource_id
}

output "virtual_network_id" {
  description = "Virtual network resource ID when private networking is enabled."
  value       = local.networking_enabled ? module.networking[0].vnet_id : null
}

output "subnet_ids" {
  description = "Map of subnet keys to resource IDs when private networking is enabled."
  value       = local.networking_enabled ? module.networking[0].subnet_ids : {}
}

output "resource_names" {
  description = "Pre-computed standard platform resource names."
  value       = module.common.resource_names
}

output "metadata" {
  description = "Aggregate deployment metadata."
  value       = module.common.metadata
}
