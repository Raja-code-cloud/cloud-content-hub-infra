# Azure Monitor Alerts Module

Creates **Azure Monitor metric alert rules** and **scheduled query (log) alert rules**. Does not create action groups, Log Analytics workspaces, diagnostic settings, dashboards, workbooks, or budgets.

## Purpose

- Define metric-based and log-based alert rules for any Azure resource
- Route alerts to existing action groups supplied by the caller
- Manage **hundreds of alert rules** via stable `for_each` keys
- Remain environment-agnostic with no hardcoded resource names or thresholds

This module creates **only**:

- `azurerm_monitor_metric_alert`
- `azurerm_monitor_scheduled_query_rules_alert_v2`

Activity log alerts are reserved for future extension (placeholder in `main.tf`).

## Architecture

```
environments/<env>/
    module "action_group"     ──▶ action_group_ids
    module "log_analytics"      ──▶ workspace_id (scheduled query alerts)
    module "storage"            ──▶ target_resource_id (metric alerts)
    module "monitor_alerts"     ──▶ metric + scheduled query alert rules
```

Action groups, Log Analytics workspaces, and target resources must exist before alert rules are applied. The module consumes action group IDs and never creates notification destinations.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Supported Alert Types

| Type | Resource | Status |
|------|----------|--------|
| Metric Alerts | `azurerm_monitor_metric_alert` | Supported |
| Scheduled Query (Log) Alerts | `azurerm_monitor_scheduled_query_rules_alert_v2` | Supported |
| Activity Log Alerts | `azurerm_monitor_activity_log_alert` | Future-ready |

## Supported Targets

Any Azure resource that exposes platform metrics or sends logs to a Log Analytics workspace, including:

| Resource | Metric Namespace | Example Metrics |
|----------|------------------|-----------------|
| Container App | `Microsoft.App/containerApps` | `UsageNanoCores`, `Requests`, `Replicas` |
| Container Apps Environment | `Microsoft.App/managedEnvironments` | `CpuPercentage`, `MemoryPercentage` |
| Azure Container Registry | `Microsoft.ContainerRegistry/registries` | `StorageUsed`, `TotalPullCount` |
| Key Vault | `Microsoft.KeyVault/vaults` | `Availability`, `ServiceApiHit` |
| Storage Account | `Microsoft.Storage/storageAccounts` | `UsedCapacity`, `Availability` |
| PostgreSQL Flexible Server | `Microsoft.DBforPostgreSQL/flexibleServers` | `cpu_percent`, `storage_percent` |
| Application Insights | `Microsoft.Insights/components` | `availabilityResults/availabilityPercentage` |
| Redis Cache | `Microsoft.Cache/redis` | `connectedclients`, `usedmemorypercentage` |

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `resource_group_name` | yes | Resource group where alert rules are deployed |
| `location` | conditional | Azure region for scheduled query alert rules (required when `scheduled_query_alerts` are defined) |
| `action_group_ids` | conditional | Existing action group resource IDs (required when alerts are defined) |
| `tags` | no | Tags applied to all alert rules |
| `metric_alerts` | no | List of metric alert definitions |
| `scheduled_query_alerts` | no | List of scheduled query alert definitions |

### Metric alert fields

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Alert rule name |
| `target_resource_id` | yes | Azure resource ID to monitor |
| `metric_namespace` | yes | e.g. `Microsoft.Storage/storageAccounts` |
| `metric_name` | yes | e.g. `UsedCapacity` |
| `aggregation` | yes | `Average`, `Count`, `Minimum`, `Maximum`, `Total` |
| `operator` | yes | `GreaterThan`, `LessThan`, etc. |
| `threshold` | yes | Static threshold value |
| `severity` | yes | `0` Critical → `4` Verbose |
| `window_size` | yes | Aggregation window (ISO8601, e.g. `PT15M`) |
| `evaluation_frequency` | yes | Evaluation frequency (ISO8601, e.g. `PT5M`) |
| `description` | no | Alert description |
| `enabled` | no | Enable rule (default `true`) |
| `auto_mitigate` | no | Auto-resolve when condition clears (default `true`) |
| `dimensions` | no | Metric dimension filters |

