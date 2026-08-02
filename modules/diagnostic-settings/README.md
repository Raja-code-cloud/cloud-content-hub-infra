# Azure Diagnostic Settings Module

Creates **Azure Monitor Diagnostic Settings** for any supported Azure resource. Does not create Log Analytics Workspaces, Storage Accounts, Event Hubs, alerts, or policies.

## Purpose

- Attach diagnostic logging and metrics to **any Azure resource** via `target_resource_id`
- Route diagnostics to existing **Log Analytics**, **Storage Account**, **Event Hub**, or **marketplace partner** destinations
- Manage **multiple diagnostic settings** per deployment using stable `for_each` keys
- Enable or disable log and metric categories dynamically without hardcoding resource-specific categories

This module creates **only** `azurerm_monitor_diagnostic_setting` resources.

## Architecture

```
environments/<env>/
    module "log_analytics"          ──▶ log_analytics_workspace_id (existing)
    module "storage"                ──▶ storage_account_id (optional, existing)
    module "key_vault"              ──▶ target_resource_id
    module "acr"                    ──▶ target_resource_id
    module "container_app"          ──▶ target_resource_id
    module "diagnostic_settings"    ──▶ azurerm_monitor_diagnostic_setting (for_each)
            │
            ▼
    Azure Monitor routes logs/metrics to configured destinations
```

Destinations and target resources must already exist. This module never creates them.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

Uses azurerm v5 blocks: `enabled_log` and `enabled_metric`.

## Inputs

### `diagnostic_settings`

List of diagnostic setting objects. Each entry requires a unique `key` for stable Terraform state at scale.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable identifier for `for_each` (2–64 chars, lowercase alphanumeric/hyphen) |
| `diagnostic_name` | yes | Diagnostic setting name (1–260 chars; cannot be `service`) |
| `target_resource_id` | yes | Full Azure Resource Manager ID of the resource to monitor |
| `log_analytics_workspace_id` | conditional | Log Analytics Workspace **resource ID** (ARM ID) |
| `storage_account_id` | conditional | Storage Account resource ID for archive destination |
| `eventhub_authorization_rule_id` | conditional | Event Hub Namespace authorization rule ID |
| `eventhub_name` | no | Event Hub name (requires `eventhub_authorization_rule_id`) |
| `marketplace_partner_resource_id` | conditional | Partner solution resource ID (maps to `partner_solution_id`) |
| `log_analytics_destination_type` | no | `AzureDiagnostics` or `Dedicated` (when LAW destination is set) |
| `logs` | no | List of log category configurations (default `[]`) |
| `metrics` | no | List of metric category configurations (default `[]`) |

At least **one destination** must be specified per setting. At least **one enabled log or metric** must be specified.

### Log object (`logs`)

| Field | Required | Description |
|-------|:--------:|-------------|
| `category` | conditional | Diagnostic log category name (resource-specific) |
| `category_group` | conditional | Diagnostic log category group (e.g. `allLogs`) |
| `enabled` | no | Include this category (default `true`) |

Exactly one of `category` or `category_group` per enabled log entry.

Use the [`azurerm_monitor_diagnostic_categories`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) data source to discover valid categories for a target resource.

### Metric object (`metrics`)

| Field | Required | Description |
|-------|:--------:|-------------|
| `category` | yes | Metric category name (commonly `AllMetrics`) |
| `enabled` | no | Include this category (default `true`) |

## Outputs

| Name | Description |
|------|-------------|
| `diagnostic_setting_ids` | Map of keys to diagnostic setting resource IDs |
| `diagnostic_setting_names` | Map of keys to diagnostic setting names |
| `target_resource_ids` | Map of keys to monitored target resource IDs |
| `diagnostic_settings` | Non-sensitive metadata map for downstream composition |

## Examples

### Container App

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "container-app-api"
      diagnostic_name            = "diag-container-app-api"
      target_resource_id         = module.container_app.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id

      logs = [
        { category = "ContainerAppConsoleLogs" },
        { category = "ContainerAppSystemLogs" },
      ]

      metrics = [
        { category = "AllMetrics" },
      ]
    },
  ]
}
```

### Container Apps Environment

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "cae-platform"
      diagnostic_name            = "diag-cae-platform"
      target_resource_id         = module.container_app_environment.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      log_analytics_destination_type = "Dedicated"

      logs = [
        { category_group = "allLogs" },
      ]

      metrics = [
        { category = "AllMetrics" },
      ]
    },
  ]
}
```

### Storage Account

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "storage-platform"
      diagnostic_name            = "diag-storage-platform"
      target_resource_id         = module.storage.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      storage_account_id         = module.storage.resource_id

      logs = [
        { category = "StorageRead",  enabled = true },
        { category = "StorageWrite", enabled = true },
        { category = "StorageDelete", enabled = true },
      ]

      metrics = [
        { category = "Transaction" },
      ]
    },
  ]
}
```

### Key Vault

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "key-vault-platform"
      diagnostic_name            = "diag-key-vault-platform"
      target_resource_id         = module.key_vault.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id

      logs = [
        { category = "AuditEvent" },
        { category = "AzurePolicyEvaluationDetails", enabled = false },
      ]

      metrics = [
        { category = "AllMetrics" },
      ]
    },
  ]
}
```

