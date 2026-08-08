# Azure Log Analytics Workspace Module

Creates exactly **one** Azure Log Analytics Workspace — the centralized logging platform for all future Azure resources.

## Purpose

- Provide a single, reusable Log Analytics Workspace per environment
- Serve as the ingestion endpoint for Container Apps, Azure Monitor, Application Insights, and diagnostic settings (configured by future modules)
- Enforce consistent tagging via the shared foundation
- Expose workspace metadata and sensitive keys for downstream integration

## Architecture

```
environments/<env>/
    module "common"         ──▶ tags, names, location
    module "resource_group" ──▶ resource group scope
    module "log_analytics"  ──▶ azurerm_log_analytics_workspace
            │
            ▼
    Future modules
    ├── application-insights  (workspace_id)
    ├── monitor               (workspace_id)
    ├── container-app         (diagnostic settings)
    └── alerts                (query workspace)
```

This module creates **only** the Log Analytics Workspace. It does not create Application Insights, alerts, diagnostic settings, or any other resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `resource_group_name` | Target resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `workspace_name` | Workspace name (from caller) | `string` | — | yes |
| `sku` | Workspace SKU | `string` | `PerGB2018` | no |
| `retention_in_days` | Data retention (days) | `number` | `30` | no |
| `daily_quota_gb` | Daily ingestion cap (GB); `-1` = unlimited | `number` | `1` | no |
| `internet_ingestion_enabled` | Allow public internet ingestion | `bool` | `true` | no |
| `internet_query_enabled` | Allow public internet queries | `bool` | `true` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Low-Cost / Dev-Friendly)

| Setting | Default | Reason |
|---------|---------|--------|
| `sku` | `PerGB2018` | Pay-as-you-go with no commitment |
| `retention_in_days` | `30` | Minimum paid-tier retention; balances cost and utility |
| `daily_quota_gb` | `1` | Ingestion cap to control cost in non-production workloads |
| `internet_ingestion_enabled` | `true` | Required for many out-of-box Azure integrations |
| `internet_query_enabled` | `true` | Enables portal and CLI queries without private link |

Override defaults per environment via `terraform.tfvars` — do not modify module defaults for production-specific values.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | Workspace ID (Customer ID GUID) |
| `name` | no | Workspace name |
| `workspace_resource_id` | no | Azure Resource Manager ID |
| `customer_id` | no | Customer ID for agents and diagnostic settings |
| `primary_shared_key` | **yes** | Primary ingestion/query key |
| `secondary_shared_key` | **yes** | Secondary ingestion/query key |
| `retention_in_days` | no | Configured retention |
| `sku` | no | Configured SKU |
| `workspace` | no | Non-sensitive metadata object for downstream modules |

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

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  workspace_name      = module.common.resource_names["log_analytics"]
  tags                = module.common.tags

  daily_quota_gb = var.environment == "prod" ? -1 : 1
  retention_in_days = var.environment == "prod" ? 90 : 30
}
```

### Production Overrides

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  workspace_name      = module.common.resource_names["log_analytics"]
  tags                = module.common.tags

  sku                        = "PerGB2018"
  retention_in_days          = 90
  daily_quota_gb             = -1
  internet_ingestion_enabled = false
  internet_query_enabled     = false
}
```

### Downstream Integration (Future Modules)

```hcl
# Application Insights (future module)
# workspace_id = module.log_analytics.customer_id

# Diagnostic settings (future module)
# log_analytics_workspace_id = module.log_analytics.workspace_resource_id
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed workspace name |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **Shared keys** — `primary_shared_key` and `secondary_shared_key` are marked `sensitive`. Store in Key Vault when used by applications; never commit to source control.
- **Internet access** — Set `internet_ingestion_enabled` and `internet_query_enabled` to `false` in production when private link is configured (future networking module).
- **Tags** — Always pass `module.common.tags` for ownership and audit traceability.
- **RBAC** — Assign Azure roles (e.g. Log Analytics Contributor) via separate identity modules; this module does not manage RBAC.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| SKU | `PerGB2018` charges per GB ingested; `Free` tier has daily cap and 7-day retention |
| Retention | Longer retention increases storage cost |
| `daily_quota_gb` | Caps daily ingestion; use `1` in dev/stage, `-1` in prod if uncapped ingestion is required |
| Data volume | Container Apps and diagnostic settings (future) will drive ingestion volume |

Monitor ingestion via Azure Cost Management and workspace usage metrics.

## Operational Notes

- Workspace creation is idempotent — re-applying updates configurable properties in place.
- Changing SKU or retention may have billing implications — review Azure pricing before modifying production.
- The Customer ID (`customer_id` output) is required by Azure Monitor agents and diagnostic setting resources.
- Shared keys can be regenerated in Azure Portal; Terraform will detect drift on next plan.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Resource Group Module](../resource-group/README.md)
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
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_daily_quota_gb"></a> [daily\_quota\_gb](#input\_daily\_quota\_gb) | Daily ingestion quota in GB. Use -1 for unlimited (Azure default). Set a positive value to cap ingestion cost. | `number` | `1` | no |
| <a name="input_internet_ingestion_enabled"></a> [internet\_ingestion\_enabled](#input\_internet\_ingestion\_enabled) | When true, allows ingestion of data from public internet sources. | `bool` | `true` | no |
| <a name="input_internet_query_enabled"></a> [internet\_query\_enabled](#input\_internet\_query\_enabled) | When true, allows querying workspace data over the public internet. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Log Analytics Workspace. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the Log Analytics Workspace is created. | `string` | n/a | yes |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | Data retention in days. Free SKU requires 7. Paid SKUs support 30-730. | `number` | `30` | no |
| <a name="input_sku"></a> [sku](#input\_sku) | Log Analytics Workspace SKU. PerGB2018 is recommended for pay-as-you-go workloads. | `string` | `"PerGB2018"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the workspace. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Name of the Log Analytics Workspace. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_customer_id"></a> [customer\_id](#output\_customer\_id) | The Customer ID (Workspace ID GUID) used by agents and diagnostic settings. |
| <a name="output_id"></a> [id](#output\_id) | The Azure Resource Manager ID of the Log Analytics Workspace. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Log Analytics Workspace. |
| <a name="output_primary_shared_key"></a> [primary\_shared\_key](#output\_primary\_shared\_key) | The primary shared key for Log Analytics agent and API authentication. Treat as confidential. |
| <a name="output_retention_in_days"></a> [retention\_in\_days](#output\_retention\_in\_days) | Configured data retention period in days. |
| <a name="output_secondary_shared_key"></a> [secondary\_shared\_key](#output\_secondary\_shared\_key) | The secondary shared key for Log Analytics agent and API authentication. Treat as confidential. |
| <a name="output_sku"></a> [sku](#output\_sku) | Configured Log Analytics Workspace SKU. |
| <a name="output_workspace"></a> [workspace](#output\_workspace) | Non-sensitive workspace metadata for downstream module composition. |
| <a name="output_workspace_resource_id"></a> [workspace\_resource\_id](#output\_workspace\_resource\_id) | The Azure Resource Manager ID of the Log Analytics Workspace. |
<!-- END_TF_DOCS -->
