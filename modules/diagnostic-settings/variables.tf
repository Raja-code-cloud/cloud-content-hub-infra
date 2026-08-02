# ------------------------------------------------------------------------------
# Diagnostic Settings Module — Variables
# ------------------------------------------------------------------------------

variable "diagnostic_settings" {
  description = "List of Azure Monitor diagnostic settings. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                             = string
    diagnostic_name                 = string
    target_resource_id              = string
    log_analytics_workspace_id      = optional(string)
    storage_account_id              = optional(string)
    eventhub_authorization_rule_id  = optional(string)
    eventhub_name                   = optional(string)
    marketplace_partner_resource_id = optional(string)
    log_analytics_destination_type  = optional(string)
    logs = optional(list(object({
      category       = optional(string)
      category_group = optional(string)
      enabled        = optional(bool, true)
    })), [])
    metrics = optional(list(object({
      category = string
      enabled  = optional(bool, true)
    })), [])
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for setting in var.diagnostic_settings : setting.key])) == length(var.diagnostic_settings)
    error_message = "Each diagnostic setting key must be unique."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", setting.key))
    ])
    error_message = "Each diagnostic setting key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      length(setting.diagnostic_name) >= 1 && length(setting.diagnostic_name) <= 260
    ])
    error_message = "Each diagnostic_name must be between 1 and 260 characters."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      lower(setting.diagnostic_name) != "service"
    ])
    error_message = "diagnostic_name cannot be 'service' (legacy Azure API restriction prevents full deletion)."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", setting.target_resource_id))
    ])
    error_message = "Each target_resource_id must be a valid Azure resource ID."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      coalesce(
        try(setting.log_analytics_workspace_id, null),
        try(setting.storage_account_id, null),
        try(setting.eventhub_authorization_rule_id, null),
        try(setting.marketplace_partner_resource_id, null)
      ) != null
    ])
    error_message = "Each diagnostic setting must specify at least one destination: log_analytics_workspace_id, storage_account_id, eventhub_authorization_rule_id, or marketplace_partner_resource_id."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.log_analytics_workspace_id, null) == null ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.OperationalInsights/workspaces/[\\w\\(\\)\\.-]+$", setting.log_analytics_workspace_id))
    ])
    error_message = "log_analytics_workspace_id must be a valid Log Analytics Workspace resource ID."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.storage_account_id, null) == null ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Storage/storageAccounts/[\\w\\(\\)\\.-]+$", setting.storage_account_id))
    ])
    error_message = "storage_account_id must be a valid Storage Account resource ID."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.eventhub_authorization_rule_id, null) == null ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.EventHub/namespaces/[\\w\\(\\)\\.-]+/authorizationRules/[\\w\\(\\)\\.-]+$", setting.eventhub_authorization_rule_id))
    ])
    error_message = "eventhub_authorization_rule_id must be a valid Event Hub Namespace authorization rule resource ID."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.marketplace_partner_resource_id, null) == null ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", setting.marketplace_partner_resource_id))
    ])
    error_message = "marketplace_partner_resource_id must be a valid Azure resource ID."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.log_analytics_destination_type, null) == null ||
      contains(["AzureDiagnostics", "Dedicated"], setting.log_analytics_destination_type)
    ])
    error_message = "log_analytics_destination_type must be AzureDiagnostics or Dedicated when specified."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      try(setting.eventhub_name, null) == null ||
      try(setting.eventhub_authorization_rule_id, null) != null
    ])
    error_message = "eventhub_authorization_rule_id is required when eventhub_name is specified."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      length([for log in setting.logs : log if try(log.enabled, true)]) > 0 ||
      length([for metric in setting.metrics : metric if try(metric.enabled, true)]) > 0
    ])
    error_message = "Each diagnostic setting must include at least one enabled log or metric category."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      alltrue([
        for log in setting.logs :
        !try(log.enabled, true) ||
        (
          (try(log.category, null) != null && try(log.category_group, null) == null) ||
          (try(log.category, null) == null && try(log.category_group, null) != null)
        )
      ])
    ])
    error_message = "Each enabled log must specify exactly one of category or category_group."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      length(distinct([
        for log in setting.logs :
        coalesce(try(log.category, null), try(log.category_group, null))
        if try(log.enabled, true)
        ])) == length([
        for log in setting.logs :
        coalesce(try(log.category, null), try(log.category_group, null))
        if try(log.enabled, true)
      ])
    ])
    error_message = "Duplicate log categories are not allowed within a diagnostic setting."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      length(distinct([
        for metric in setting.metrics :
        metric.category
        if try(metric.enabled, true)
        ])) == length([
        for metric in setting.metrics :
        metric.category
        if try(metric.enabled, true)
      ])
    ])
    error_message = "Duplicate metric categories are not allowed within a diagnostic setting."
  }

  validation {
    condition = alltrue([
      for setting in var.diagnostic_settings :
      alltrue([
        for metric in setting.metrics :
        !try(metric.enabled, true) || length(metric.category) > 0
      ])
    ])
    error_message = "Each enabled metric must specify a non-empty category."
  }
}
