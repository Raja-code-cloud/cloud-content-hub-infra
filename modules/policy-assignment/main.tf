# ------------------------------------------------------------------------------
# Policy Assignment Module
#
# Creates Azure Policy Assignments only.
# Does NOT create policy definitions, initiatives, exemptions, management groups,
# subscriptions, or other Azure resources.
# See: modules/policy-assignment/README.md
# ------------------------------------------------------------------------------

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = local.management_group_assignments

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  management_group_id  = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  enforce              = try(local.enforce_values[each.key], null)
  location             = try(each.value.location, null)
  parameters           = try(local.parameters_json[each.key], null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = coalesce(try(each.value.non_compliance_messages, null), [])

    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = local.subscription_assignments

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  subscription_id      = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  enforce              = try(local.enforce_values[each.key], null)
  location             = try(each.value.location, null)
  parameters           = try(local.parameters_json[each.key], null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = coalesce(try(each.value.non_compliance_messages, null), [])

    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}

resource "azurerm_resource_group_policy_assignment" "this" {
  for_each = local.resource_group_assignments

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  resource_group_id    = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  enforce              = try(local.enforce_values[each.key], null)
  location             = try(each.value.location, null)
  parameters           = try(local.parameters_json[each.key], null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = coalesce(try(each.value.non_compliance_messages, null), [])

    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}

resource "azurerm_resource_policy_assignment" "this" {
  for_each = local.resource_assignments

  name                 = each.value.name
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  resource_id          = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  enforce              = try(local.enforce_values[each.key], null)
  location             = try(each.value.location, null)
  parameters           = try(local.parameters_json[each.key], null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = coalesce(try(each.value.non_compliance_messages, null), [])

    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}
