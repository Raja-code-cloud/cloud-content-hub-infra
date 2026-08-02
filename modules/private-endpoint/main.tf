# ------------------------------------------------------------------------------
# Private Endpoint Module
#
# Creates Azure Private Endpoints for existing Private Link-enabled resources.
# Does NOT create virtual networks, subnets, private DNS zones, DNS records,
# or target Azure resources.
# See: modules/private-endpoint/README.md
# ------------------------------------------------------------------------------

resource "azurerm_private_endpoint" "this" {
  for_each = local.private_endpoints

  name                          = each.value.private_endpoint_name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = each.value.custom_network_interface_name
  tags                          = length(each.value.tags) > 0 ? each.value.tags : null

  private_service_connection {
    name                           = each.value.private_service_connection_name
    private_connection_resource_id = each.value.target_resource_id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = each.value.is_manual_connection
    request_message                = each.value.is_manual_connection ? each.value.request_message : null
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_group != null ? [each.value.private_dns_zone_group] : []

    content {
      name                 = private_dns_zone_group.value.name
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }
}

check "network_interface_name_aliases_are_consistent" {
  assert {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.network_interface_name, null) == null ||
      try(endpoint.custom_network_interface_name, null) == null ||
      endpoint.network_interface_name == endpoint.custom_network_interface_name
    ])
    error_message = "network_interface_name and custom_network_interface_name must match when both are specified."
  }
}

check "manual_connection_request_message_length" {
  assert {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      !try(endpoint.is_manual_connection, false) ||
      try(endpoint.request_message, null) == null ||
      length(endpoint.request_message) <= 140
    ])
    error_message = "request_message must be 140 characters or fewer when is_manual_connection is true."
  }
}
