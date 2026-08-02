# ------------------------------------------------------------------------------
# Private DNS Module — Outputs
# ------------------------------------------------------------------------------

output "zone_ids" {
  description = "Map of private DNS zone names to Azure Private DNS zone resource IDs."
  value       = { for name, zone in azurerm_private_dns_zone.this : name => zone.id }
}

output "zone_names" {
  description = "Map of private DNS zone names to zone FQDNs."
  value       = { for name, zone in azurerm_private_dns_zone.this : name => zone.name }
}

output "virtual_network_link_ids" {
  description = "Map of virtual network link keys to Azure Private DNS virtual network link resource IDs."
  value       = { for key, link in azurerm_private_dns_zone_virtual_network_link.this : key => link.id }
}

output "private_dns_zones" {
  description = "Non-sensitive private DNS zone metadata for downstream module composition."
  value = {
    for name, zone in azurerm_private_dns_zone.this :
    name => {
      id                                                    = zone.id
      name                                                  = zone.name
      resource_group_name                                   = zone.resource_group_name
      number_of_record_sets                                 = zone.number_of_record_sets
      max_number_of_record_sets                             = zone.max_number_of_record_sets
      max_number_of_virtual_network_links                   = zone.max_number_of_virtual_network_links
      max_number_of_virtual_network_links_with_registration = zone.max_number_of_virtual_network_links_with_registration
    }
  }
}

output "virtual_network_links" {
  description = "Non-sensitive virtual network link metadata for downstream module composition."
  value = {
    for key, link in azurerm_private_dns_zone_virtual_network_link.this :
    key => {
      id                    = link.id
      name                  = link.name
      private_dns_zone_name = link.private_dns_zone_name
      virtual_network_id    = link.virtual_network_id
      registration_enabled  = link.registration_enabled
      resource_group_name   = link.resource_group_name
    }
  }
}
