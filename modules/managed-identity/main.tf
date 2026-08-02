# ------------------------------------------------------------------------------
# User Assigned Managed Identity Module
#
# Creates exactly one Azure User Assigned Managed Identity.
# Does NOT create role assignments, federated credentials, or access policies.
# See: modules/managed-identity/README.md
# ------------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "this" {
  name                = var.identity_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
