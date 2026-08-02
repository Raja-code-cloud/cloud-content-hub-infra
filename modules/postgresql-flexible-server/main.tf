# ------------------------------------------------------------------------------
# PostgreSQL Flexible Server Module
#
# Creates exactly one Azure Database for PostgreSQL Flexible Server.
# Does NOT create databases, firewall rules, configuration, or private endpoints.
# See: modules/postgresql-flexible-server/README.md
# ------------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  version                       = var.postgresql_version
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  zone                          = var.zone
  public_network_access_enabled = var.public_network_access_enabled
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  tags                          = var.tags

  dynamic "high_availability" {
    for_each = local.high_availability_enabled ? [var.high_availability_mode] : []

    content {
      mode = high_availability.value
    }
  }
}

check "vnet_requires_private_dns" {
  assert {
    condition     = !local.vnet_integrated || var.private_dns_zone_id != null
    error_message = "private_dns_zone_id is required when delegated_subnet_id is set."
  }
}

check "vnet_disables_public_access" {
  assert {
    condition     = !local.vnet_integrated || !var.public_network_access_enabled
    error_message = "public_network_access_enabled must be false when delegated_subnet_id is set."
  }
}

check "ha_requires_non_burstable_sku" {
  assert {
    condition     = !local.high_availability_enabled || startswith(var.sku_name, "GP_") || startswith(var.sku_name, "MO_")
    error_message = "high_availability_mode requires a General Purpose (GP_) or Memory Optimized (MO_) SKU."
  }
}
