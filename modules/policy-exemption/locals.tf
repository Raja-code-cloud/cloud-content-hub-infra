# ------------------------------------------------------------------------------
# Policy Exemption Module — Locals
# ------------------------------------------------------------------------------

locals {
  exemptions = {
    for exemption in var.exemptions : exemption.key => exemption
  }

  scope_types = {
    for key, exemption in local.exemptions :
    key => (
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+$", exemption.scope)) ? "management_group" :
      can(regex("^/subscriptions/[0-9a-f-]{36}$", exemption.scope)) ? "subscription" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", exemption.scope)) ? "resource_group" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", exemption.scope)) ? "resource" :
      "invalid"
    )
  }

  management_group_exemptions = {
    for key, exemption in local.exemptions :
    key => exemption if local.scope_types[key] == "management_group"
  }

  subscription_exemptions = {
    for key, exemption in local.exemptions :
    key => exemption if local.scope_types[key] == "subscription"
  }

  resource_group_exemptions = {
    for key, exemption in local.exemptions :
    key => exemption if local.scope_types[key] == "resource_group"
  }

  resource_exemptions = {
    for key, exemption in local.exemptions :
    key => exemption if local.scope_types[key] == "resource"
  }

  normalized_expires_on = {
    for key, exemption in local.exemptions : key => (
      try(exemption.expires_on, null) != null ? (
        can(regex("T", exemption.expires_on)) ? exemption.expires_on : "${exemption.expires_on}T23:59:59Z"
      ) : null
    )
  }

  metadata_json = {
    for key, exemption in local.exemptions : key => (
      try(exemption.metadata, null) != null ? jsonencode(exemption.metadata) : null
    )
  }

  all_exemptions = merge(
    azurerm_management_group_policy_exemption.this,
    azurerm_subscription_policy_exemption.this,
    azurerm_resource_group_policy_exemption.this,
    azurerm_resource_policy_exemption.this,
  )
}
