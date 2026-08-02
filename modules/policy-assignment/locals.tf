# ------------------------------------------------------------------------------
# Policy Assignment Module — Locals
# ------------------------------------------------------------------------------

locals {
  assignments = {
    for assignment in var.assignments : assignment.key => assignment
  }

  scope_types = {
    for key, assignment in local.assignments :
    key => (
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+$", assignment.scope)) ? "management_group" :
      can(regex("^/subscriptions/[0-9a-f-]{36}$", assignment.scope)) ? "subscription" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", assignment.scope)) ? "resource_group" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", assignment.scope)) ? "resource" :
      "invalid"
    )
  }

  management_group_assignments = {
    for key, assignment in local.assignments :
    key => assignment if local.scope_types[key] == "management_group"
  }

  subscription_assignments = {
    for key, assignment in local.assignments :
    key => assignment if local.scope_types[key] == "subscription"
  }

  resource_group_assignments = {
    for key, assignment in local.assignments :
    key => assignment if local.scope_types[key] == "resource_group"
  }

  resource_assignments = {
    for key, assignment in local.assignments :
    key => assignment if local.scope_types[key] == "resource"
  }

  enforce_values = {
    for key, assignment in local.assignments :
    key => (
      try(assignment.enforcement_mode, null) == null ? null :
      assignment.enforcement_mode == "Default" ? true :
      false
    )
  }

  parameters_json = {
    for key, assignment in local.assignments :
    key => (
      try(assignment.parameters, null) == null ? null :
      jsonencode({
        for param_key, param_value in assignment.parameters :
        param_key => (
          try(param_value.value, null) != null ? param_value : { value = param_value }
        )
      })
    )
  }

  all_assignments = merge(
    azurerm_management_group_policy_assignment.this,
    azurerm_subscription_policy_assignment.this,
    azurerm_resource_group_policy_assignment.this,
    azurerm_resource_policy_assignment.this,
  )
}
