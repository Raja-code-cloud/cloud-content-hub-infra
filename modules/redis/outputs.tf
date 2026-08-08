# ------------------------------------------------------------------------------
# Azure Cache for Redis Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Redis cache."
  value       = azurerm_redis_cache.this.id
}

output "name" {
  description = "The name of the Redis cache."
  value       = azurerm_redis_cache.this.name
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Redis cache."
  value       = azurerm_redis_cache.this.id
}

output "hostname" {
  description = "The hostname of the Redis cache endpoint."
  value       = azurerm_redis_cache.this.hostname
}

output "ssl_port" {
  description = "The TLS port of the Redis cache."
  value       = azurerm_redis_cache.this.ssl_port
}

output "port" {
  description = "The non-TLS port of the Redis cache (disabled when non_ssl_port_enabled is false)."
  value       = azurerm_redis_cache.this.port
}

output "primary_access_key" {
  description = "Primary access key for Redis authentication. Treat as confidential."
  value       = azurerm_redis_cache.this.primary_access_key
  sensitive   = true
}

output "redis_url" {
  description = "CCH_REDIS_URL-compatible connection string using TLS (rediss://)."
  value       = local.redis_url
  sensitive   = true
}

output "redis" {
  description = "Non-sensitive Redis metadata for downstream module composition."
  value = {
    id       = azurerm_redis_cache.this.id
    name     = azurerm_redis_cache.this.name
    hostname = azurerm_redis_cache.this.hostname
    ssl_port = azurerm_redis_cache.this.ssl_port
    sku_name = azurerm_redis_cache.this.sku_name
    location = azurerm_redis_cache.this.location
  }
}
