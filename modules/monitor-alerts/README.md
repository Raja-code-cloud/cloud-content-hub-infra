# Azure Monitor Metric Alerts Module

Creates **Azure Monitor metric alert rules**. Does not create action groups, Log Analytics, or diagnostic settings.

## Purpose

- Define metric-based alert rules for any Azure resource scope
- Support static thresholds, dynamic thresholds, and Application Insights web test availability
- Route alerts to existing action groups
- Manage **multiple alert rules** via stable `for_each` keys

This module creates **only** `azurerm_monitor_metric_alert` resources.

## Architecture

```
environments/<env>/
    module "action_group"       ──▶ action_group_ids
    module "storage"            ──▶ scopes (resource_id)
    module "postgresql_..."     ──▶ scopes (resource_id)
    module "monitor_alerts"     ──▶ azurerm_monitor_metric_alert (for_each)
```

Action groups and target resources must exist before alert rules are applied.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

### `metric_alerts`

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `alert_name` | yes | Alert rule name |
| `resource_group_name` | yes | Resource group for the alert rule resource |
| `scopes` | yes | List of resource IDs to monitor (min 1) |
| `frequency` | yes | Evaluation frequency (ISO8601, e.g. `PT5M`) |
| `window_size` | yes | Aggregation window (ISO8601, e.g. `PT15M`) |
| `severity` | yes | `0` Critical → `4` Verbose |
| `actions` | yes | Action group references (min 1) |
| `description` | no | Alert description |
| `enabled` | no | Enable rule (default `true`) |
| `auto_mitigate` | no | Auto-resolve when condition clears (default `true`) |
| `target_resource_type` | conditional | Required for subscription/RG/multi-scope alerts |
| `target_resource_location` | conditional | Required with `target_resource_type` |
| `criteria` | conditional | Static threshold criteria (one or more) |
| `dynamic_criteria` | conditional | Dynamic threshold criteria (max one) |
| `application_insights_web_test_location_availability_criteria` | conditional | Web test availability criteria (max one) |

Exactly **one** criteria type must be specified per alert.

### Static criteria (`criteria`)

| Field | Required | Description |
|-------|:--------:|-------------|
| `metric_namespace` | yes | e.g. `Microsoft.Storage/storageAccounts` |
| `metric_name` | yes | e.g. `UsedCapacity` |
| `aggregation` | yes | `Average`, `Count`, `Minimum`, `Maximum`, `Total` |
| `operator` | yes | `GreaterThan`, `LessThan`, etc. |
| `threshold` | yes | Static threshold value |
| `dimensions` | no | Metric dimension filters |
| `skip_metric_validation` | no | Skip metric existence check |

### Dynamic criteria (`dynamic_criteria`)

| Field | Required | Description |
|-------|:--------:|-------------|
| `metric_namespace` | yes | Metric namespace |
| `metric_name` | yes | Metric name |
| `aggregation` | yes | Aggregation type |
| `operator` | yes | `LessThan`, `GreaterThan`, `GreaterOrLessThan` |
| `alert_sensitivity` | yes | `Low`, `Medium`, `High` |
| `dimensions` | no | Dimension filters |

## Outputs

| Name | Description |
|------|-------------|
| `alert_ids` | Map of keys to metric alert resource IDs |
| `alert_names` | Map of keys to alert rule names |
| `scopes` | Map of keys to monitored scopes |
| `metric_alerts` | Non-sensitive metadata map |

## Examples

