# ------------------------------------------------------------------------------
# Networking Module — Locals
# ------------------------------------------------------------------------------

locals {
  subnets = {
    for subnet in var.subnets : subnet.key => subnet
  }

  network_security_groups = {
    for nsg in var.network_security_groups : nsg.key => nsg
  }

  subnet_nsg_associations = {
    for key, subnet in local.subnets : key => subnet
    if try(subnet.nsg_id, null) != null || try(subnet.nsg_key, null) != null
  }

  subnet_nsg_ids = {
    for key, subnet in local.subnet_nsg_associations : key => (
      try(subnet.nsg_id, null) != null ? subnet.nsg_id : azurerm_network_security_group.this[subnet.nsg_key].id
    )
  }
}
