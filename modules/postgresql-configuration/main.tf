# ------------------------------------------------------------------------------
# PostgreSQL Configuration Module
#
# Manages PostgreSQL server configuration parameters on an existing Azure
# Database for PostgreSQL Flexible Server. Does NOT create servers, databases,
# firewall rules, administrators, or private endpoints.
# See: modules/postgresql-configuration/README.md
# ------------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = local.configurations

  name      = each.value.name
  server_id = var.server_id
  value     = each.value.value
}

check "server_name_matches_server_id" {
  assert {
    condition     = endswith(var.server_id, "/flexibleServers/${var.server_name}")
    error_message = "server_name must match the flexible server name in server_id."
  }
}

check "restricted_configurations_require_opt_in" {
  assert {
    condition = var.allow_restricted_configurations || !anytrue([
      for configuration in var.configurations :
      try(configuration.enabled, true) &&
      contains(local.restricted_configuration_names, configuration.name)
    ])
    error_message = "Authentication and transport security parameters are restricted. Set allow_restricted_configurations = true to manage them explicitly."
  }
}
