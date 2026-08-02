# ------------------------------------------------------------------------------
# Budget Module — Locals
# ------------------------------------------------------------------------------

locals {
  budgets = {
    for budget in var.budgets : budget.key => budget
  }

  scope_types = {
    for key, budget in local.budgets : key => (
      can(regex("^/subscriptions/[0-9a-f-]{36}$", budget.scope)) ? "subscription" : "resource_group"
    )
  }

  subscription_budgets = {
    for key, budget in local.budgets : key => budget
    if local.scope_types[key] == "subscription"
  }

  resource_group_budgets = {
    for key, budget in local.budgets : key => budget
    if local.scope_types[key] == "resource_group"
  }

  subscription_ids = {
    for key, budget in local.subscription_budgets : key => (
      can(regex("^/subscriptions/", budget.scope)) ?
      regex("^/subscriptions/([0-9a-f-]{36})$", budget.scope)[0] :
      budget.scope
    )
  }

  normalized_start_dates = {
    for key, budget in local.budgets : key => (
      can(regex("T", budget.start_date)) ? budget.start_date : "${budget.start_date}T00:00:00Z"
    )
  }

  normalized_end_dates = {
    for key, budget in local.budgets : key => (
      try(budget.end_date, null) != null ? (
        can(regex("T", budget.end_date)) ? budget.end_date : "${budget.end_date}T00:00:00Z"
      ) : null
    )
  }

  budget_notifications = {
    for key, budget in local.budgets : key => [
      for notification in budget.notifications : {
        threshold      = notification.threshold
        operator       = notification.operator
        threshold_type = try(notification.threshold_type, "Actual")
        contact_emails = try(notification.contact_emails, [])
        contact_groups = try(notification.contact_groups, [])
        contact_roles  = try(notification.contact_roles, [])
        enabled        = try(notification.enabled, true)
      }
    ]
  }
}
