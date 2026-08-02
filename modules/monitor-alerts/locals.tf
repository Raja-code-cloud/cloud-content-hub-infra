# ------------------------------------------------------------------------------
# Monitor Alerts Module — Locals
# ------------------------------------------------------------------------------

locals {
  # Shared action group references applied to every alert rule.
  alert_actions = [
    for action_group_id in var.action_group_ids : {
      action_group_id = action_group_id
    }
  ]

  metric_alerts = {
    for alert in var.metric_alerts : alert.key => {
      name                = alert.name
      resource_group_name = var.resource_group_name
      scopes              = [alert.target_resource_id]
      description         = try(alert.description, null)
      enabled             = try(alert.enabled, true)
      auto_mitigate       = try(alert.auto_mitigate, true)
      frequency           = alert.evaluation_frequency
      window_size         = alert.window_size
      severity            = alert.severity
      tags                = var.tags
      actions             = local.alert_actions
      criteria = [{
        metric_namespace = alert.metric_namespace
        metric_name      = alert.metric_name
        aggregation      = alert.aggregation
        operator         = alert.operator
        threshold        = alert.threshold
        dimensions       = try(alert.dimensions, [])
      }]
    }
  }

  scheduled_query_alerts = {
    for alert in var.scheduled_query_alerts : alert.key => {
      name                 = alert.name
      resource_group_name  = var.resource_group_name
      location             = var.location
      description          = try(alert.description, null)
      enabled              = try(alert.enabled, true)
      evaluation_frequency = alert.evaluation_frequency
      window_duration      = alert.window_size
      scopes               = [alert.workspace_id]
      severity             = alert.severity
      tags                 = var.tags
      action_group_ids     = var.action_group_ids
      criteria = {
        query                   = alert.kql_query
        time_aggregation_method = alert.time_aggregation
        operator                = alert.operator
        threshold               = alert.threshold
      }
    }
  }

  # Future-ready: activity log alerts will be added here when supported.
  # activity_log_alerts = {}

  alert_names = merge(
    { for key, alert in local.metric_alerts : key => alert.name },
    { for key, alert in local.scheduled_query_alerts : key => alert.name },
  )

  target_resources = merge(
    { for key, alert in var.metric_alerts : key => alert.target_resource_id },
    { for key, alert in var.scheduled_query_alerts : key => alert.workspace_id },
  )
}