### Storage Account capacity

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  metric_alerts = [
    {
      key                 = "storage-capacity"
      alert_name          = "alert-storage-capacity"
      resource_group_name = module.resource_group.name
      scopes              = [module.storage.resource_id]
      description         = "Storage account capacity exceeds threshold"
      severity            = 2
      frequency           = "PT5M"
      window_size         = "PT1H"
      tags                = module.common.tags

      criteria = [
        {
          metric_namespace = "Microsoft.Storage/storageAccounts"
          metric_name      = "UsedCapacity"
          aggregation      = "Average"
          operator         = "GreaterThan"
          threshold        = 85899345920
        },
      ]

      actions = [
        { action_group_id = module.action_group.action_group_ids["platform-ops"] },
      ]
    },
  ]
}
```

### PostgreSQL CPU

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  metric_alerts = [
    {
      key                 = "postgres-cpu"
      alert_name          = "alert-postgres-cpu-high"
      resource_group_name = module.resource_group.name
      scopes              = [module.postgresql_flexible_server.resource_id]
      severity            = 1
      frequency           = "PT5M"
      window_size         = "PT15M"
      tags                = module.common.tags

      criteria = [
        {
          metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
          metric_name      = "cpu_percent"
          aggregation      = "Average"
          operator         = "GreaterThan"
          threshold        = 85
        },
      ]

      actions = [
        { action_group_id = module.action_group.action_group_ids["critical"] },
      ]
    },
  ]
}
```

### Key Vault availability (dynamic threshold)

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  metric_alerts = [
    {
      key                 = "keyvault-availability"
      alert_name          = "alert-keyvault-availability"
      resource_group_name = module.resource_group.name
      scopes              = [module.key_vault.resource_id]
      severity            = 0
      frequency           = "PT5M"
      window_size         = "PT15M"
      tags                = module.common.tags

      dynamic_criteria = {
        metric_namespace  = "Microsoft.KeyVault/vaults"
        metric_name       = "Availability"
        aggregation       = "Average"
        operator          = "LessThan"
        alert_sensitivity = "Medium"
      }

      actions = [
        { action_group_id = module.action_group.action_group_ids["critical"] },
      ]
    },
  ]
}
```

### Container App HTTP errors

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  metric_alerts = [
    {
      key                 = "container-app-errors"
      alert_name          = "alert-container-app-http-errors"
      resource_group_name = module.resource_group.name
      scopes              = [module.container_app.resource_id]
      severity            = 2
      frequency           = "PT5M"
      window_size         = "PT15M"
      tags                = module.common.tags

      criteria = [
        {
          metric_namespace = "Microsoft.App/containerApps"
          metric_name      = "Requests"
          aggregation      = "Count"
          operator         = "GreaterThan"
          threshold        = 100
          dimensions = [
            {
              name     = "statusCodeCategory"
              operator = "Include"
              values   = ["5xx"]
            },
          ]
        },
      ]

      actions = [
        { action_group_id = module.action_group.action_group_ids["platform-ops"] },
      ]
    },
  ]
}
```

### ACR storage usage

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  metric_alerts = [
    {
      key                 = "acr-storage"
      alert_name          = "alert-acr-storage"
      resource_group_name = module.resource_group.name
      scopes              = [module.acr.resource_id]
      severity            = 3
      frequency           = "PT15M"
      window_size         = "PT1H"
      tags                = module.common.tags

      criteria = [
        {
          metric_namespace = "Microsoft.ContainerRegistry/registries"
          metric_name      = "StorageUsed"
          aggregation      = "Average"
          operator         = "GreaterThan"
          threshold        = 5368709120
        },
      ]

      actions = [
        { action_group_id = module.action_group.action_group_ids["warning"] },
      ]
    },
  ]
}
```

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Match severity to action group | Route sev 0–1 to critical/on-call groups |
| Use dynamic thresholds for variable workloads | Reduces false positives on Container Apps |
| Set `auto_mitigate = true` | Auto-resolve when metrics return to normal |
| Start with longer `window_size` in dev | Avoid alert fatigue during testing |
| Use dimensions to filter noise | e.g. HTTP 5xx only, not all requests |

## Severity Reference

| Value | Level |
|-------|-------|
| 0 | Critical |
| 1 | Error |
| 2 | Warning |
| 3 | Informational |
| 4 | Verbose |

## Cost Considerations

Metric alert rules are generally low cost. Costs increase with:

- High evaluation frequency (`PT1M` vs `PT15M`)
- Large numbers of alert rules
- SMS/voice notifications via action groups

## Related

- [Action Group Module](../action-group/README.md)
- [Application Insights Module](../application-insights/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)
