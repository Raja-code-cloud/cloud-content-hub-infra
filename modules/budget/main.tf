# ------------------------------------------------------------------------------
# Budget Module
#
# Creates Azure Cost Management Budgets at subscription or resource group scope.
# Does NOT create action groups, alerts, policies, or other Azure resources.
# See: modules/budget/README.md
# ------------------------------------------------------------------------------

resource "azurerm_consumption_budget_subscription" "this" {
  for_each = local.subscription_budgets

  name            = each.value.name
  subscription_id = local.subscription_ids[each.key]
  amount          = each.value.amount
  time_grain      = each.value.time_grain

  time_period {
    start_date = local.normalized_start_dates[each.key]
    end_date   = local.normalized_end_dates[each.key]
  }

  dynamic "filter" {
    for_each = try(each.value.filter, null) != null ? [each.value.filter] : []
    content {
      dynamic "dimension" {
        for_each = try(filter.value.dimensions, [])
        content {
          name     = dimension.value.name
          operator = try(dimension.value.operator, null)
          values   = dimension.value.values
        }
      }

      dynamic "tag" {
        for_each = try(filter.value.tags, [])
        content {
          name     = tag.value.name
          operator = try(tag.value.operator, null)
          values   = tag.value.values
        }
      }
    }
  }

  dynamic "notification" {
    for_each = local.budget_notifications[each.key]
    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = notification.value.threshold_type
      contact_emails = length(notification.value.contact_emails) > 0 ? notification.value.contact_emails : null
      contact_groups = length(notification.value.contact_groups) > 0 ? notification.value.contact_groups : null
      contact_roles  = length(notification.value.contact_roles) > 0 ? notification.value.contact_roles : null
    }
  }
}

resource "azurerm_consumption_budget_resource_group" "this" {
  for_each = local.resource_group_budgets

  name              = each.value.name
  resource_group_id = each.value.scope
  amount            = each.value.amount
  time_grain        = each.value.time_grain

  time_period {
    start_date = local.normalized_start_dates[each.key]
    end_date   = local.normalized_end_dates[each.key]
  }

  dynamic "filter" {
    for_each = try(each.value.filter, null) != null ? [each.value.filter] : []
    content {
      dynamic "dimension" {
        for_each = try(filter.value.dimensions, [])
        content {
          name     = dimension.value.name
          operator = try(dimension.value.operator, null)
          values   = dimension.value.values
        }
      }

      dynamic "tag" {
        for_each = try(filter.value.tags, [])
        content {
          name     = tag.value.name
          operator = try(tag.value.operator, null)
          values   = tag.value.values
        }
      }
    }
  }

  dynamic "notification" {
    for_each = local.budget_notifications[each.key]
    content {
      enabled        = notification.value.enabled
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = notification.value.threshold_type
      contact_emails = length(notification.value.contact_emails) > 0 ? notification.value.contact_emails : null
      contact_groups = length(notification.value.contact_groups) > 0 ? notification.value.contact_groups : null
      contact_roles  = length(notification.value.contact_roles) > 0 ? notification.value.contact_roles : null
    }
  }
}
