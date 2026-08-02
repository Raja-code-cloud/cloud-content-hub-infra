# ------------------------------------------------------------------------------
# Policy Exemption Module — Outputs
# ------------------------------------------------------------------------------

output "exemption_ids" {
  description = "Map of exemption keys to Azure Policy Exemption resource IDs."
  value       = { for key, exemption in local.all_exemptions : key => exemption.id }
}

output "exemption_names" {
  description = "Map of exemption keys to exemption resource names."
  value       = { for key, exemption in local.all_exemptions : key => exemption.name }
}

output "scopes" {
  description = "Map of exemption keys to exemption scopes."
  value       = { for key, exemption in local.exemptions : key => exemption.scope }
}

output "policy_assignment_ids" {
  description = "Map of exemption keys to parent policy assignment resource IDs."
  value       = { for key, exemption in local.all_exemptions : key => exemption.policy_assignment_id }
}

output "expiration_dates" {
  description = "Map of exemption keys to normalized expiration dates (null when not set)."
  value       = { for key, exemption in local.all_exemptions : key => try(exemption.expires_on, null) }
}

output "exemptions" {
  description = "Non-sensitive exemption metadata for downstream module composition."
  value = {
    for key, exemption in local.all_exemptions :
    key => {
      id                              = exemption.id
      name                            = exemption.name
      display_name                    = exemption.display_name
      description                     = exemption.description
      scope                           = local.exemptions[key].scope
      scope_type                      = local.scope_types[key]
      policy_assignment_id            = exemption.policy_assignment_id
      exemption_category              = exemption.exemption_category
      expires_on                      = try(exemption.expires_on, null)
      policy_definition_reference_ids = try(local.exemptions[key].policy_definition_reference_ids, [])
      resource_id                     = exemption.id
    }
  }
}
