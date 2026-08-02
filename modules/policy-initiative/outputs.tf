# ------------------------------------------------------------------------------
# Policy Initiative Module — Outputs
# ------------------------------------------------------------------------------

output "initiative_ids" {
  description = "Map of initiative keys to Azure Policy Initiative resource IDs."
  value       = { for key, initiative in local.all_initiatives : key => initiative.id }
}

output "initiative_names" {
  description = "Map of initiative keys to Azure Policy Initiative resource names."
  value       = { for key, initiative in local.all_initiatives : key => initiative.name }
}

output "policy_definition_counts" {
  description = "Map of initiative keys to the number of referenced policy definitions."
  value = {
    for key, initiative in local.initiatives :
    key => length(initiative.policy_definitions)
  }
}

output "policy_definition_references" {
  description = "Map of initiative keys to referenced policy definition metadata."
  value = {
    for key, initiative in local.initiatives :
    key => [
      for policy_definition in initiative.policy_definitions : {
        policy_definition_id = policy_definition.policy_definition_id
        reference_id         = try(policy_definition.reference_id, null)
        group_names          = try(policy_definition.group_names, null)
        version              = try(policy_definition.version, null)
      }
    ]
  }
}

output "initiatives" {
  description = "Non-sensitive initiative metadata for downstream module composition."
  value = {
    for key, initiative in local.all_initiatives :
    key => {
      id                  = initiative.id
      name                = initiative.name
      display_name        = initiative.display_name
      description         = initiative.description
      management_group_id = try(local.initiatives[key].management_group_id, null)
      policy_type         = initiative.policy_type
      policy_group_count  = length(coalesce(try(local.initiatives[key].policy_groups, null), []))
      policy_count        = length(local.initiatives[key].policy_definitions)
    }
  }
}
