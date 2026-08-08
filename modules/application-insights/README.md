# Azure Application Insights Module

Creates exactly **one** workspace-based Azure Application Insights resource linked to an existing Log Analytics Workspace.

## Purpose

- Provide a reusable, environment-agnostic Application Insights instance for application telemetry
- Link telemetry to a centralized Log Analytics Workspace for unified querying and retention
- Enforce consistent tagging via the shared foundation
- Expose instrumentation credentials for downstream application and Container Apps modules

This module does **not** create diagnostic settings, alerts, smart detection rules, availability tests, workbooks, or dashboards — those are implemented in separate modules.

## Architecture

```
environments/<env>/
    module "common"              ──▶ tags, names, location
    module "resource_group"      ──▶ resource group scope
    module "log_analytics"       ──▶ existing workspace (dependency)
    module "application_insights" ──▶ azurerm_application_insights (workspace-linked)
            │
            ▼
    Future modules (separate implementations)
    ├── container-app           (connection_string / instrumentation_key)
    ├── diagnostic settings   (log analytics)
    ├── alerts                  (query-based rules)
    ├── availability tests      (synthetic monitoring)
    └── key vault secret        (store connection string)
```

This module creates **only** the Application Insights resource. It does not create the Log Analytics Workspace.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `application_insights_name` | Application Insights name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group | `string` | — | yes |
| `location` | Azure region (match workspace region) | `string` | — | yes |
| `workspace_id` | Log Analytics Workspace resource ID | `string` | — | yes |
| `application_type` | Application type (`web`, `java`, etc.) | `string` | `web` | no |
| `sampling_percentage` | Telemetry sampling percentage (0–100) | `number` | `50` | no |
| `disable_ip_masking` | Disable IP masking in telemetry | `bool` | `false` | no |
| `internet_ingestion_enabled` | Allow public internet ingestion | `bool` | `true` | no |
| `internet_query_enabled` | Allow public internet queries | `bool` | `true` | no |
| `local_authentication_disabled` | Disable local auth in favour of Azure AD | `bool` | `true` | no |
| `force_customer_storage_for_profiler` | Use customer-managed storage for profiler | `bool` | `false` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Single-User / Low-Cost / Enterprise Security)

| Setting | Default | Reason |
|---------|---------|--------|
| `application_type` | `web` | Most common workload type for web APIs and container apps |
| `sampling_percentage` | `50` | Reduces ingestion volume and cost while retaining representative telemetry |
| `disable_ip_masking` | `false` | Keeps IP masking enabled for privacy compliance |
| `internet_ingestion_enabled` | `true` | Required for SDK telemetry without private link (dev/single-user) |
| `internet_query_enabled` | `true` | Enables portal and CLI queries without private link |
| `local_authentication_disabled` | `true` | Disables instrumentation-key-only auth; prefer Azure AD / managed identity |
| `force_customer_storage_for_profiler` | `false` | Avoids additional storage account cost unless profiler compliance requires it |

Override defaults per environment via module arguments — do not modify module defaults for production-specific values.

### azurerm v5 Attribute Mapping

User-facing variables preserve enterprise naming conventions. The module maps to current provider attributes internally:

| Input Variable | Provider Attribute | Mapping |
|----------------|-------------------|---------|
| `disable_ip_masking` | `ip_masking_enabled` | `!disable_ip_masking` |
| `local_authentication_disabled` | `local_authentication_enabled` | `!local_authentication_disabled` |

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | Application Insights application ID (GUID) |
| `instrumentation_key` | **yes** | Instrumentation key for SDK configuration |
| `connection_string` | **yes** | Connection string for SDK configuration |
| `resource_id` | no | Azure Resource Manager ID |
| `name` | no | Application Insights resource name |
| `workspace_id` | no | Linked Log Analytics Workspace resource ID |
| `application_insights` | no | Non-sensitive metadata object for downstream modules |

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

  standard_resource_names = merge(
    var.standard_resource_names,
    {
      log_analytics = { resource_type = "log_analytics" }
      app_insights  = { resource_type = "app_insights" }
    }
  )
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
}

module "application_insights" {
  source = "../../modules/application-insights"

  application_insights_name = module.common.resource_names["app_insights"]
  resource_group_name       = module.resource_group.name
  location                  = module.common.location
  workspace_id              = module.log_analytics.workspace_resource_id
  tags                      = module.common.tags

  sampling_percentage = var.environment == "prod" ? 100 : 50
}
```

### Production Overrides

```hcl
module "application_insights" {
  source = "../../modules/application-insights"

  application_insights_name = module.common.resource_names["app_insights"]
  resource_group_name       = module.resource_group.name
  location                  = module.common.location
  workspace_id              = module.log_analytics.workspace_resource_id
  tags                      = module.common.tags

