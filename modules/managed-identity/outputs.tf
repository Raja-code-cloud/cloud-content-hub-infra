# ------------------------------------------------------------------------------
# Managed Identity Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Client ID of the User Assigned Managed Identity (used by applications for authentication)."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "client_id" {
  description = "The Client ID of the User Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "The Object ID (Principal ID) of the User Assigned Managed Identity for RBAC assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the User Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "The name of the User Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "tenant_id" {
  description = "The Azure AD Tenant ID associated with the User Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}

output "identity" {
  description = "Non-sensitive identity metadata for downstream module composition."
  value = {
    client_id    = azurerm_user_assigned_identity.this.client_id
    principal_id = azurerm_user_assigned_identity.this.principal_id
    resource_id  = azurerm_user_assigned_identity.this.id
    name         = azurerm_user_assigned_identity.this.name
    tenant_id    = azurerm_user_assigned_identity.this.tenant_id
    location     = azurerm_user_assigned_identity.this.location
  }
}
