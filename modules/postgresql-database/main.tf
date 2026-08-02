# ------------------------------------------------------------------------------
# PostgreSQL Database Module
#
# Creates logical databases on an existing Azure Database for PostgreSQL
# Flexible Server. Does NOT create the server, users, firewall rules,
# configuration, schemas, extensions, or RBAC assignments.
# See: modules/postgresql-database/README.md
# ------------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_database" "protected" {
  for_each = local.protected_databases

  name      = each.value.name
  server_id = var.server_id
  charset   = each.value.charset
  collation = each.value.collation

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "unprotected" {
  for_each = local.unprotected_databases

  name      = each.value.name
  server_id = var.server_id
  charset   = each.value.charset
  collation = each.value.collation

  lifecycle {
    prevent_destroy = false
  }
}

check "server_name_matches_server_id" {
  assert {
    condition     = endswith(var.server_id, "/flexibleServers/${var.server_name}")
    error_message = "server_name must match the flexible server name in server_id."
  }
}

check "database_names_not_reserved" {
  assert {
    condition = alltrue([
      for database in var.databases :
      !contains(local.reserved_database_names, database.name)
    ])
    error_message = "Database names cannot be reserved PostgreSQL or Azure system names (azure_maintenance, azure_sys, postgres, template0, template1)."
  }
}

check "database_charsets_supported" {
  assert {
    condition = alltrue([
      for database in var.databases :
      contains(local.supported_charsets, database.charset)
    ])
    error_message = "Each database charset must be a supported PostgreSQL charset. UTF8 is recommended."
  }
}
