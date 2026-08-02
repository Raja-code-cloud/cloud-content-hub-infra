# ------------------------------------------------------------------------------
# Policy Initiative Module — Locals
# ------------------------------------------------------------------------------

locals {
  initiatives = {
    for initiative in var.initiatives : initiative.key => initiative
  }

  subscription_initiatives = {
    for key, initiative in local.initiatives :
    key => initiative if try(initiative.management_group_id, null) == null
  }

  management_group_initiatives = {
    for key, initiative in local.initiatives :
    key => initiative if try(initiative.management_group_id, null) != null
  }

  parameters_json = {
    for key, initiative in local.initiatives :
    key => (
      try(initiative.parameters, null) == null ? null :
      jsonencode(initiative.parameters)
    )
  }

  metadata_json = {
    for key, initiative in local.initiatives :
    key => (
      try(initiative.metadata, null) == null ? null :
      jsonencode(initiative.metadata)
    )
  }

  policy_definition_references = {
    for key, initiative in local.initiatives :
    key => [
      for policy_definition in initiative.policy_definitions : {
        policy_definition_id = policy_definition.policy_definition_id
        reference_id         = try(policy_definition.reference_id, null)
        parameter_values = (
          try(policy_definition.parameters, null) == null ? null :
          jsonencode({
            for param_key, param_value in policy_definition.parameters :
            param_key => (
              try(param_value.value, null) != null ? param_value : { value = param_value }
            )
          })
        )
        policy_group_names = try(policy_definition.group_names, null)
        version            = try(policy_definition.version, null)
      }
    ]
  }

  all_initiatives = merge(
    azurerm_policy_set_definition.this,
    azurerm_management_group_policy_set_definition.this,
  )
}
