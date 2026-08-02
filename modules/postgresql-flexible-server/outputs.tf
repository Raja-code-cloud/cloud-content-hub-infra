# ------------------------------------------------------------------------------
# PostgreSQL Flexible Server Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "The fully qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "postgresql_version" {
  description = "The PostgreSQL major version of the server."
  value       = azurerm_postgresql_flexible_server.this.version
}

output "sku_name" {
  description = "The SKU name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.this.sku_name
}

output "administrator_login" {
  description = "The administrator login username. Password is never exposed."
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "connection_endpoint" {
  description = "PostgreSQL connection endpoint in host:port format."
  value       = "${azurerm_postgresql_flexible_server.this.fqdn}:5432"
}

output "server" {
  description = "Non-sensitive server metadata for downstream module composition."
  value = {
    id                  = azurerm_postgresql_flexible_server.this.id
    name                = azurerm_postgresql_flexible_server.this.name
    fqdn                = azurerm_postgresql_flexible_server.this.fqdn
    connection_endpoint = "${azurerm_postgresql_flexible_server.this.fqdn}:5432"
    version             = azurerm_postgresql_flexible_server.this.version
    sku_name            = azurerm_postgresql_flexible_server.this.sku_name
    administrator_login = azurerm_postgresql_flexible_server.this.administrator_login
  }
}
