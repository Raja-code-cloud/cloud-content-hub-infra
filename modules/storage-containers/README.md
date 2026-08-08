# Azure Storage Blob Containers Module

Creates **blob containers in an existing Azure Storage Account**. Does not create storage accounts, lifecycle policies, network rules, or RBAC assignments.

## Purpose

- Provision blob containers for application content, exports, backups, and logs
- Support hundreds of containers via stable `for_each` keys
- Default to private access with no anonymous access
- Remain environment-agnostic with no hardcoded container names

This module creates **only** `azurerm_storage_container` resources.

## Architecture

```
environments/<env>/
    module "storage"             ──▶ storage_account_name, storage_account_id, primary_blob_endpoint
    module "storage_containers"  ──▶ azurerm_storage_container (for_each)
            │
            ▼
    application / CI pipelines   ──▶ container_urls, container_names
```

The Storage Account must exist before containers are created. Assign blob data roles via the `role-assignment` module separately.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `storage_account_name` | yes | Existing Storage Account name |
| `storage_account_id` | yes | Existing Storage Account resource ID (from the storage module) |
| `containers` | no | List of blob container definitions |
| `tags` | no | Tags merged into each container metadata map |
| `primary_blob_endpoint` | no | Blob endpoint from storage module for accurate container URLs |

### Container object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `key` | yes | — | Stable `for_each` identifier |
| `name` | yes | — | Blob container name (3–63 chars, lowercase) |
| `container_access_type` | no | `private` | `private`, `blob`, or `container` |
| `metadata` | no | `{}` | Container metadata key-value pairs |
| `immutability_policy` | no | — | Future-ready immutability configuration |
| `legal_hold` | no | — | Future-ready legal hold flag |

Blob containers do not support Azure Resource Manager tags. Module-level `tags` are merged into each container's `metadata` map (container metadata overrides module tags on key collision).

### Access types

| Value | Description |
|-------|-------------|
| `private` | No anonymous access (recommended default) |
| `blob` | Anonymous read access for blobs only |
| `container` | Anonymous read access for containers and blobs |

## Outputs

| Name | Description |
|------|-------------|
| `container_ids` | Map of keys to blob container resource IDs |
| `container_names` | Map of keys to container names |
| `container_urls` | Map of keys to blob container URLs |
| `containers` | Non-sensitive metadata map |

## Examples

### Content containers (posters, articles, videos, thumbnails)

```hcl
module "storage_containers" {
  source = "../../modules/storage-containers"

  storage_account_name  = module.storage.name
  storage_account_id    = module.storage.id
  primary_blob_endpoint = module.storage.primary_blob_endpoint
  tags                    = module.common.tags

  containers = [
    {
      key  = "posters"
      name = "posters"
      metadata = {
        purpose = "marketing-posters"
      }
    },
    {
      key  = "articles"
      name = "articles"
      metadata = {
        purpose = "published-articles"
      }
    },
    {
      key  = "videos"
      name = "videos"
      metadata = {
        purpose = "video-assets"
      }
    },
    {
      key  = "thumbnails"
      name = "thumbnails"
      metadata = {
        purpose = "video-thumbnails"
      }
    },
  ]
}
```

### Exports and backups

```hcl
module "storage_containers" {
  source = "../../modules/storage-containers"

  storage_account_name  = module.storage.name
  storage_account_id    = module.storage.id
  primary_blob_endpoint = module.storage.primary_blob_endpoint
  tags                  = module.common.tags

  containers = [
    {
      key                   = "exports"
      name                  = "exports"
      container_access_type = "private"
      metadata = {
        purpose     = "data-exports"
        retention   = "90-days"
      }
    },
    {
      key                   = "backups"
      name                  = "backups"
      container_access_type = "private"
      metadata = {
        purpose     = "database-backups"
        retention   = "365-days"
      }
    },
  ]
}
```

### Logs

```hcl
module "storage_containers" {
  source = "../../modules/storage-containers"

  storage_account_name  = module.storage.name
  storage_account_id    = module.storage.id
  primary_blob_endpoint = module.storage.primary_blob_endpoint
  tags                  = module.common.tags

  containers = [
    {
      key  = "logs"
      name = "logs"
      metadata = {
        purpose = "application-logs"
      }
    },
  ]
}
```

