# Azure PostgreSQL Flexible Server Module

Creates exactly **one** Azure Database for PostgreSQL Flexible Server. No databases, firewall rules, configuration parameters, private endpoints, or RBAC assignments are created.

## Purpose

- Provide a reusable, environment-agnostic PostgreSQL server for the platform
- Support future database, firewall, and VNet integration modules
- Accept credentials from external secret sources — never hardcode passwords
- Expose connection metadata for application and Container Apps modules

## Architecture

```
environments/<env>/
    module "common"                      ──▶ tags, names, location
    module "resource_group"              ──▶ resource group scope
    module "postgresql_flexible_server"  ──▶ azurerm_postgresql_flexible_server
            │
            ▼
    Future modules (separate implementations)
    ├── postgresql-database           (server_id)
    ├── postgresql-firewall-rule      (server_id)
    ├── postgresql-configuration      (server_id)
    ├── private endpoint              (network module)
    ├── diagnostic settings           (log analytics)
    └── key vault secret              (connection string)
```

This module creates **only** the PostgreSQL Flexible Server resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `server_name` | Server name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `administrator_login` | Admin username | `string` | — | yes |
| `administrator_password` | Admin password (sensitive) | `string` | — | yes |
| `sku_name` | Server SKU | `string` | `B_Standard_B1ms` | no |
| `storage_mb` | Storage in MB (min 32768) | `number` | `32768` | no |
| `postgresql_version` | PostgreSQL major version | `string` | `16` | no |
| `backup_retention_days` | Backup retention (7–35) | `number` | `7` | no |
| `geo_redundant_backup_enabled` | Geo-redundant backups | `bool` | `false` | no |
| `zone` | Availability zone (1, 2, 3) | `string` | `null` | no |
| `high_availability_mode` | `Disabled`, `SameZone`, `ZoneRedundant` | `string` | `Disabled` | no |
| `public_network_access_enabled` | Public network access | `bool` | `true` | no |
| `delegated_subnet_id` | VNet integration subnet | `string` | `null` | no |
| `private_dns_zone_id` | Private DNS zone for VNet | `string` | `null` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Single-User / Dev)

| Setting | Default | Reason |
|---------|---------|--------|
| `sku_name` | `B_Standard_B1ms` | Burstable tier; lowest cost for dev |
| `storage_mb` | `32768` | Minimum supported storage (32 GB) |
| `version` | `16` | Latest supported stable major version |
| `backup_retention_days` | `7` | Minimum retention; lowest backup storage cost |
| `geo_redundant_backup_enabled` | `false` | Avoid geo-redundancy cost in non-prod |
| `high_availability_mode` | `Disabled` | No HA overhead for dev workloads |
| `public_network_access_enabled` | `true` | Simplifies dev access before private endpoints |

### Password Handling

Supply `administrator_password` via:

- `terraform.tfvars` (gitignored)
- GitHub Actions secrets (`TF_VAR_administrator_password`)
- Key Vault reference (future module)

**Never** commit passwords to source control.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | ARM resource ID |
| `name` | no | Server name |
| `fqdn` | no | Fully qualified domain name |
| `resource_id` | no | ARM resource ID (alias) |
| `postgresql_version` | no | PostgreSQL major version |
| `sku_name` | no | Configured SKU |
| `administrator_login` | no | Admin username |
| `connection_endpoint` | no | `host:5432` connection string host |
| `server` | no | Non-sensitive metadata object |

Passwords are **never** exposed in outputs.

## Example Usage

### Environment Root Module

```hcl
module "common" {
  source = "../../modules/common"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  owner            = var.owner
  business_unit    = var.business_unit
  cost_center      = var.cost_center
  tags             = var.tags
  additional_tags  = var.additional_tags
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = module.common.resource_names["resource_group"]
  location = module.common.location
  tags     = module.common.tags
}

module "postgresql_flexible_server" {
  source = "../../modules/postgresql-flexible-server"

  server_name           = module.common.resource_names["postgres"]
  resource_group_name   = module.resource_group.name
  location              = module.common.location
  administrator_login   = var.postgresql_administrator_login
  administrator_password = var.postgresql_administrator_password
  tags                  = module.common.tags

  sku_name  = var.environment == "prod" ? "GP_Standard_D2s_v3" : "B_Standard_B1ms"
  postgresql_version = "16"
  storage_mb = var.environment == "prod" ? 131072 : 32768
}
```

Define credentials in `terraform.tfvars` (gitignored):

```hcl
postgresql_administrator_login    = "pgadmin"
postgresql_administrator_password = "<from-secret-store>"
```

### VNet Integration (Future Networking Module)

```hcl
module "postgresql_flexible_server" {
  source = "../../modules/postgresql-flexible-server"

  server_name            = module.common.resource_names["postgres"]
  resource_group_name    = module.resource_group.name
  location               = module.common.location
  administrator_login    = var.postgresql_administrator_login
  administrator_password = var.postgresql_administrator_password
  tags                   = module.common.tags

  delegated_subnet_id           = module.networking.postgresql_subnet_id
  private_dns_zone_id           = module.networking.postgresql_private_dns_zone_id
  public_network_access_enabled = false
}
```

