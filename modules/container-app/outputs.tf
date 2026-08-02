# ------------------------------------------------------------------------------
# Container App Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Container App."
  value       = azurerm_container_app.this.id
}

output "name" {
  description = "The name of the Container App."
  value       = azurerm_container_app.this.name
}

output "fqdn" {
  description = "The FQDN of the latest revision when ingress is enabled. Null for internal workers without ingress."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "latest_revision" {
  description = "The FQDN of the latest revision of the Container App."
  value       = azurerm_container_app.this.latest_revision_fqdn
}

output "latest_revision_name" {
  description = "The name of the latest Container App revision."
  value       = azurerm_container_app.this.latest_revision_name
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity. Null when system-assigned identity is not enabled."
  value       = try(azurerm_container_app.this.identity[0].principal_id, null)
}

output "identity_id" {
  description = "The resource ID of the first user-assigned managed identity attached to the Container App. Null when only system-assigned identity is used or no identity is configured."
  value       = try(one(azurerm_container_app.this.identity[0].identity_ids), null)
}

output "identity_ids" {
  description = "Resource IDs of user-assigned managed identities attached to the Container App."
  value       = try(tolist(azurerm_container_app.this.identity[0].identity_ids), [])
}

output "ingress_url" {
  description = "HTTPS URL for the Container App ingress when a FQDN is available."
  value = (
    azurerm_container_app.this.latest_revision_fqdn != null
    ? "https://${azurerm_container_app.this.latest_revision_fqdn}"
    : null
  )
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Container App."
  value       = azurerm_container_app.this.id
}

output "environment_id" {
  description = "The Container Apps Environment resource ID hosting this app."
  value       = var.container_app_environment_id
}

output "location" {
  description = "The Azure region where the Container App is deployed."
  value       = azurerm_container_app.this.location
}

output "outbound_ip_addresses" {
  description = "Public IP addresses used for outbound network access from the Container App."
  value       = azurerm_container_app.this.outbound_ip_addresses
}

output "container_app" {
  description = "Non-sensitive Container App metadata for downstream module composition. Never includes secret values."
  value = {
    id                    = azurerm_container_app.this.id
    name                  = azurerm_container_app.this.name
    resource_id           = azurerm_container_app.this.id
    environment_id        = var.container_app_environment_id
    location              = azurerm_container_app.this.location
    latest_revision_fqdn  = azurerm_container_app.this.latest_revision_fqdn
    latest_revision_name  = azurerm_container_app.this.latest_revision_name
    revision_mode         = var.revision_mode
    outbound_ip_addresses = azurerm_container_app.this.outbound_ip_addresses
  }
}
