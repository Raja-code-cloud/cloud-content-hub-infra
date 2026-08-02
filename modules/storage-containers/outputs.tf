# ------------------------------------------------------------------------------
# Storage Containers Module — Outputs
# ------------------------------------------------------------------------------

output "container_ids" {
  description = "Map of container keys to Azure blob container resource IDs."
  value       = { for key, container in azurerm_storage_container.this : key => container.id }
}

output "container_names" {
  description = "Map of container keys to blob container names."
  value       = { for key, container in azurerm_storage_container.this : key => container.name }
}

output "container_urls" {
  description = "Map of container keys to blob container URLs."
  value       = local.container_urls
}

output "containers" {
  description = "Non-sensitive container metadata for downstream module composition."
  value = {
    for key, container in azurerm_storage_container.this :
    key => {
      id                      = container.id
      name                    = container.name
      url                     = local.container_urls[key]
      storage_account_name    = var.storage_account_name
      container_access_type   = container.container_access_type
      metadata                = container.metadata
      has_immutability_policy = container.has_immutability_policy
      has_legal_hold          = container.has_legal_hold
    }
  }
}
