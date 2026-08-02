# ------------------------------------------------------------------------------
# Resource Group Module
#
# Creates exactly one Azure Resource Group with an optional management lock.
# See: modules/resource-group/README.md
# ------------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

resource "azurerm_management_lock" "this" {
  count = var.create_resource_lock ? 1 : 0

  name       = local.lock_name
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock_level
  notes      = var.lock_notes
}
