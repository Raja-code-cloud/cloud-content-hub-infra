# ------------------------------------------------------------------------------
# Monitor Alerts Module
#
# Creates Azure Monitor metric and scheduled query (log) alert rules.
# Does NOT create action groups, Log Analytics workspaces, or diagnostic settings.
# See: modules/monitor-alerts/README.md
# ------------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.metric_alerts

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  scopes              = each.value.scopes
  description         = each.value.description
  enabled             = each.value.enabled
  auto_mitigate       = each.value.auto_mitigate
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  severity            = each.value.severity
  tags                = each.value.tags

  dynamic "criteria" {
    for_each = each.value.criteria
    content {
      metric_namespace = criteria.value.metric_namespace
      metric_name      = criteria.value.metric_name
      aggregation      = criteria.value.aggregation
      operator         = criteria.value.operator
      threshold        = criteria.value.threshold

      dynamic "dimension" {
        for_each = criteria.value.dimensions
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = each.value.actions
    content {
      action_group_id = action.value.action_group_id
    }
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "this" {
  for_each = local.scheduled_query_alerts

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  location             = each.value.location
  description          = each.value.description
  enabled              = each.value.enabled
  evaluation_frequency = each.value.evaluation_frequency
  window_duration      = each.value.window_duration
  scopes               = each.value.scopes
  severity             = each.value.severity
  tags                 = each.value.tags

  criteria {
    query                   = each.value.criteria.query
    time_aggregation_method = each.value.criteria.time_aggregation_method
    operator                = each.value.criteria.operator
    threshold               = each.value.criteria.threshold

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = each.value.action_group_ids
  }
}

# Future-ready: Activity Log Alerts
# resource "azurerm_monitor_activity_log_alert" "this" {
#   for_each = local.activity_log_alerts
#   ...
# }