### Future-ready immutability (validated, not yet applied)

```hcl
module "storage_containers" {
  source = "../../modules/storage-containers"

  storage_account_name  = module.storage.name
  storage_account_id    = module.storage.id
  primary_blob_endpoint = module.storage.primary_blob_endpoint
  tags                  = module.common.tags

  containers = [
    {
      key  = "compliance-archive"
      name = "compliance-archive"
      immutability_policy = {
        immutability_period_in_days = 2555
        state                       = "Unlocked"
      }
      legal_hold = true
    },
  ]
}
```

Immutability and legal hold fields are validated at plan time. Resource support will be added in a future module version.

## Naming Guidance

| Rule | Detail |
|------|--------|
| Length | 3–63 characters |
| Characters | Lowercase letters, numbers, and hyphens only |
| Start/end | Must start and end with a letter or number |
| Hyphens | No consecutive hyphens (`--`) |
| Uniqueness | Names must be unique within the Storage Account |
| Stable keys | Use `key` values that do not change when display names change |

Recommended naming patterns:

- `{workload}-{purpose}` — e.g. `cch-posters`, `cch-exports`
- `{environment}-{purpose}` — e.g. `dev-logs`, `prod-backups`

## Operational Guidance

1. **Create the Storage Account first** — Use the `storage` module before this module.
2. **Pass the blob endpoint** — Supply `primary_blob_endpoint` from the storage module for accurate URLs in sovereign and custom endpoint scenarios.
3. **Use private access by default** — Only set `blob` or `container` when anonymous read is explicitly required.
4. **Manage lifecycle separately** — Blob lifecycle management policies belong at the storage account level, not in this module.
5. **Assign RBAC separately** — Grant `Storage Blob Data Contributor` via the `role-assignment` module to workloads that write blobs.

## Security Best Practices

| Practice | Rationale |
|----------|-----------|
| Default to `private` | Prevents anonymous blob access |
| Keep `allow_blob_public_access = false` on the storage account | Storage account must permit public access before container-level public settings take effect |
| Use metadata for classification | Track data sensitivity and retention in container metadata |
| Prefer Azure AD / RBAC over shared keys | Assign blob data roles to managed identities |
| Plan immutability for compliance workloads | Use future immutability support for WORM retention requirements |

## Cost Considerations

Blob containers themselves have no direct cost. Storage charges apply based on:

- Data stored (Hot, Cool, Archive tiers)
- Read/write operations
- Data transfer and geo-replication

Use separate containers for workloads with different retention or tier requirements to simplify lifecycle management at the account level.

## Related

- [Storage Account Module](../storage/README.md)
- [Role Assignment Module](../role-assignment/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)

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
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_containers"></a> [containers](#input\_containers) | List of blob containers to create in the existing Storage Account. Each entry requires a stable key for for\_each identity at scale. | <pre>list(object({<br/>    key                   = string<br/>    name                  = string<br/>    container_access_type = optional(string, "private")<br/>    metadata              = optional(map(string), {})<br/>    immutability_policy = optional(object({<br/>      immutability_period_in_days   = number<br/>      state                         = string<br/>      allow_protected_append_writes = optional(bool, false)<br/>    }))<br/>    legal_hold = optional(bool)<br/>  }))</pre> | `[]` | no |
| <a name="input_primary_blob_endpoint"></a> [primary\_blob\_endpoint](#input\_primary\_blob\_endpoint) | Primary blob endpoint from the storage account module. When omitted, container URLs use the public Azure cloud naming convention. | `string` | `null` | no |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Resource ID of the existing Storage Account. Required by azurerm v5 for container binding. | `string` | n/a | yes |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Name of the existing Storage Account. This module does not create the Storage Account. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags merged into each container metadata map. Blob containers do not support Azure Resource Manager tags directly. | `map(string)` | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_ids"></a> [container\_ids](#output\_container\_ids) | Map of container keys to Azure blob container resource IDs. |
| <a name="output_container_names"></a> [container\_names](#output\_container\_names) | Map of container keys to blob container names. |
| <a name="output_container_urls"></a> [container\_urls](#output\_container\_urls) | Map of container keys to blob container URLs. |
| <a name="output_containers"></a> [containers](#output\_containers) | Non-sensitive container metadata for downstream module composition. |
<!-- END_TF_DOCS -->