# Azure Cache for Redis Module

Creates exactly one Azure Cache for Redis instance used by Cloud Content Hub AI for Celery broker/result backend and readiness checks (`CCH_REDIS_URL`).

## Usage

```hcl
module "redis" {
  source = "../../modules/redis"

  redis_cache_name    = module.common.resource_names["redis"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku_name = "Basic"
  family   = "C"
  capacity = 0
}
```

## Notes

- TLS-only access is the default (`non_ssl_port_enabled = false`).
- `redis_url` output is formatted for `CCH_REDIS_URL` (`rediss://:...@host:6380/0`).
- Private endpoint connectivity requires Premium SKU and `public_network_access_enabled = false`.
- This module does **not** create private endpoints, DNS zones, diagnostics, or RBAC.

## Inputs / Outputs

See `variables.tf` and `outputs.tf`.
