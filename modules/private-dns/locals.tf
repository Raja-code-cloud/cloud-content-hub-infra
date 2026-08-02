# ------------------------------------------------------------------------------
# Private DNS Module — Locals
# ------------------------------------------------------------------------------

locals {
  private_dns_zones = {
    for zone in var.private_dns_zones : zone.name => {
      name                = zone.name
      resource_group_name = var.resource_group_name
      tags                = var.tags
    }
  }

  virtual_network_links = {
    for link in var.virtual_network_links : link.key => {
      name                 = link.link_name
      private_dns_zone_id  = azurerm_private_dns_zone.this[link.zone_name].id
      virtual_network_id   = link.vnet_id
      registration_enabled = try(link.registration_enabled, false)
      tags                 = var.tags
    }
  }
}
