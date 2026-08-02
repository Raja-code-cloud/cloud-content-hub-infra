# ------------------------------------------------------------------------------
# Resource Lock Module
#
# Creates Azure Management Locks on existing scopes.
# Does NOT create Azure resources, policies, RBAC assignments, or budgets.
# See: modules/resource-lock/README.md
# ------------------------------------------------------------------------------

resource "azurerm_management_lock" "this" {
  for_each = local.locks

  name       = each.value.name
  scope      = each.value.scope
  lock_level = each.value.lock_level
  notes      = each.value.notes
}
