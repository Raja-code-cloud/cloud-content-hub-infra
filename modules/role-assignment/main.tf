# ------------------------------------------------------------------------------
# Role Assignment Module
#
# Creates Azure RBAC role assignments only.
# Does NOT create role definitions, identities, groups, users, or policies.
# See: modules/role-assignment/README.md
# ------------------------------------------------------------------------------

resource "azurerm_role_assignment" "this" {
  for_each = local.assignments

  scope                            = each.value.scope
  role_definition_name             = try(each.value.role_definition_name, null)
  role_definition_id               = try(each.value.role_definition_id, null)
  principal_id                     = each.value.principal_id
  principal_type                   = try(each.value.principal_type, null)
  description                      = try(each.value.description, null)
  condition                        = try(each.value.condition, null)
  condition_version                = try(each.value.condition_version, null)
  skip_service_principal_aad_check = try(each.value.skip_service_principal_aad_check, false)
}
