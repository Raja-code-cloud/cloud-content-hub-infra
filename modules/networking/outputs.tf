# ------------------------------------------------------------------------------
# Networking Module — Outputs
# ------------------------------------------------------------------------------

output "vnet_id" {
  description = "The Azure Resource Manager ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet keys to subnet resource IDs."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "subnet_names" {
  description = "Map of subnet keys to subnet names."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.name }
}

output "subnets" {
  description = "Non-sensitive subnet metadata for downstream module composition."
  value = {
    for key, subnet in azurerm_subnet.this :
    key => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
      resource_id      = subnet.id
    }
  }
}

output "network_security_group_ids" {
  description = "Map of NSG keys to Network Security Group resource IDs created by this module."
  value       = { for key, nsg in azurerm_network_security_group.this : key => nsg.id }
}

output "network_security_group_names" {
  description = "Map of NSG keys to Network Security Group names created by this module."
  value       = { for key, nsg in azurerm_network_security_group.this : key => nsg.name }
}
