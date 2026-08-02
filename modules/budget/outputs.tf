# ------------------------------------------------------------------------------
# Budget Module — Outputs
# ------------------------------------------------------------------------------

output "budget_ids" {
  description = "Map of budget keys to Azure Cost Management budget resource IDs."
  value = merge(
    { for key, budget in azurerm_consumption_budget_subscription.this : key => budget.id },
    { for key, budget in azurerm_consumption_budget_resource_group.this : key => budget.id },
  )
}

output "budget_names" {
  description = "Map of budget keys to budget names."
  value = merge(
    { for key, budget in azurerm_consumption_budget_subscription.this : key => budget.name },
    { for key, budget in azurerm_consumption_budget_resource_group.this : key => budget.name },
  )
}

output "budget_amounts" {
  description = "Map of budget keys to budget amounts."
  value = merge(
    { for key, budget in azurerm_consumption_budget_subscription.this : key => budget.amount },
    { for key, budget in azurerm_consumption_budget_resource_group.this : key => budget.amount },
  )
}

output "budget_scopes" {
  description = "Map of budget keys to scope resource IDs (subscription or resource group)."
  value = {
    for key, budget in local.budgets : key => budget.scope
  }
}

output "budget_scope" {
  description = "Map of budget keys to scope resource IDs (alias for budget_scopes)."
  value = {
    for key, budget in local.budgets : key => budget.scope
  }
}

output "budget_scope_types" {
  description = "Map of budget keys to scope type (subscription or resource_group)."
  value       = local.scope_types
}

output "budgets" {
  description = "Non-sensitive budget metadata for downstream module composition."
  value = {
    for key, budget in local.budgets :
    key => {
      id          = try(azurerm_consumption_budget_subscription.this[key].id, azurerm_consumption_budget_resource_group.this[key].id)
      name        = budget.name
      scope       = budget.scope
      scope_type  = local.scope_types[key]
      amount      = budget.amount
      time_grain  = budget.time_grain
      start_date  = local.normalized_start_dates[key]
      end_date    = local.normalized_end_dates[key]
      tags        = try(budget.tags, {})
      resource_id = try(azurerm_consumption_budget_subscription.this[key].id, azurerm_consumption_budget_resource_group.this[key].id)
    }
  }
}
