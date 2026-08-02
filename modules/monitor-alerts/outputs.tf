# ------------------------------------------------------------------------------
# Monitor Alerts Module — Outputs
# ------------------------------------------------------------------------------

output "alert_ids" {
  description = "Map of metric alert keys to Azure metric alert resource IDs."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.id }
}

output "alert_names" {
  description = "Map of metric alert keys to metric alert rule names."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.name }
}

output "scopes" {
  description = "Map of metric alert keys to monitored scope resource IDs."
  value       = { for key, alert in azurerm_monitor_metric_alert.this : key => alert.scopes }
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
