output "resource_prefix" {
  description = "Standard resource prefix."
  value       = module.common.resource_prefix
}

output "tags" {
  description = "Merged global tags."
  value       = module.common.tags
}

output "resource_names" {
  description = "Pre-computed platform resource names."
  value       = module.common.resource_names
}

output "acr_name" {
  description = "Example ACR name from the common name set."
  value       = module.common.resource_names["acr"]
}

output "storage_name" {
  description = "Example storage account name (globally unique pattern)."
  value       = module.common.resource_names["storage"]
}

output "custom_subnet_name" {
  description = "Custom name generated via the naming module directly."
  value       = module.custom_name.name
}

output "metadata" {
  description = "Deployment metadata."
  value       = module.common.metadata
}
