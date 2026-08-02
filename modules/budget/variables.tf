# ------------------------------------------------------------------------------
# Budget Module — Variables
# ------------------------------------------------------------------------------

variable "budgets" {
  description = "Azure Cost Management budgets. Each entry requires a stable key for for_each identity. Scope must be a subscription or resource group resource ID."
  type = list(object({
    key        = string
    name       = string
    scope      = string
    amount     = number
    time_grain = string
    start_date = string
    end_date   = optional(string)
    tags       = optional(map(string), {})
    filter = optional(object({
      dimensions = optional(list(object({
        name     = string
        operator = optional(string)
        values   = list(string)
      })), [])
      tags = optional(list(object({
        name     = string
        operator = optional(string)
        values   = list(string)
      })), [])
    }))
    notifications = list(object({
      threshold      = number
      operator       = string
      threshold_type = optional(string, "Actual")
      contact_emails = optional(list(string), [])
      contact_groups = optional(list(string), [])
      contact_roles  = optional(list(string), [])
      enabled        = optional(bool, true)
    }))
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for budget in var.budgets : budget.key])) == length(var.budgets)
    error_message = "Each budget key must be unique."
  }

  validation {
    condition     = length(distinct([for budget in var.budgets : budget.name])) == length(var.budgets)
    error_message = "Each budget name must be unique."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", budget.key))
    ])
    error_message = "Each budget key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      length(budget.name) >= 1 && length(budget.name) <= 63
    ])
    error_message = "Each budget name must be between 1 and 63 characters."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      budget.amount > 0
    ])
    error_message = "Each budget amount must be greater than zero."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      contains(["Monthly", "Quarterly", "Annually"], budget.time_grain)
    ])
    error_message = "time_grain must be Monthly, Quarterly, or Annually."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      can(regex("^/subscriptions/[0-9a-f-]{36}$", budget.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", budget.scope))
    ])
    error_message = "scope must be a subscription ID (/subscriptions/{guid}) or resource group ID (/subscriptions/{guid}/resourceGroups/{name})."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      can(regex("^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z|[0-9]{4}-[0-9]{2}-[0-9]{2})$", budget.start_date))
    ])
    error_message = "start_date must be ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ)."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      try(budget.end_date, null) == null ||
      can(regex("^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z|[0-9]{4}-[0-9]{2}-[0-9]{2})$", budget.end_date))
    ])
    error_message = "end_date must be ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ) when specified."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      length(budget.notifications) > 0
    ])
    error_message = "Each budget must define at least one notification."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        notification.threshold > 0 && notification.threshold <= 1000
      ])
    ])
    error_message = "Notification threshold must be between 0 (exclusive) and 1000 (inclusive) percent."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        contains(["EqualTo", "GreaterThan", "GreaterThanOrEqualTo"], notification.operator)
      ])
    ])
    error_message = "Notification operator must be EqualTo, GreaterThan, or GreaterThanOrEqualTo."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        contains(["Actual", "Forecasted"], try(notification.threshold_type, "Actual"))
      ])
    ])
    error_message = "Notification threshold_type must be Actual or Forecasted."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        !try(notification.enabled, true) ||
        length(try(notification.contact_emails, [])) > 0 ||
        length(try(notification.contact_groups, [])) > 0 ||
        length(try(notification.contact_roles, [])) > 0
      ])
    ])
    error_message = "Each enabled notification must specify at least one of contact_emails, contact_groups, or contact_roles."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        alltrue([
          for email in try(notification.contact_emails, []) :
          can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
        ])
      ])
    ])
    error_message = "Each contact_emails entry must be a valid email address format."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        alltrue([
          for group_id in try(notification.contact_groups, []) :
          can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Insights/actionGroups/[\\w\\(\\)\\.-]+$", group_id))
        ])
      ])
    ])
    error_message = "Each contact_groups entry must be a valid Azure Monitor Action Group resource ID."
  }

  validation {
    condition = alltrue([
      for budget in var.budgets :
      alltrue([
        for notification in budget.notifications :
        alltrue([
          for role in try(notification.contact_roles, []) :
          contains(["Owner", "Contributor", "Reader"], role)
        ])
      ])
    ])
    error_message = "Each contact_roles entry must be Owner, Contributor, or Reader."
  }
}
