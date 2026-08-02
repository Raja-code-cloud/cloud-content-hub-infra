# ------------------------------------------------------------------------------
# Private DNS Module
#
# Creates Azure Private DNS zones and virtual network links.
# Does NOT create private endpoints, DNS records, public DNS zones, or DNS forwarders.
# See: modules/private-dns/README.md
# ------------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "this" {
  for_each = local.private_dns_zones

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  tags                = each.value.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.virtual_network_links

  name                 = each.value.name
  private_dns_zone_id  = each.value.private_dns_zone_id
  virtual_network_id   = each.value.virtual_network_id
  registration_enabled = each.value.registration_enabled
  tags                 = each.value.tags
}
