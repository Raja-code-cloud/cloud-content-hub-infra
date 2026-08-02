# ------------------------------------------------------------------------------
# Private Endpoint Module — Outputs
# ------------------------------------------------------------------------------

output "private_endpoint_ids" {
  description = "Map of private endpoint keys to Azure Resource Manager IDs."
  value       = { for key, endpoint in azurerm_private_endpoint.this : key => endpoint.id }
}

output "private_endpoint_names" {
  description = "Map of private endpoint keys to private endpoint names."
  value       = { for key, endpoint in azurerm_private_endpoint.this : key => endpoint.name }
}

output "network_interface_ids" {
  description = "Map of private endpoint keys to private endpoint network interface IDs."
  value = {
    for key, endpoint in azurerm_private_endpoint.this :
    key => try(endpoint.network_interface[0].id, null)
  }
}

output "network_interface_names" {
  description = "Map of private endpoint keys to private endpoint network interface names."
  value = {
    for key, endpoint in azurerm_private_endpoint.this :
    key => try(endpoint.network_interface[0].name, null)
  }
}

output "private_ip_addresses" {
  description = "Map of private endpoint keys to allocated private IP addresses."
  value = {
    for key, endpoint in azurerm_private_endpoint.this :
    key => try(endpoint.network_interface[0].private_ip_address, null)
  }
}

output "target_resource_ids" {
  description = "Map of private endpoint keys to target Private Link resource IDs."
  value       = { for key, endpoint in local.private_endpoints : key => endpoint.target_resource_id }
}

output "private_endpoints" {
  description = "Non-sensitive private endpoint metadata for downstream module composition."
  value = {
    for key, endpoint in azurerm_private_endpoint.this :
    key => {
      id                     = endpoint.id
      name                   = endpoint.name
      location               = endpoint.location
      resource_group_name    = endpoint.resource_group_name
      subnet_id              = endpoint.subnet_id
      target_resource_id     = local.private_endpoints[key].target_resource_id
      subresource_names      = local.private_endpoints[key].subresource_names
      network_interface_id   = try(endpoint.network_interface[0].id, null)
      network_interface_name = try(endpoint.network_interface[0].name, null)
      private_ip_address     = try(endpoint.network_interface[0].private_ip_address, null)
      is_manual_connection   = local.private_endpoints[key].is_manual_connection
      private_dns_zone_group = local.private_endpoints[key].private_dns_zone_group
    }
  }
}
