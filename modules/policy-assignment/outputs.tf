# ------------------------------------------------------------------------------
# Policy Assignment Module — Outputs
# ------------------------------------------------------------------------------

output "assignment_ids" {
  description = "Map of assignment keys to Azure Policy Assignment resource IDs."
  value       = { for key, assignment in local.all_assignments : key => assignment.id }
}

output "assignment_names" {
  description = "Map of assignment keys to Azure Policy Assignment resource names."
  value       = { for key, assignment in local.all_assignments : key => assignment.name }
}

output "policy_definition_ids" {
  description = "Map of assignment keys to assigned policy or initiative definition IDs."
  value       = { for key, assignment in local.all_assignments : key => assignment.policy_definition_id }
}

output "scopes" {
  description = "Map of assignment keys to assignment scopes."
  value       = { for key, assignment in local.all_assignments : key => local.assignments[key].scope }
}

output "identity_principal_ids" {
  description = "Map of assignment keys to managed identity principal IDs when an identity is configured."
  value = {
    for key, assignment in local.all_assignments :
    key => try(assignment.identity[0].principal_id, null)
  }
}

output "assignments" {
  description = "Non-sensitive policy assignment metadata for downstream module composition."
  value = {
    for key, assignment in local.all_assignments :
    key => {
      id                    = assignment.id
      name                  = assignment.name
      display_name          = assignment.display_name
      description           = assignment.description
      scope                 = local.assignments[key].scope
      scope_type            = local.scope_types[key]
      policy_definition_id  = assignment.policy_definition_id
      enforcement_mode      = try(local.assignments[key].enforcement_mode, null)
      location              = assignment.location
      identity_principal_id = try(assignment.identity[0].principal_id, null)
      identity_tenant_id    = try(assignment.identity[0].tenant_id, null)
    }
  }
}
