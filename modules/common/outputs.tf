# ------------------------------------------------------------------------------
# Common Module — Outputs
#
# Exposes reusable metadata only. Never expose secrets.
# ------------------------------------------------------------------------------

output "project_name" {
  description = "Configured project name."
  value       = var.project_name
}

output "application_name" {
  description = "Configured application name."
  value       = var.application_name
}

output "environment" {
  description = "Configured deployment environment."
  value       = var.environment
}

output "location" {
  description = "Configured Azure region."
  value       = var.location
}

output "location_short" {
  description = "Short region code for naming."
  value       = module.naming.location_short
}

output "environment_short" {
  description = "Abbreviated environment code."
  value       = local.environment_short
}

output "resource_prefix" {
  description = "Standard resource prefix (<project>-<environment>)."
  value       = local.computed_resource_prefix
}

output "resource_prefix_short" {
  description = "Compact resource prefix for globally unique names."
  value       = module.naming.resource_prefix_short
}

output "tags" {
  description = "Merged global tag set for resource assignment."
  value       = local.merged_tags
}

output "base_tags" {
  description = "Base organizational tags before additional merges."
  value       = local.base_tags
}

output "standard_labels" {
  description = "Standard label map combining naming and organizational metadata."
  value       = local.standard_labels
}

output "resource_names" {
  description = "Pre-computed standard platform resource names."
  value       = module.naming.names
}

output "naming" {
  description = "Naming module outputs for advanced composition."
  value = {
    resource_prefix       = module.naming.resource_prefix
    resource_prefix_short = module.naming.resource_prefix_short
    location_short        = module.naming.location_short
    environment_short     = module.naming.environment_short
    resource_catalog      = module.naming.resource_catalog
    allowed_regions       = module.naming.allowed_regions
  }
}

output "metadata" {
  description = "Aggregate metadata for logging, diagnostics, and module composition."
  value = {
    project_name     = var.project_name
    application_name = var.application_name
    environment      = var.environment
    location         = var.location
    resource_prefix  = local.computed_resource_prefix
    repository_name  = var.repository_name
    managed_by       = var.managed_by
  }
}
