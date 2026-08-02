# ------------------------------------------------------------------------------
# Policy Exemption Module
#
# Creates Azure Policy Exemptions only.
# Does NOT create policy definitions, initiatives, assignments, or other resources.
# See: modules/policy-exemption/README.md
# ------------------------------------------------------------------------------

resource "azurerm_management_group_policy_exemption" "this" {
  for_each = local.management_group_exemptions

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  management_group_id  = each.value.scope
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  expires_on           = local.normalized_expires_on[each.key]
  metadata             = local.metadata_json[each.key]

  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = local.subscription_exemptions

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  subscription_id      = each.value.scope
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  expires_on           = local.normalized_expires_on[each.key]
  metadata             = local.metadata_json[each.key]

  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = local.resource_group_exemptions

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  resource_group_id    = each.value.scope
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  expires_on           = local.normalized_expires_on[each.key]
  metadata             = local.metadata_json[each.key]

  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_resource_policy_exemption" "this" {
  for_each = local.resource_exemptions

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  resource_id          = each.value.scope
  policy_assignment_id = each.value.policy_assignment_id
  exemption_category   = each.value.exemption_category
  expires_on           = local.normalized_expires_on[each.key]
  metadata             = local.metadata_json[each.key]

  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}
