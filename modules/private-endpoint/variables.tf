# ------------------------------------------------------------------------------
# Private Endpoint Module — Variables
# ------------------------------------------------------------------------------

variable "private_endpoints" {
  description = "List of Azure Private Endpoints to create. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                   = string
    private_endpoint_name = string
    resource_group_name   = string
    location              = string
    subnet_id             = string
    target_resource_id    = string
    subresource_names     = list(string)
    private_dns_zone_group = optional(object({
      name                 = string
      private_dns_zone_ids = list(string)
    }))
    network_interface_name          = optional(string)
    custom_network_interface_name   = optional(string)
    private_service_connection_name = optional(string)
    is_manual_connection            = optional(bool, false)
    request_message                 = optional(string)
    tags                            = optional(map(string), {})
    enabled                         = optional(bool, true)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for endpoint in var.private_endpoints : endpoint.key])) == length(var.private_endpoints)
    error_message = "Each private endpoint key must be unique."
  }

  validation {
    condition     = length(distinct([for endpoint in var.private_endpoints : endpoint.private_endpoint_name if try(endpoint.enabled, true)])) == length([for endpoint in var.private_endpoints : endpoint if try(endpoint.enabled, true)])
    error_message = "Each enabled private_endpoint_name must be unique."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", endpoint.key))
    ])
    error_message = "Each private endpoint key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9_]$", endpoint.private_endpoint_name)) ||
      can(regex("^[a-zA-Z0-9]{1,80}$", endpoint.private_endpoint_name))
    ])
    error_message = "Each private_endpoint_name must be 1-80 valid Azure private endpoint name characters."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      can(regex("^[\\w\\(\\)\\.-]{1,90}$", endpoint.resource_group_name))
    ])
    error_message = "Each resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      contains([
        "eastus", "eastus2", "centralus", "westus2", "westus3",
        "northeurope", "westeurope", "uksouth", "ukwest",
        "swedencentral", "francecentral", "germanywestcentral",
        "australiaeast", "southeastasia", "japaneast", "brazilsouth",
      ], endpoint.location)
    ])
    error_message = "Each location must be a supported Azure region."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      can(
        regex(
          "^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Network/virtualNetworks/[\\w\\(\\)\\.-]+/subnets/[\\w\\(\\)\\.-]+$",
          endpoint.subnet_id,
        )
      )
    ])
    error_message = "Each subnet_id must be a valid Azure subnet resource ID."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      can(
        regex(
          "^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$",
          endpoint.target_resource_id,
        )
      )
    ])
    error_message = "Each target_resource_id must be a valid Azure resource ID."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      length(endpoint.subresource_names) > 0
    ])
    error_message = "Each private endpoint must specify at least one subresource name."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      length(distinct(endpoint.subresource_names)) == length(endpoint.subresource_names)
    ])
    error_message = "Each subresource_names list must not contain duplicate values."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      alltrue([
        for subresource_name in endpoint.subresource_names :
        can(regex("^[a-zA-Z][a-zA-Z0-9_-]{0,62}$", subresource_name))
      ])
    ])
    error_message = "Each subresource name must start with a letter and contain only alphanumeric characters, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.private_dns_zone_group, null) == null ||
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9_]$", endpoint.private_dns_zone_group.name)) ||
      can(regex("^[a-zA-Z0-9]{1,80}$", endpoint.private_dns_zone_group.name))
    ])
    error_message = "Each private_dns_zone_group.name must be 1-80 valid Azure name characters when specified."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.private_dns_zone_group, null) == null ||
      length(endpoint.private_dns_zone_group.private_dns_zone_ids) > 0
    ])
    error_message = "Each private_dns_zone_group must include at least one private_dns_zone_id when specified."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.private_dns_zone_group, null) == null ||
      alltrue([
        for zone_id in endpoint.private_dns_zone_group.private_dns_zone_ids :
        can(
          regex(
            "^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Network/privateDnsZones/[\\w\\.-]+$",
            zone_id,
          )
        )
      ])
    ])
    error_message = "Each private_dns_zone_id must be a valid Azure Private DNS Zone resource ID."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.private_dns_zone_group, null) == null ||
      length(distinct(endpoint.private_dns_zone_group.private_dns_zone_ids)) == length(endpoint.private_dns_zone_group.private_dns_zone_ids)
    ])
    error_message = "Each private_dns_zone_group.private_dns_zone_ids list must not contain duplicate values."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.network_interface_name, null) == null ||
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9_]$", endpoint.network_interface_name)) ||
      can(regex("^[a-zA-Z0-9]{1,80}$", endpoint.network_interface_name))
    ])
    error_message = "Each network_interface_name must be 1-80 valid Azure network interface name characters when specified."
  }

  validation {
    condition = alltrue([
      for endpoint in var.private_endpoints :
      try(endpoint.custom_network_interface_name, null) == null ||
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9_]$", endpoint.custom_network_interface_name)) ||
      can(regex("^[a-zA-Z0-9]{1,80}$", endpoint.custom_network_interface_name))
    ])
    error_message = "Each custom_network_interface_name must be 1-80 valid Azure network interface name characters when specified."
  }
}

variable "tags" {
  description = "Default tags applied to all private endpoints. Merged with optional per-endpoint tags."
  type        = map(string)
  nullable    = false
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(key) >= 1 && length(key) <= 512 && length(value) <= 256
    ])
    error_message = "Each tag key must be 1-512 characters and each value must be 1-256 characters."
  }
}
