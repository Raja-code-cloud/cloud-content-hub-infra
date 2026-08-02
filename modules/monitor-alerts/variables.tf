# ------------------------------------------------------------------------------
# Monitor Alerts Module — Variables
# ------------------------------------------------------------------------------

variable "metric_alerts" {
  description = "List of Azure Monitor metric alert rules. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                      = string
    alert_name               = string
    resource_group_name      = string
    scopes                   = list(string)
    description              = optional(string)
    enabled                  = optional(bool, true)
    auto_mitigate            = optional(bool, true)
    frequency                = string
    window_size              = string
    severity                 = number
    target_resource_type     = optional(string)
    target_resource_location = optional(string)
    tags                     = optional(map(string), {})
    criteria = optional(list(object({
      metric_namespace       = string
      metric_name            = string
      aggregation            = string
      operator               = string
      threshold              = number
      skip_metric_validation = optional(bool, false)
      dimensions = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    })), [])
    dynamic_criteria = optional(object({
      metric_namespace         = string
      metric_name              = string
      aggregation              = string
      operator                 = string
      alert_sensitivity        = string
      evaluation_total_count   = optional(number)
      evaluation_failure_count = optional(number)
      ignore_data_before       = optional(string)
      skip_metric_validation   = optional(bool, false)
      dimensions = optional(list(object({
        name     = string
        operator = string
        values   = list(string)
      })), [])
    }))
    application_insights_web_test_location_availability_criteria = optional(object({
      web_test_id           = string
      component_id          = string
      failed_location_count = number
    }))
    actions = list(object({
      action_group_id    = string
      webhook_properties = optional(map(string))
    }))
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for alert in var.metric_alerts : alert.key])) == length(var.metric_alerts)
    error_message = "Each metric alert key must be unique."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", alert.key))
    ])
    error_message = "Each metric alert key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^[\\w\\(\\)\\.-]{1,260}$", alert.alert_name))
    ])
    error_message = "Each alert_name must be 1-260 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      length(alert.scopes) > 0
    ])
    error_message = "Each metric alert must specify at least one scope."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for scope in alert.scopes :
        can(regex("^/subscriptions/[0-9a-f-]{36}(/resourceGroups/[\\w\\(\\)\\.-]+(/providers/.+)?)?$", scope))
      ])
    ])
    error_message = "Each scope must be a valid subscription, resource group, or resource ID."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alert.severity >= 0 && alert.severity <= 4
    ])
    error_message = "severity must be between 0 (Critical) and 4 (Verbose)."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^PT([0-9]+M|[0-9]+H|[0-9]+D)$", alert.frequency))
    ])
    error_message = "frequency must be an ISO8601 duration starting with PT (e.g. PT1M, PT5M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^PT([0-9]+M|[0-9]+H|[0-9]+D)$", alert.window_size))
    ])
    error_message = "window_size must be an ISO8601 duration starting with PT (e.g. PT5M, PT15M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      (
        length(try(alert.criteria, [])) > 0 &&
        try(alert.dynamic_criteria, null) == null &&
        try(alert.application_insights_web_test_location_availability_criteria, null) == null
        ) || (
        length(try(alert.criteria, [])) == 0 &&
        try(alert.dynamic_criteria, null) != null &&
        try(alert.application_insights_web_test_location_availability_criteria, null) == null
        ) || (
        length(try(alert.criteria, [])) == 0 &&
        try(alert.dynamic_criteria, null) == null &&
        try(alert.application_insights_web_test_location_availability_criteria, null) != null
      )
    ])
    error_message = "Each alert must specify exactly one criteria type: criteria, dynamic_criteria, or application_insights_web_test_location_availability_criteria."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      length(alert.actions) > 0
    ])
    error_message = "Each metric alert must reference at least one action group."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for action in alert.actions :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Insights/actionGroups/[\\w\\(\\)\\.-]+$", action.action_group_id))
      ])
    ])
    error_message = "Each action_group_id must be a valid Azure Monitor action group resource ID."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for criterion in try(alert.criteria, []) :
        contains(["Average", "Count", "Minimum", "Maximum", "Total"], criterion.aggregation)
      ])
    ])
    error_message = "criteria aggregation must be Average, Count, Minimum, Maximum, or Total."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for criterion in try(alert.criteria, []) :
        contains(["Equals", "NotEquals", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], criterion.operator)
      ])
    ])
    error_message = "criteria operator must be a supported static threshold operator."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      try(alert.dynamic_criteria, null) == null ||
      contains(["Average", "Count", "Minimum", "Maximum", "Total"], alert.dynamic_criteria.aggregation)
    ])
    error_message = "dynamic_criteria aggregation must be Average, Count, Minimum, Maximum, or Total."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      try(alert.dynamic_criteria, null) == null ||
      contains(["LessThan", "GreaterThan", "GreaterOrLessThan"], alert.dynamic_criteria.operator)
    ])
    error_message = "dynamic_criteria operator must be LessThan, GreaterThan, or GreaterOrLessThan."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      try(alert.dynamic_criteria, null) == null ||
      contains(["Low", "Medium", "High"], alert.dynamic_criteria.alert_sensitivity)
    ])
    error_message = "dynamic_criteria alert_sensitivity must be Low, Medium, or High."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for criterion in try(alert.criteria, []) :
        alltrue([
          for dimension in try(criterion.dimensions, []) :
          contains(["Include", "Exclude"], dimension.operator)
        ])
      ])
    ])
    error_message = "criteria dimension operator must be Include or Exclude."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      (
        length(alert.scopes) == 1 &&
        !can(regex("^/subscriptions/[0-9a-f-]{36}$", alert.scopes[0])) &&
        !can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", alert.scopes[0]))
        ) || (
        try(alert.target_resource_type, null) != null &&
        try(alert.target_resource_location, null) != null
      )
    ])
    error_message = "target_resource_type and target_resource_location are required when scopes include subscription or resource group IDs, or multiple scopes."
  }
}
