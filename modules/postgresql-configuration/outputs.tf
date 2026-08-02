# ------------------------------------------------------------------------------
# PostgreSQL Configuration Module — Outputs
# ------------------------------------------------------------------------------

output "configuration_ids" {
  description = "Map of configuration names to Azure Resource Manager IDs."
  value       = { for name, configuration in azurerm_postgresql_flexible_server_configuration.this : name => configuration.id }
}

output "configuration_names" {
  description = "Map of configuration names to PostgreSQL server parameter names."
  value       = { for name, configuration in azurerm_postgresql_flexible_server_configuration.this : name => configuration.name }
}

output "applied_values" {
  description = "Map of configuration names to applied PostgreSQL server parameter values."
  value       = { for name, configuration in azurerm_postgresql_flexible_server_configuration.this : name => configuration.value }
}

output "server_name" {
  description = "Name of the PostgreSQL Flexible Server hosting the configuration parameters."
  value       = var.server_name
}

output "configurations" {
  description = "Non-sensitive configuration metadata for downstream module composition."
  value = {
    for name, configuration in azurerm_postgresql_flexible_server_configuration.this :
    name => {
      id          = configuration.id
      name        = configuration.name
      value       = configuration.value
      source      = try(local.configurations[name].source, null)
      server_name = var.server_name
    }
  }
}
