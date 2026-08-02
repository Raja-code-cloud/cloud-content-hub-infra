# ------------------------------------------------------------------------------
# PostgreSQL Database Module — Outputs
# ------------------------------------------------------------------------------

locals {
  managed_databases = merge(
    azurerm_postgresql_flexible_server_database.protected,
    azurerm_postgresql_flexible_server_database.unprotected,
  )
}

output "database_ids" {
  description = "Map of database names to Azure Resource Manager IDs."
  value       = { for name, database in local.managed_databases : name => database.id }
}

output "database_names" {
  description = "Map of database names to PostgreSQL database names."
  value       = { for name, database in local.managed_databases : name => database.name }
}

output "server_name" {
  description = "Name of the PostgreSQL Flexible Server hosting the databases."
  value       = var.server_name
}

output "fully_qualified_database_identifiers" {
  description = "Map of database names to fully qualified Azure Resource Manager identifiers."
  value       = { for name, database in local.managed_databases : name => database.id }
}

output "databases" {
  description = "Non-sensitive database metadata for downstream module composition."
  value = {
    for name, database in local.managed_databases :
    name => {
      id                                  = database.id
      name                                = database.name
      charset                             = database.charset
      collation                           = database.collation
      server_name                         = var.server_name
      fully_qualified_database_identifier = database.id
      prevent_destroy                     = contains(keys(local.protected_databases), name)
      tags                                = var.tags
    }
  }
}
