# ------------------------------------------------------------------------------
# Azure Cache for Redis Module — Locals
# ------------------------------------------------------------------------------

locals {
  premium_sku = var.sku_name == "Premium"

  redis_url = format(
    "rediss://:%s@%s:%d/0",
    urlencode(azurerm_redis_cache.this.primary_access_key),
    azurerm_redis_cache.this.hostname,
    azurerm_redis_cache.this.ssl_port,
  )
}