### Future Extension Points

```hcl
# Database (future module)
# server_id = module.postgresql_flexible_server.id

# Firewall rule (future module)
# server_id = module.postgresql_flexible_server.id

# Key Vault secret (future module)
# value = "postgresql://${module.postgresql_flexible_server.administrator_login}@${module.postgresql_flexible_server.fqdn}:5432/postgres"
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed server name |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **Passwords** — Marked `sensitive`; never output; supply via secrets management.
- **Public access** — Disabled when using VNet integration (`delegated_subnet_id`).
- **No firewall rules** — Server is accessible per Azure defaults until firewall module is applied.
- **No RBAC** — Database-level permissions managed separately.
- **Admin login** — Reserved names blocked by validation.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| SKU tier | Burstable (B_) lowest cost; GP_/MO_ for production |
| `storage_mb` | Billed per GB provisioned; minimum 32 GB |
| `backup_retention_days` | Longer retention increases backup storage cost |
| `geo_redundant_backup_enabled` | Adds backup redundancy cost |
| `high_availability_mode` | SameZone/ZoneRedundant doubles compute cost |

`B_Standard_B1ms` + 32 GB + 7-day retention is the lowest-cost viable configuration.

## Operational Notes

- Server names are **immutable** — choose via `modules/naming` before first deploy.
- **SKU changes** may require downtime; review Azure docs before modifying production.
- **Version upgrades** are supported in place for major versions (with compatibility testing).
- **HA mode** requires General Purpose or Memory Optimized SKU — enforced by `check` block.
- Store connection details in Key Vault after deployment (future module).

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Resource Group Module](../resource-group/README.md)
- [Key Vault Module](../key-vault/README.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

No requirements.

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.0.1 |

## Modules

## Modules

No modules.

## Resources

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | Administrator login username for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_administrator_password"></a> [administrator\_password](#input\_administrator\_password) | Administrator password. Supply via tfvars, Key Vault, or CI secrets — never hardcode in source. | `string` | n/a | yes |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Backup retention period in days. | `number` | `7` | no |
| <a name="input_delegated_subnet_id"></a> [delegated\_subnet\_id](#input\_delegated\_subnet\_id) | Optional subnet ID for VNet-integrated deployment. Requires private\_dns\_zone\_id when set. | `string` | `null` | no |
| <a name="input_geo_redundant_backup_enabled"></a> [geo\_redundant\_backup\_enabled](#input\_geo\_redundant\_backup\_enabled) | When true, enables geo-redundant backup storage. | `bool` | `false` | no |
| <a name="input_high_availability_mode"></a> [high\_availability\_mode](#input\_high\_availability\_mode) | High availability mode. Disabled, SameZone, or ZoneRedundant. | `string` | `"Disabled"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the PostgreSQL Flexible Server. | `string` | n/a | yes |
| <a name="input_postgresql_version"></a> [postgresql\_version](#input\_postgresql\_version) | PostgreSQL major version. | `string` | `"16"` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | Optional private DNS zone ID for VNet-integrated deployment. | `string` | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | When true, allows public network access to the server. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the PostgreSQL Flexible Server is created. | `string` | n/a | yes |
| <a name="input_server_name"></a> [server\_name](#input\_server\_name) | Name of the PostgreSQL Flexible Server. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for the PostgreSQL Flexible Server (e.g. B\_Standard\_B1ms, GP\_Standard\_D2s\_v3). | `string` | `"B_Standard_B1ms"` | no |
| <a name="input_storage_mb"></a> [storage\_mb](#input\_storage\_mb) | Storage size in megabytes. Minimum 32768 (32 GB). | `number` | `32768` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the PostgreSQL Flexible Server. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Availability zone for the server (1, 2, or 3). Null for no zone preference. | `string` | `null` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_administrator_login"></a> [administrator\_login](#output\_administrator\_login) | The administrator login username. Password is never exposed. |
| <a name="output_connection_endpoint"></a> [connection\_endpoint](#output\_connection\_endpoint) | PostgreSQL connection endpoint in host:port format. |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | The fully qualified domain name of the PostgreSQL Flexible Server. |
| <a name="output_id"></a> [id](#output\_id) | The Azure Resource Manager ID of the PostgreSQL Flexible Server. |
| <a name="output_name"></a> [name](#output\_name) | The name of the PostgreSQL Flexible Server. |
| <a name="output_postgresql_version"></a> [postgresql\_version](#output\_postgresql\_version) | The PostgreSQL major version of the server. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the PostgreSQL Flexible Server. |
| <a name="output_server"></a> [server](#output\_server) | Non-sensitive server metadata for downstream module composition. |
| <a name="output_sku_name"></a> [sku\_name](#output\_sku\_name) | The SKU name of the PostgreSQL Flexible Server. |
<!-- END_TF_DOCS -->
