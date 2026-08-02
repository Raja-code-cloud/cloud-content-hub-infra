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

output "tags" {
  description = "Merged global tag set for resource modules."
  value       = module.common.tags
}

output "resource_names" {
  description = "Pre-computed standard platform resource names."
  value       = module.common.resource_names
}

output "metadata" {
  description = "Aggregate deployment metadata."
  value       = module.common.metadata
}
