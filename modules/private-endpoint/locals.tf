# ------------------------------------------------------------------------------
# Private Endpoint Module — Locals
# ------------------------------------------------------------------------------

locals {
  private_endpoints = {
    for endpoint in var.private_endpoints : endpoint.key => {
      private_endpoint_name           = endpoint.private_endpoint_name
      resource_group_name             = endpoint.resource_group_name
      location                        = endpoint.location
      subnet_id                       = endpoint.subnet_id
      target_resource_id              = endpoint.target_resource_id
      subresource_names               = endpoint.subresource_names
      private_dns_zone_group          = try(endpoint.private_dns_zone_group, null)
      custom_network_interface_name   = coalesce(try(endpoint.custom_network_interface_name, null), try(endpoint.network_interface_name, null))
      private_service_connection_name = coalesce(try(endpoint.private_service_connection_name, null), "${endpoint.private_endpoint_name}-psc")
      is_manual_connection            = try(endpoint.is_manual_connection, false)
      request_message                 = try(endpoint.request_message, null)
      tags                            = merge(var.tags, try(endpoint.tags, {}))
    }
    if try(endpoint.enabled, true)
  }
}
