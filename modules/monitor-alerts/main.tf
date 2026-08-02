# ------------------------------------------------------------------------------
# Monitor Alerts Module
#
# Creates Azure Monitor metric alert rules only.
# Does NOT create action groups, Log Analytics, or diagnostic settings.
# See: modules/monitor-alerts/README.md
# ------------------------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.metric_alerts

  name                     = each.value.alert_name
  resource_group_name      = each.value.resource_group_name
  scopes                   = each.value.scopes
  description              = try(each.value.description, null)
  enabled                  = try(each.value.enabled, true)
  auto_mitigate            = try(each.value.auto_mitigate, true)
  frequency                = each.value.frequency
  window_size              = each.value.window_size
  severity                 = each.value.severity
  target_resource_type     = try(each.value.target_resource_type, null)
  target_resource_location = try(each.value.target_resource_location, null)
  tags                     = try(each.value.tags, {})

  dynamic "criteria" {
    for_each = try(each.value.criteria, [])
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = try(criteria.value.skip_metric_validation, false)

      dynamic "dimension" {
        for_each = try(criteria.value.dimensions, [])
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = try(each.value.dynamic_criteria, null) != null ? [each.value.dynamic_criteria] : []
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name              = dynamic_criteria.value.metric_name
      aggregation              = dynamic_criteria.value.aggregation
      operator                 = dynamic_criteria.value.operator
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = try(dynamic_criteria.value.evaluation_total_count, null)
      evaluation_failure_count = try(dynamic_criteria.value.evaluation_failure_count, null)
      ignore_data_before       = try(dynamic_criteria.value.ignore_data_before, null)
      skip_metric_validation   = try(dynamic_criteria.value.skip_metric_validation, false)

      dynamic "dimension" {
        for_each = try(dynamic_criteria.value.dimensions, [])
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "application_insights_web_test_location_availability_criteria" {
    for_each = try(each.value.application_insights_web_test_location_availability_criteria, null) != null ? [each.value.application_insights_web_test_location_availability_criteria] : []
    content {
      web_test_id           = application_insights_web_test_location_availability_criteria.value.web_test_id
      component_id          = application_insights_web_test_location_availability_criteria.value.component_id
      failed_location_count = application_insights_web_test_location_availability_criteria.value.failed_location_count
    }
  }

  dynamic "action" {
    for_each = each.value.actions
    content {
      action_group_id    = action.value.action_group_id
      webhook_properties = try(action.value.webhook_properties, null)
    }
  }
}
