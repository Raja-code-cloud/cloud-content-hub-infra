# ------------------------------------------------------------------------------
# Role Assignment Module — Outputs
# ------------------------------------------------------------------------------

output "assignment_ids" {
  description = "Map of assignment keys to Azure role assignment resource IDs."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.id }
}

output "principal_ids" {
  description = "Map of assignment keys to principal object IDs."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.principal_id }
}

output "scopes" {
  description = "Map of assignment keys to assignment scopes."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.scope }
}

output "role_names" {
  description = "Map of assignment keys to resolved role definition names."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.role_definition_name }
}

output "role_definition_ids" {
  description = "Map of assignment keys to resolved role definition IDs."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.role_definition_id }
}

output "assignments" {
  description = "Non-sensitive role assignment metadata for downstream module composition."
  value = {
    for key, assignment in azurerm_role_assignment.this :
    key => {
      id                   = assignment.id
      name                 = assignment.name
      principal_id         = assignment.principal_id
      principal_type       = assignment.principal_type
      scope                = assignment.scope
      role_definition_name = assignment.role_definition_name
      role_definition_id   = assignment.role_definition_id
      description          = assignment.description
    }
  }
}
