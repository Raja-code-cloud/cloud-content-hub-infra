# ------------------------------------------------------------------------------
# Monitor Alerts Module — Outputs
# ------------------------------------------------------------------------------

output "metric_alert_ids" {
  description = "Map of metric alert keys to Azure metric alert resource IDs."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.id }
}

output "scheduled_query_alert_ids" {
  description = "Map of scheduled query alert keys to Azure scheduled query alert resource IDs."
  value       = { for key, alert in azurerm_monitor_scheduled_query_rules_alert_v2.this : key => alert.id }
}

output "alert_names" {
  description = "Map of alert keys to alert rule names across metric and scheduled query alerts."
  value       = local.alert_names
}

output "target_resources" {
  description = "Map of alert keys to monitored target resource or workspace IDs."
  value       = local.target_resources
}

output "metric_alerts" {
  description = "Non-sensitive metric alert metadata for downstream module composition."
  value = {
    for key, alert in azurerm_monitor_metric_alert.this :
    key => {
      id                  = alert.id
      name                = alert.name
      resource_group_name = alert.resource_group_name
      scopes              = alert.scopes
      severity            = alert.severity
      enabled             = alert.enabled
      auto_mitigate       = alert.auto_mitigate
      frequency           = alert.frequency
      window_size         = alert.window_size
    }
  }
}

output "scheduled_query_alerts" {
  description = "Non-sensitive scheduled query alert metadata for downstream module composition."
  value = {
    for key, alert in azurerm_monitor_scheduled_query_rules_alert_v2.this :
    key => {
      id                   = alert.id
      name                 = alert.name
      resource_group_name  = alert.resource_group_name
      scopes               = alert.scopes
      severity             = alert.severity
      enabled              = alert.enabled
      evaluation_frequency = alert.evaluation_frequency
      window_duration      = alert.window_duration
    }
  }
}
