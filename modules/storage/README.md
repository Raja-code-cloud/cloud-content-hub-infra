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
<!-- END_TF_DOCS -->