### Scheduled query alert fields

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Alert rule name |
| `workspace_id` | yes | Log Analytics workspace or Application Insights resource ID |
| `kql_query` | yes | KQL query evaluated by the alert rule |
| `severity` | yes | `0` Critical → `4` Verbose |
| `evaluation_frequency` | yes | Evaluation frequency (ISO8601, e.g. `PT5M`) |
| `window_size` | yes | Query time window (ISO8601, e.g. `PT15M`) |
| `threshold` | yes | Alert threshold |
| `operator` | yes | `Equal`, `GreaterThan`, `GreaterThanOrEqual`, `LessThan`, `LessThanOrEqual` |
| `time_aggregation` | yes | `Count`, `Average`, `Minimum`, `Maximum`, `Total` |
| `description` | no | Alert description |
| `enabled` | no | Enable rule (default `true`) |

## Outputs

| Name | Description |
|------|-------------|
| `metric_alert_ids` | Map of keys to metric alert resource IDs |
| `scheduled_query_alert_ids` | Map of keys to scheduled query alert resource IDs |
| `alert_names` | Map of keys to alert rule names (all types) |
| `target_resources` | Map of keys to target resource or workspace IDs |
| `metric_alerts` | Non-sensitive metric alert metadata |
| `scheduled_query_alerts` | Non-sensitive scheduled query alert metadata |

## Examples

### High CPU (Container App)

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "container-app-cpu-high"
      name                 = "alert-container-app-cpu-high"
      description          = "Container App CPU usage exceeds threshold"
      target_resource_id   = module.container_app.resource_id
      metric_namespace     = "Microsoft.App/containerApps"
      metric_name          = "UsageNanoCores"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 800000000
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
    },
  ]
}
```

### High Memory (Container Apps Environment)

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "cae-memory-high"
      name                 = "alert-cae-memory-high"
      description          = "Container Apps Environment memory usage is high"
      target_resource_id   = module.container_app_environment.resource_id
      metric_namespace     = "Microsoft.App/managedEnvironments"
      metric_name          = "MemoryPercentage"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 85
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
    },
  ]
}
```

### Container Restarts (Log Alert)

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  scheduled_query_alerts = [
    {
      key                  = "container-restarts"
      name                 = "alert-container-restarts"
      description          = "Container App restart count exceeds threshold"
      workspace_id         = module.log_analytics.workspace_id
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
      threshold            = 3
      operator             = "GreaterThan"
      time_aggregation     = "Count"
      kql_query            = <<-QUERY
        ContainerAppConsoleLogs_CL
        | where Log_s contains "restart" or Log_s contains "Restart"
        | summarize RestartCount = count() by ContainerAppName_s, bin(TimeGenerated, 5m)
      QUERY
    },
  ]
}
```

### HTTP 5xx (Metric Alert with Dimensions)

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "container-app-http-5xx"
      name                 = "alert-container-app-http-5xx"
      description          = "HTTP 5xx response count exceeds threshold"
      target_resource_id   = module.container_app.resource_id
      metric_namespace     = "Microsoft.App/containerApps"
      metric_name          = "Requests"
      aggregation          = "Count"
      operator             = "GreaterThan"
      threshold            = 50
      severity             = 1
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
      dimensions = [
        {
          name     = "statusCodeCategory"
          operator = "Include"
          values   = ["5xx"]
        },
      ]
    },
  ]
}
```

### Storage Capacity

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "storage-capacity"
      name                 = "alert-storage-capacity"
      description          = "Storage account used capacity exceeds threshold"
      target_resource_id   = module.storage.resource_id
      metric_namespace     = "Microsoft.Storage/storageAccounts"
      metric_name          = "UsedCapacity"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 85899345920
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT1H"
    },
  ]
}
```

### Key Vault Availability

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["critical"],
  ]

  metric_alerts = [
    {
      key                  = "keyvault-availability"
      name                 = "alert-keyvault-availability"
      description          = "Key Vault availability dropped below threshold"
      target_resource_id   = module.key_vault.resource_id
      metric_namespace     = "Microsoft.KeyVault/vaults"
      metric_name          = "Availability"
      aggregation          = "Average"
      operator             = "LessThan"
      threshold            = 99
      severity             = 0
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
    },
  ]
}
```

