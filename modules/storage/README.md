# Azure Storage Account Module

Creates exactly **one** Azure Storage Account. No blob containers, file shares, queues, tables, lifecycle policies, or network rules are created.

## Purpose

- Provide a reusable, environment-agnostic storage foundation for the platform
- Support future blob containers, Terraform state backends, and application data stores
- Enforce secure defaults (HTTPS-only, no public blob access, TLS 1.2)
- Expose service endpoints for downstream module composition

## Architecture

```
environments/<env>/
    module "common"            ──▶ tags, names, location
    module "resource_group"    ──▶ resource group scope
    module "storage"           ──▶ azurerm_storage_account
            │
            ▼
    Future modules (separate implementations)
    ├── blob containers         (primary_blob_endpoint)
    ├── lifecycle policies      (account scope)
    ├── private endpoints       (network module)
    ├── diagnostic settings     (log analytics)
    └── role assignments        (managed identity)
```

This module creates **only** the Storage Account resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `storage_account_name` | Globally unique name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `account_tier` | `Standard` or `Premium` | `string` | `Standard` | no |
| `account_replication_type` | `LRS`, `GRS`, `RAGRS`, `ZRS`, `GZRS`, `RAGZRS` | `string` | `LRS` | no |
| `account_kind` | `StorageV2`, `BlobStorage`, etc. | `string` | `StorageV2` | no |
| `access_tier` | `Hot` or `Cool` | `string` | `Hot` | no |
| `min_tls_version` | `TLS1_0`, `TLS1_1`, `TLS1_2` | `string` | `TLS1_2` | no |
| `https_traffic_only_enabled` | Require HTTPS | `bool` | `true` | no |
| `allow_blob_public_access` | Allow anonymous blob access | `bool` | `false` | no |
| `shared_access_key_enabled` | Enable shared key auth | `bool` | `true` | no |
| `public_network_access_enabled` | Allow public internet access | `bool` | `true` | no |
| `infrastructure_encryption_enabled` | Double encryption at rest | `bool` | `false` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Low-Cost / Dev)

| Setting | Default | Reason |
|---------|---------|--------|
| `account_tier` | `Standard` | Lowest cost general-purpose tier |
| `account_replication_type` | `LRS` | Single-datacenter replication; cheapest option |
| `account_kind` | `StorageV2` | General-purpose with blob, file, queue, table |
| `access_tier` | `Hot` | Immediate access for active data |
| `min_tls_version` | `TLS1_2` | Modern TLS baseline |
| `allow_blob_public_access` | `false` | Prevent accidental public data exposure |
| `infrastructure_encryption_enabled` | `false` | Avoid double-encryption cost unless required |

### Naming Note

Storage account names must be **globally unique**, **3–24 lowercase alphanumeric characters** (no hyphens). Use the compact naming pattern from `modules/naming` (e.g. `cchdeveusstorage`) or supply via `terraform.tfvars`.

## Outputs

| Name | Description |
|------|-------------|
| `id` | Azure Resource Manager ID |
| `name` | Storage account name |
| `resource_id` | ARM resource ID (alias of `id`) |
| `primary_blob_endpoint` | Blob service URL |
| `primary_queue_endpoint` | Queue service URL |
| `primary_table_endpoint` | Table service URL |
| `primary_file_endpoint` | File service URL |
| `primary_dfs_endpoint` | Data Lake Gen2 URL (when applicable) |
| `storage_account` | Non-sensitive metadata object |

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

module "storage" {
  source = "../../modules/storage"

  storage_account_name = module.common.resource_names["storage"]
  resource_group_name  = module.resource_group.name
  location             = module.common.location
  tags                 = module.common.tags

  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
}
```

### Production Hardening

```hcl
module "storage" {
  source = "../../modules/storage"

  storage_account_name = var.storage_account_name
  resource_group_name  = module.resource_group.name
  location             = module.common.location
  tags                 = module.common.tags

  account_replication_type      = "GRS"
  allow_blob_public_access      = false
  shared_access_key_enabled     = false
  public_network_access_enabled = false
  min_tls_version               = "TLS1_2"
}
```

Private endpoints and network rules will be configured in future networking modules.

### Future Integration Points

```hcl
# Blob container (future module)
# storage_account_name = module.storage.name

# Role assignment (future module)
# scope        = module.storage.resource_id
# principal_id = module.managed_identity.principal_id
# role         = "Storage Blob Data Contributor"

