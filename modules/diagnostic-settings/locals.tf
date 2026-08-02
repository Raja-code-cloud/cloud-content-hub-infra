# ------------------------------------------------------------------------------
# Diagnostic Settings Module — Locals
# ------------------------------------------------------------------------------

locals {
  diagnostic_settings = {
    for setting in var.diagnostic_settings : setting.key => {
      diagnostic_name                 = setting.diagnostic_name
      target_resource_id              = setting.target_resource_id
      log_analytics_workspace_id      = try(setting.log_analytics_workspace_id, null)
      storage_account_id              = try(setting.storage_account_id, null)
      eventhub_authorization_rule_id  = try(setting.eventhub_authorization_rule_id, null)
      eventhub_name                   = try(setting.eventhub_name, null)
      marketplace_partner_resource_id = try(setting.marketplace_partner_resource_id, null)
      log_analytics_destination_type  = try(setting.log_analytics_destination_type, null)
      enabled_logs = [
        for log in setting.logs : log
        if try(log.enabled, true)
      ]
      enabled_metrics = [
        for metric in setting.metrics : metric
        if try(metric.enabled, true)
      ]
    }
  }
}