### PostgreSQL CPU

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["critical"],
  ]

  metric_alerts = [
    {
      key                  = "postgres-cpu"
      name                 = "alert-postgres-cpu-high"
      description          = "PostgreSQL CPU usage exceeds threshold"
      target_resource_id   = module.postgresql_flexible_server.resource_id
      metric_namespace     = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric_name          = "cpu_percent"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 85
      severity             = 1
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
    },
  ]
}
```

### PostgreSQL Storage

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "postgres-storage"
      name                 = "alert-postgres-storage-high"
      description          = "PostgreSQL storage usage exceeds threshold"
      target_resource_id   = module.postgresql_flexible_server.resource_id
      metric_namespace     = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric_name          = "storage_percent"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 80
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
    },
  ]
}
```

### Container App Availability

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = [
    module.action_group.action_group_ids["critical"],
    module.action_group.action_group_ids["platform-ops"],
  ]

  metric_alerts = [
    {
      key                  = "container-app-availability"
      name                 = "alert-container-app-availability"
      description          = "Container App replica count dropped below minimum"
      target_resource_id   = module.container_app.resource_id
      metric_namespace     = "Microsoft.App/containerApps"
      metric_name          = "Replicas"
      aggregation          = "Average"
      operator             = "LessThan"
      threshold            = 1
      severity             = 0
      evaluation_frequency = "PT1M"
      window_size          = "PT5M"
      auto_mitigate        = true
    },
  ]
}
```

### Combined metric and log alerts

```hcl
module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  action_group_ids = values(module.action_group.action_group_ids)

  metric_alerts = [
    {
      key                  = "acr-storage"
      name                 = "alert-acr-storage"
      target_resource_id   = module.acr.resource_id
      metric_namespace     = "Microsoft.ContainerRegistry/registries"
      metric_name          = "StorageUsed"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 5368709120
      severity             = 3
      evaluation_frequency = "PT15M"
      window_size          = "PT1H"
    },
  ]

  scheduled_query_alerts = [
    {
      key                  = "failed-requests"
      name                 = "alert-failed-requests"
      workspace_id         = module.application_insights.resource_id
      kql_query            = "requests | where success == false | summarize FailedCount = count()"
      severity             = 2
      evaluation_frequency = "PT5M"
      window_size          = "PT15M"
      threshold            = 10
      operator             = "GreaterThan"
      time_aggregation     = "Count"
    },
  ]
}
```

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Use stable `key` values | Prevents Terraform state churn when alert names change |
| Match severity to action group | Route sev 0–1 to critical/on-call groups |
| Set `auto_mitigate = true` for metric alerts | Auto-resolve when metrics return to normal |
| Start with longer `window_size` in dev | Reduces alert fatigue during testing |
| Use dimensions to filter noise | e.g. HTTP 5xx only, not all requests |
| Keep KQL queries focused | Narrow time ranges and filters reduce evaluation cost |
| Assign managed identity to log alerts when needed | Required for cross-resource query scopes in some subscriptions |

## Severity Reference

| Value | Level |
|-------|-------|
| 0 | Critical |
| 1 | Error |
| 2 | Warning |
| 3 | Informational |
| 4 | Verbose |

## Operational Guidance

1. **Deploy action groups first** — Alert rules reference existing action group IDs.
2. **Enable diagnostic settings** — Log-based alerts require data in the target workspace.
3. **Validate metrics exist** — Use Azure Monitor Metrics Explorer before defining thresholds.
4. **Tune thresholds iteratively** — Start with conservative values and tighten based on baseline data.
5. **Use multiple action groups** — Route the same alert to on-call and ticketing systems.
6. **Review fired alerts weekly** — Adjust thresholds and windows to reduce false positives.

## Cost Considerations

Alert rules themselves are generally low cost. Costs increase with:

- High evaluation frequency (`PT1M` vs `PT15M`)
- Large numbers of scheduled query alert rules
- Complex KQL queries scanning large datasets
- SMS/voice notifications via action groups (billed separately)

Scheduled query alerts evaluate KQL against Log Analytics data, which may incur query ingestion and compute charges depending on workspace pricing tier.

## Security

- No secrets are accepted or exposed by this module
- Action group IDs are resource references only
- KQL queries should not embed credentials or connection strings
- Apply least-privilege RBAC to the Terraform deployment identity

## Related

- [Action Group Module](../action-group/README.md)
- [Application Insights Module](../application-insights/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)
- [Log Analytics Module](../log-analytics/README.md)