# Terraform state backend (bootstrap)
# storage_account_name = module.storage.name
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed storage name |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **HTTPS only by default** — `https_traffic_only_enabled = true` rejects HTTP requests.
- **No public blob access by default** — `allow_blob_public_access = false` blocks anonymous container access.
- **TLS 1.2 minimum** — Rejects legacy TLS versions.
- **Shared keys** — Disable `shared_access_key_enabled` in production when using managed identity exclusively.
- **Public network** — Disable `public_network_access_enabled` when private endpoints are configured.
- **No RBAC in this module** — Role assignments are implemented separately.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| `LRS` vs `GRS` | GRS doubles storage cost for geo-redundancy |
| `Hot` vs `Cool` | Cool tier reduces storage cost; increases access cost |
| `Premium` tier | Significantly higher cost; for low-latency workloads only |
| Transactions | Read/write operations billed per transaction |

LRS + Standard + Hot is the lowest-cost combination for development workloads.

## Operational Guidance

- Storage account names are **globally unique** and **immutable** — choose before first deploy.
- Changing replication type may require account recreation in some scenarios.
- `primary_dfs_endpoint` is populated when hierarchical namespace (Data Lake Gen2) is enabled in a future module or extension.
- Use `azurerm_storage_account` import for migrating existing accounts.

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
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tier"></a> [access\_tier](#input\_access\_tier) | Default blob access tier for StorageV2 and BlobStorage accounts. | `string` | `"Hot"` | no |
| <a name="input_account_kind"></a> [account\_kind](#input\_account\_kind) | Storage account kind. StorageV2 is recommended for general-purpose blob, file, queue, and table storage. | `string` | `"StorageV2"` | no |
| <a name="input_account_replication_type"></a> [account\_replication\_type](#input\_account\_replication\_type) | Storage replication strategy. LRS is the lowest-cost option for non-production workloads. | `string` | `"LRS"` | no |
| <a name="input_account_tier"></a> [account\_tier](#input\_account\_tier) | Storage account tier. Standard for general-purpose workloads; Premium for high-performance scenarios. | `string` | `"Standard"` | no |
| <a name="input_allow_blob_public_access"></a> [allow\_blob\_public\_access](#input\_allow\_blob\_public\_access) | When true, allows nested blob containers to permit anonymous public access. | `bool` | `false` | no |
| <a name="input_https_traffic_only_enabled"></a> [https\_traffic\_only\_enabled](#input\_https\_traffic\_only\_enabled) | When true, requires secure transfer (HTTPS) for all requests. | `bool` | `true` | no |
| <a name="input_infrastructure_encryption_enabled"></a> [infrastructure\_encryption\_enabled](#input\_infrastructure\_encryption\_enabled) | When true, enables infrastructure encryption for data at rest (double encryption). | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Storage Account. | `string` | n/a | yes |
| <a name="input_min_tls_version"></a> [min\_tls\_version](#input\_min\_tls\_version) | Minimum TLS version for HTTPS requests to the storage account. | `string` | `"TLS1_2"` | no |
| <a name="input_network_rules"></a> [network\_rules](#input\_network\_rules) | Optional network rules restricting storage account access. Recommended when private endpoints are enabled. | <pre>object({<br/>    default_action             = optional(string, "Deny")<br/>    bypass                     = optional(list(string), ["AzureServices"])<br/>    ip_rules                   = optional(list(string), [])<br/>    virtual_network_subnet_ids = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | When true, allows access to the storage account over the public internet. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the Storage Account is created. | `string` | n/a | yes |
| <a name="input_shared_access_key_enabled"></a> [shared\_access\_key\_enabled](#input\_shared\_access\_key\_enabled) | When true, allows authenticated access via shared access keys. | `bool` | `true` | no |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Globally unique name of the Storage Account. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Storage Account. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The Azure Resource Manager ID of the Storage Account. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Storage Account. |
| <a name="output_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#output\_primary\_blob\_endpoint) | The primary blob service endpoint URL. |
| <a name="output_primary_dfs_endpoint"></a> [primary\_dfs\_endpoint](#output\_primary\_dfs\_endpoint) | The primary Azure Data Lake Storage Gen2 endpoint URL. Empty when hierarchical namespace is not enabled. |
| <a name="output_primary_file_endpoint"></a> [primary\_file\_endpoint](#output\_primary\_file\_endpoint) | The primary file service endpoint URL. |
| <a name="output_primary_queue_endpoint"></a> [primary\_queue\_endpoint](#output\_primary\_queue\_endpoint) | The primary queue service endpoint URL. |
| <a name="output_primary_table_endpoint"></a> [primary\_table\_endpoint](#output\_primary\_table\_endpoint) | The primary table service endpoint URL. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the Storage Account. |
| <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account) | Non-sensitive storage account metadata for downstream module composition. |
<!-- END_TF_DOCS -->
