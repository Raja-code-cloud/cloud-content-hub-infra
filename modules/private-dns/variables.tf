# ------------------------------------------------------------------------------
# Private DNS Module — Variables
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group where private DNS zones and virtual network links are created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 valid Azure resource group name characters."
  }
}

variable "tags" {
  description = "Tags applied to all private DNS zones and virtual network links created by this module."
  type        = map(string)
  default     = {}
}

variable "private_dns_zones" {
  description = "List of Azure Private DNS zones to create. Zone name is used as the stable for_each identifier."
  type = list(object({
    name                 = string
    registration_enabled = optional(bool, false)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for zone in var.private_dns_zones : zone.name])) == length(var.private_dns_zones)
    error_message = "Each private DNS zone name must be unique."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones :
      length(zone.name) >= 1 && length(zone.name) <= 255
    ])
    error_message = "Each private DNS zone name must be between 1 and 255 characters."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones :
      can(regex("^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$", zone.name))
    ])
    error_message = "Each private DNS zone name must be a valid DNS domain name."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones :
      length(split(".", zone.name)) >= 2
    ])
    error_message = "Each private DNS zone name must contain at least two labels (e.g. privatelink.blob.core.windows.net)."
  }

  validation {
    condition = alltrue([
      for zone in var.private_dns_zones :
      !can(regex("\\.$", zone.name))
    ])
    error_message = "Private DNS zone names must not end with a trailing dot."
  }
}

variable "virtual_network_links" {
  description = "List of virtual network links to associate existing VNets with private DNS zones. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                  = string
    zone_name            = string
    link_name            = string
    vnet_id              = string
    registration_enabled = optional(bool, false)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for link in var.virtual_network_links : link.key])) == length(var.virtual_network_links)
    error_message = "Each virtual network link key must be unique."
  }

  validation {
    condition = length(distinct([
      for link in var.virtual_network_links : "${link.zone_name}/${link.link_name}"
    ])) == length(var.virtual_network_links)
    error_message = "Each zone_name and link_name combination must be unique."
  }

  validation {
    condition = alltrue([
      for link in var.virtual_network_links :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", link.key))
    ])
    error_message = "Each virtual network link key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for link in var.virtual_network_links :
      contains([for zone in var.private_dns_zones : zone.name], link.zone_name)
    ])
    error_message = "Each virtual network link zone_name must reference a private DNS zone defined in private_dns_zones."
  }

  validation {
    condition = alltrue([
      for link in var.virtual_network_links :
      can(regex("^[\\w\\(\\)\\.-]{1,80}$", link.link_name))
    ])
    error_message = "Each link_name must be 1-80 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for link in var.virtual_network_links :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Network/virtualNetworks/[\\w\\(\\)\\.-]+$", link.vnet_id))
    ])
    error_message = "Each vnet_id must be a valid Azure Virtual Network resource ID."
  }
}
