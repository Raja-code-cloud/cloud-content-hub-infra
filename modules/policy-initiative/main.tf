# ------------------------------------------------------------------------------
# Policy Initiative Module
#
# Creates Azure Policy Initiatives (Policy Set Definitions) only.
# Does NOT create policy definitions, assignments, exemptions, management groups,
# subscriptions, or other Azure resources.
# See: modules/policy-initiative/README.md
# ------------------------------------------------------------------------------

resource "azurerm_policy_set_definition" "this" {
  for_each = local.subscription_initiatives

  name         = each.value.name
  display_name = each.value.display_name
  description  = try(each.value.description, null)
  policy_type  = each.value.policy_type
  metadata     = try(local.metadata_json[each.key], null)
  parameters   = try(local.parameters_json[each.key], null)

  dynamic "policy_definition_reference" {
    for_each = local.policy_definition_references[each.key]

    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.value.reference_id
      parameter_values     = policy_definition_reference.value.parameter_values
      policy_group_names   = policy_definition_reference.value.policy_group_names
      version              = policy_definition_reference.value.version
    }
  }

  dynamic "policy_definition_group" {
    for_each = coalesce(try(each.value.policy_groups, null), [])

    content {
      name                            = policy_definition_group.value.name
      display_name                    = try(policy_definition_group.value.display_name, null)
      description                     = try(policy_definition_group.value.description, null)
      category                        = try(policy_definition_group.value.category, null)
      additional_metadata_resource_id = try(policy_definition_group.value.additional_metadata_resource_id, null)
    }
  }
}

resource "azurerm_management_group_policy_set_definition" "this" {
  for_each = local.management_group_initiatives

  name                = each.value.name
  display_name        = each.value.display_name
  description         = try(each.value.description, null)
  management_group_id = each.value.management_group_id
  policy_type         = each.value.policy_type
  metadata            = try(local.metadata_json[each.key], null)
  parameters          = try(local.parameters_json[each.key], null)

  dynamic "policy_definition_reference" {
    for_each = local.policy_definition_references[each.key]

    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.value.reference_id
      parameter_values     = policy_definition_reference.value.parameter_values
      policy_group_names   = policy_definition_reference.value.policy_group_names
      version              = policy_definition_reference.value.version
    }
  }

  dynamic "policy_definition_group" {
    for_each = coalesce(try(each.value.policy_groups, null), [])

    content {
      name                            = policy_definition_group.value.name
      display_name                    = try(policy_definition_group.value.display_name, null)
      description                     = try(policy_definition_group.value.description, null)
      category                        = try(policy_definition_group.value.category, null)
      additional_metadata_resource_id = try(policy_definition_group.value.additional_metadata_resource_id, null)
    }
  }
}
