# ------------------------------------------------------------------------------
# Azure Container Registry Module
#
# Creates exactly one Azure Container Registry.
# Does NOT create role assignments, private endpoints, or diagnostic settings.
# See: modules/acr/README.md
# ------------------------------------------------------------------------------

resource "azurerm_container_registry" "this" {
  name                          = var.registry_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  anonymous_pull_enabled        = var.anonymous_pull_enabled
  tags                          = var.tags
}

check "zone_redundancy_requires_premium" {
  assert {
    condition     = !var.zone_redundancy_enabled || local.premium_sku
    error_message = "zone_redundancy_enabled requires Premium SKU."
  }
}

check "anonymous_pull_requires_standard_or_premium" {
  assert {
    condition     = !var.anonymous_pull_enabled || contains(["Standard", "Premium"], var.sku)
    error_message = "anonymous_pull_enabled requires Standard or Premium SKU."
  }
}