  sampling_percentage               = 100
  internet_ingestion_enabled        = false
  internet_query_enabled            = false
  local_authentication_disabled     = true
  force_customer_storage_for_profiler = var.enable_profiler_customer_storage
}
```

### Downstream Integration (Future Modules)

```hcl
# Container App environment variable (future module)
# APPLICATIONINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string

# Key Vault secret (future module)
# secret_value = module.application_insights.connection_string
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed Application Insights name |
| `modules/resource-group` | Resource group scope |
| `modules/log-analytics` | Existing workspace (`workspace_id` input) |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **Workspace-based mode** — Telemetry is stored in the linked Log Analytics Workspace, enabling centralized retention and RBAC.
- **Local authentication** — Default `local_authentication_disabled = true` disables instrumentation-key-only access. Applications should use Azure AD, managed identity, or connection strings stored in Key Vault.
- **Sensitive outputs** — `instrumentation_key` and `connection_string` are marked `sensitive`. Store in Key Vault when consumed by applications; never commit to source control or log in CI output.
- **IP masking** — Default keeps IP masking enabled (`disable_ip_masking = false`) for privacy compliance.
- **Internet access** — Set `internet_ingestion_enabled` and `internet_query_enabled` to `false` in production when private link is configured (future networking module).
- **Tags** — Always pass `module.common.tags` for ownership and audit traceability.
- **RBAC** — Assign Azure roles (e.g. Monitoring Contributor) via separate identity modules; this module does not manage RBAC.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| Workspace billing | Workspace-based App Insights bills through the linked Log Analytics Workspace (per GB ingested) |
| `sampling_percentage` | Lower values reduce telemetry volume and ingestion cost; use `50` in dev, `100` in prod if full fidelity is required |
| Profiler storage | `force_customer_storage_for_profiler = true` requires a customer-managed storage account (additional cost) |
| Data volume | Application SDKs, Container Apps, and diagnostic settings drive ingestion volume |

Monitor ingestion via Azure Cost Management and Log Analytics usage metrics.

## Operational Guidance

- Application Insights must be in the **same region** as the linked Log Analytics Workspace.
- Re-applying updates configurable properties in place; destroying the resource removes associated telemetry configuration references.
- Connection strings and instrumentation keys can be rotated in Azure Portal; Terraform will detect drift on next plan.
- Use the `application_insights` output object when passing metadata to downstream modules without exposing secrets.
- Alerts, availability tests, and diagnostic settings should be managed by their dedicated modules to maintain single responsibility.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Log Analytics Module](../log-analytics/README.md)
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
| [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_insights_name"></a> [application\_insights\_name](#input\_application\_insights\_name) | Name of the Application Insights resource. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |
| <a name="input_application_type"></a> [application\_type](#input\_application\_type) | Type of application monitored by Application Insights. | `string` | `"web"` | no |
| <a name="input_disable_ip_masking"></a> [disable\_ip\_masking](#input\_disable\_ip\_masking) | When true, disables IP masking in telemetry data. | `bool` | `false` | no |
| <a name="input_force_customer_storage_for_profiler"></a> [force\_customer\_storage\_for\_profiler](#input\_force\_customer\_storage\_for\_profiler) | When true, forces customer-managed storage for profiler data. | `bool` | `false` | no |
| <a name="input_internet_ingestion_enabled"></a> [internet\_ingestion\_enabled](#input\_internet\_ingestion\_enabled) | When true, allows ingestion of telemetry over the public internet. | `bool` | `true` | no |
| <a name="input_internet_query_enabled"></a> [internet\_query\_enabled](#input\_internet\_query\_enabled) | When true, allows querying telemetry over the public internet. | `bool` | `true` | no |
| <a name="input_local_authentication_disabled"></a> [local\_authentication\_disabled](#input\_local\_authentication\_disabled) | When true, disables local authentication in favour of Azure AD authentication. | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for Application Insights. Should match the linked Log Analytics Workspace region. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where Application Insights is created. | `string` | n/a | yes |
| <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage) | Percentage of telemetry data sampled (0-100). Lower values reduce ingestion cost. | `number` | `50` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to Application Insights. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | Resource ID of the existing Log Analytics Workspace. This module does not create the workspace. | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_insights"></a> [application\_insights](#output\_application\_insights) | Non-sensitive Application Insights metadata for downstream module composition. |
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | The connection string for Application Insights SDK configuration. Treat as confidential. |
| <a name="output_id"></a> [id](#output\_id) | The Application Insights application ID (GUID). |
| <a name="output_instrumentation_key"></a> [instrumentation\_key](#output\_instrumentation\_key) | The instrumentation key for Application Insights SDK configuration. Treat as confidential. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Application Insights resource. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the Application Insights resource. |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | The resource ID of the linked Log Analytics Workspace. |
<!-- END_TF_DOCS -->