### Azure Container Registry

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "acr-platform"
      diagnostic_name            = "diag-acr-platform"
      target_resource_id         = module.acr.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id

      logs = [
        { category = "ContainerRegistryRepositoryEvents" },
        { category = "ContainerRegistryLoginEvents" },
      ]

      metrics = [
        { category = "AllMetrics" },
      ]
    },
  ]
}
```

### PostgreSQL Flexible Server

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "postgres-platform"
      diagnostic_name            = "diag-postgres-platform"
      target_resource_id         = module.postgresql_flexible_server.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id

      logs = [
        { category = "PostgreSQLLogs" },
      ]

      metrics = [
        { category = "AllMetrics" },
      ]
    },
  ]
}
```

### Multiple settings (batch)

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                        = "kv-diag"
      diagnostic_name            = "diag-key-vault"
      target_resource_id         = module.key_vault.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      logs    = [{ category = "AuditEvent" }]
      metrics = [{ category = "AllMetrics" }]
    },
    {
      key                        = "acr-diag"
      diagnostic_name            = "diag-acr"
      target_resource_id         = module.acr.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      logs    = [{ category = "ContainerRegistryLoginEvents" }]
      metrics = [{ category = "AllMetrics" }]
    },
  ]
}
```

### Event Hub destination (optional)

```hcl
module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = [
    {
      key                            = "storage-eventhub"
      diagnostic_name                = "diag-storage-eventhub"
      target_resource_id             = module.storage.resource_id
      eventhub_authorization_rule_id = var.eventhub_namespace_auth_rule_id
      eventhub_name                  = "platform-diagnostics"
      logs    = [{ category = "StorageRead" }]
      metrics = [{ category = "Transaction" }]
    },
  ]
}
```

## Discovering Log and Metric Categories

Categories vary by resource type. Use the data source before defining settings:

```hcl
data "azurerm_monitor_diagnostic_categories" "key_vault" {
  resource_id = module.key_vault.resource_id
}

# data.azurerm_monitor_diagnostic_categories.key_vault.log_category_types
# data.azurerm_monitor_diagnostic_categories.key_vault.metric_category_types
```

Do not hardcode categories in this module — pass them from the environment root or derived from data sources.

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Use `category_group = "allLogs"` when supported | Simplifies future category additions |
| Prefer Log Analytics for operational queries | Centralized observability platform |
| Use `log_analytics_destination_type = "Dedicated"` when available | Resource-specific tables improve query performance |
| One diagnostic setting per target per purpose | Azure allows multiple settings with unique names |
| Stable `key` values | Prevents unnecessary Terraform replacement at scale |
| Disable categories with `enabled = false` | Explicit intent without removing configuration |
| Apply after target resource exists | Diagnostic settings require a live target resource ID |

## Operational Guidance

1. **Apply order** — Create target resources first; add `depends_on` if Terraform ordering is ambiguous.
2. **Import** — Use format `{targetResourceId}|{diagnosticSettingName}` for existing settings.
3. **Name `service`** — Avoid; legacy Azure API prevents full deletion.
4. **Managed Identity** — Diagnostic settings are not supported on all resource types (e.g. user-assigned managed identity). Verify per resource documentation.
5. **Application Insights** — Workspace-based App Insights may receive telemetry via workspace linkage rather than direct diagnostic settings.

## Cost Considerations

| Destination | Cost Driver |
|-------------|-------------|
| Log Analytics | Ingestion volume (GB/day); use workspace daily quota in dev |
| Storage Account | Blob storage for archived logs |
| Event Hub | Throughput units and retention |
| Metrics | Generally lower cost; included in platform metrics billing |

Reduce cost in development by:

- Enabling only required log categories (not `allLogs` where granular control is needed)
- Using Log Analytics daily ingestion cap
- Omitting `storage_account_id` when archive is not required

## Security

- Does **not** create or expose destination credentials
- Consumes existing destination resource IDs only
- No sensitive outputs
- Event Hub authorization uses existing namespace authorization rule IDs

## Supported Azure Resources

This module accepts any valid `target_resource_id`. Common platform resources:

| Resource | Example Categories |
|----------|-------------------|
| Container App | `ContainerAppConsoleLogs`, `ContainerAppSystemLogs` |
| Container Apps Environment | `allLogs` (category group) |
| Storage Account | `StorageRead`, `StorageWrite`, `StorageDelete` |
| Key Vault | `AuditEvent` |
| Container Registry | `ContainerRegistryLoginEvents`, `ContainerRegistryRepositoryEvents` |
| PostgreSQL Flexible Server | `PostgreSQLLogs` |
| Application Insights | Varies — verify with diagnostic categories data source |

Future resources are supported without module changes — pass the resource ID and appropriate categories.

## Related

- [Log Analytics Module](../log-analytics/README.md)
- [Storage Module](../storage/README.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)
