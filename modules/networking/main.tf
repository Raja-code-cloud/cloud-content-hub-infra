# ------------------------------------------------------------------------------
# Networking Module
#
# Creates Virtual Network, Subnets, optional NSGs, and subnet associations.
# Does NOT create private endpoints, DNS zones, NAT, firewall, VPN, or route tables.
# See: modules/networking/README.md
# ------------------------------------------------------------------------------

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_network_security_group" "this" {
  for_each = local.network_security_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, try(each.value.tags, {}))

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])
    content {
      name                         = security_rule.value.name
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = try(security_rule.value.source_port_range, null)
      destination_port_range       = try(security_rule.value.destination_port_range, null)
      source_port_ranges           = try(security_rule.value.source_port_ranges, null)
      destination_port_ranges      = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix        = try(security_rule.value.source_address_prefix, null)
      destination_address_prefix   = try(security_rule.value.destination_address_prefix, null)
      source_address_prefixes      = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefixes = try(security_rule.value.destination_address_prefixes, null)
      description                  = try(security_rule.value.description, null)
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  service_endpoint_policy_ids                   = length(try(each.value.service_endpoint_policy_ids, [])) > 0 ? each.value.service_endpoint_policy_ids : null
  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, null)
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, null)

  dynamic "service_endpoint" {
    for_each = try(each.value.service_endpoints, [])
    content {
      service = service_endpoint.value
    }
  }

  dynamic "delegation" {
    for_each = try(each.value.delegations, [])
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnet_nsg_associations

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = local.subnet_nsg_ids[each.key]
}
