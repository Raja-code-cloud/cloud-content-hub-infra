# ------------------------------------------------------------------------------
# Naming Module — Outputs
# ------------------------------------------------------------------------------

output "resource_prefix" {
  description = "Standard resource prefix in the form <project>-<environment> (e.g. cch-dev)."
  value       = local.resource_prefix
}

output "resource_prefix_short" {
  description = "Compact resource prefix without delimiters for globally unique names."
  value       = local.resource_prefix_short
}

output "location_short" {
  description = "Short region code derived from location or supplied explicitly."
  value       = local.location_short
}

output "environment_short" {
  description = "Abbreviated environment code (dev, stg, prd)."
  value       = local.environment_short
}

output "standard_labels" {
  description = "Standard label map for use in tags and metadata."
  value       = local.standard_labels
}

output "name" {
  description = "Generated name for single-name mode (resource_type input). Null when resource_type is not set."
  value       = var.resource_type == null ? null : local.names["default"]
}

output "names" {
  description = "Map of generated names keyed by logical name from the resources input or default for single-name mode."
  value       = local.names
}

output "resource_catalog" {
  description = "Supported resource type catalog with naming constraints."
  value = {
    for key, cfg in local.resource_catalog : key => {
      slug              = cfg.slug
      max_length        = cfg.max_length
      include_location  = cfg.include_location
      alphanumeric_only = cfg.alphanumeric_only
    }
  }
}

output "allowed_regions" {
  description = "Map of supported Azure regions to short codes."
  value       = local.allowed_regions
}
