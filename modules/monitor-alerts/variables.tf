# ------------------------------------------------------------------------------
# Monitor Alerts Module — Variables
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group where alert rules are deployed."
  type        = string

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 valid Azure name characters."
  }
}

variable "location" {
  description = "Azure region for scheduled query alert rules. Required when scheduled_query_alerts are defined."
  type        = string
  default     = ""

  validation {
    condition     = length(trimspace(var.location)) == 0 || length(trimspace(var.location)) >= 1
    error_message = "location must not contain only whitespace when specified."
  }
}

variable "action_group_ids" {
  description = "List of existing Azure Monitor action group resource IDs to notify when alerts fire."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for action_group_id in var.action_group_ids :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Insights/actionGroups/[\\w\\(\\)\\.-]+$", action_group_id))
    ])
    error_message = "Each action_group_id must be a valid Azure Monitor action group resource ID."
  }

  validation {
    condition     = (length(var.metric_alerts) + length(var.scheduled_query_alerts)) == 0 || length(var.action_group_ids) > 0
    error_message = "At least one action_group_id is required when metric_alerts or scheduled_query_alerts are defined."
  }
}

variable "tags" {
  description = "Tags applied to all alert rules created by this module."
  type        = map(string)
  default     = {}
}

variable "metric_alerts" {
  description = "List of Azure Monitor metric alert rules. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                  = string
    name                 = string
    description          = optional(string)
    target_resource_id   = string
    metric_namespace     = string
    metric_name          = string
    aggregation          = string
    operator             = string
    threshold            = number
    severity             = number
    window_size          = string
    evaluation_frequency = string
    enabled              = optional(bool, true)
    auto_mitigate        = optional(bool, true)
    dimensions = optional(list(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
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
      can(regex("^[\\w\\(\\)\\.-]{1,260}$", alert.name))
    ])
    error_message = "Each metric alert name must be 1-260 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", alert.target_resource_id))
    ])
    error_message = "Each target_resource_id must be a valid Azure resource ID."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^Microsoft\\.[A-Za-z0-9]+/[A-Za-z0-9]+$", alert.metric_namespace))
    ])
    error_message = "Each metric_namespace must follow the Microsoft.<Provider>/<ResourceType> format."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      length(trimspace(alert.metric_name)) > 0
    ])
    error_message = "Each metric_name must not be empty."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      contains(["Average", "Count", "Minimum", "Maximum", "Total"], alert.aggregation)
    ])
    error_message = "aggregation must be Average, Count, Minimum, Maximum, or Total."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      contains(["Equals", "NotEquals", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], alert.operator)
    ])
    error_message = "operator must be Equals, NotEquals, GreaterThan, GreaterThanOrEqual, LessThan, or LessThanOrEqual."
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
      can(regex("^PT([1-9][0-9]*M|[1-9][0-9]*H|[1-9][0-9]*D)$", alert.evaluation_frequency))
    ])
    error_message = "evaluation_frequency must be an ISO8601 duration starting with PT (e.g. PT1M, PT5M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      can(regex("^PT([1-9][0-9]*M|[1-9][0-9]*H|[1-9][0-9]*D)$", alert.window_size))
    ])
    error_message = "window_size must be an ISO8601 duration starting with PT (e.g. PT5M, PT15M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for dimension in try(alert.dimensions, []) :
        contains(["Include", "Exclude"], dimension.operator)
      ])
    ])
    error_message = "dimension operator must be Include or Exclude."
  }

  validation {
    condition = alltrue([
      for alert in var.metric_alerts :
      alltrue([
        for dimension in try(alert.dimensions, []) :
        length(dimension.values) > 0
      ])
    ])
    error_message = "Each dimension must specify at least one value."
  }
}

variable "scheduled_query_alerts" {
  description = "List of Azure Monitor scheduled query (log) alert rules. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                  = string
    name                 = string
    description          = optional(string)
    workspace_id         = string
    kql_query            = string
    severity             = number
    evaluation_frequency = string
    window_size          = string
    threshold            = number
    operator             = string
    time_aggregation     = string
    enabled              = optional(bool, true)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for alert in var.scheduled_query_alerts : alert.key])) == length(var.scheduled_query_alerts)
    error_message = "Each scheduled query alert key must be unique."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", alert.key))
    ])
    error_message = "Each scheduled query alert key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      can(regex("^[\\w\\(\\)\\.-]{1,260}$", alert.name))
    ])
    error_message = "Each scheduled query alert name must be 1-260 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/(Microsoft\\.OperationalInsights/workspaces|Microsoft\\.Insights/components)/[\\w\\(\\)\\.-]+$", alert.workspace_id))
    ])
    error_message = "Each workspace_id must be a valid Log Analytics workspace or Application Insights component resource ID."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      length(trimspace(alert.kql_query)) > 0
    ])
    error_message = "Each kql_query must not be empty."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      alert.severity >= 0 && alert.severity <= 4
    ])
    error_message = "severity must be between 0 (Critical) and 4 (Verbose)."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      can(regex("^PT([1-9][0-9]*M|[1-9][0-9]*H|[1-9][0-9]*D)$", alert.evaluation_frequency))
    ])
    error_message = "evaluation_frequency must be an ISO8601 duration starting with PT (e.g. PT5M, PT15M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      can(regex("^PT([1-9][0-9]*M|[1-9][0-9]*H|[1-9][0-9]*D)$", alert.window_size))
    ])
    error_message = "window_size must be an ISO8601 duration starting with PT (e.g. PT5M, PT15M, PT1H)."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      contains(["Equal", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual"], alert.operator)
    ])
    error_message = "operator must be Equal, GreaterThan, GreaterThanOrEqual, LessThan, or LessThanOrEqual."
  }

  validation {
    condition = alltrue([
      for alert in var.scheduled_query_alerts :
      contains(["Count", "Average", "Minimum", "Maximum", "Total"], alert.time_aggregation)
    ])
    error_message = "time_aggregation must be Count, Average, Minimum, Maximum, or Total."
  }

  validation {
    condition     = length(var.scheduled_query_alerts) == 0 || length(trimspace(var.location)) > 0
    error_message = "location is required when scheduled_query_alerts are defined."
  }
}
