# ------------------------------------------------------------------------------
# Azure Cache for Redis Module
#
# Creates exactly one Azure Cache for Redis instance.
# Does NOT create private endpoints, private DNS, diagnostics, or RBAC.
# See: modules/redis/README.md
# ------------------------------------------------------------------------------

resource "azurerm_redis_cache" "this" {
  name                          = var.redis_cache_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  minimum_tls_version           = var.minimum_tls_version
  non_ssl_port_enabled          = var.non_ssl_port_enabled
  public_network_access_enabled = var.public_network_access_enabled
  redis_version                 = var.redis_version
  tags                          = var.tags

  dynamic "redis_configuration" {
    for_each = var.redis_configuration != null ? [var.redis_configuration] : []

    content {
      maxmemory_policy   = try(redis_configuration.value.maxmemory_policy, null)
      maxmemory_reserved = try(redis_configuration.value.maxmemory_reserved, null)
      maxmemory_delta    = try(redis_configuration.value.maxmemory_delta, null)
    }
  }
}

check "premium_required_for_private_access" {
  assert {
    condition     = var.public_network_access_enabled || local.premium_sku
    error_message = "public_network_access_enabled=false requires Premium SKU for private endpoint connectivity."
  }
}

check "family_matches_sku" {
  assert {
    condition = (
      (var.sku_name == "Premium" && var.family == "P") ||
      (var.sku_name != "Premium" && var.family == "C")
    )
    error_message = "family must be P for Premium SKU and C for Basic/Standard SKU."
  }
}
