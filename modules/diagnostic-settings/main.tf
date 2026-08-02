# ------------------------------------------------------------------------------
# Diagnostic Settings Module
#
# Creates Azure Monitor Diagnostic Settings only.
# Does NOT create Log Analytics, Storage, Event Hub, alerts, or policies.
# See: modules/diagnostic-settings/README.md
# ------------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = local.diagnostic_settings

  name                           = each.value.diagnostic_name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = each.value.eventhub_authorization_rule_id
  eventhub_name                  = each.value.eventhub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = each.value.enabled_logs
    content {
      category       = try(enabled_log.value.category, null)
      category_group = try(enabled_log.value.category_group, null)
    }
  }

  dynamic "enabled_metric" {
    for_each = each.value.enabled_metrics
    content {
      category = enabled_metric.value.category
    }
  }
}
