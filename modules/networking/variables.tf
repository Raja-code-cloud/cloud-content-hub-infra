# ------------------------------------------------------------------------------
# Networking Module — Variables
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where networking resources are created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for networking resources."
  type        = string
  nullable    = false

  validation {
    condition = contains([
      "eastus", "eastus2", "centralus", "westus2", "westus3",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "swedencentral", "francecentral", "germanywestcentral",
      "australiaeast", "southeastasia", "japaneast", "brazilsouth",
    ], var.location)
    error_message = "location must be a supported Azure region."
  }
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,64}$", var.vnet_name))
    error_message = "vnet_name must be 1-64 characters with valid Azure virtual network name characters."
  }
}

variable "address_space" {
  description = "Address space for the Virtual Network as a list of CIDR blocks."
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR block."
  }

  validation {
    condition = alltrue([
      for cidr in var.address_space :
      can(cidrhost(cidr, 0))
    ])
    error_message = "Each address_space entry must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = length(distinct(var.address_space)) == length(var.address_space)
    error_message = "address_space entries must be unique."
  }

  validation {
    condition = length(var.address_space) < 2 || alltrue([
      for i, left in var.address_space :
      alltrue([
        for j, right in var.address_space :
        i >= j || !(cidrcontains(left, cidrhost(right, 0)) && cidrcontains(right, cidrhost(left, 0)))
      ])
    ])
    error_message = "address_space entries must not overlap."
  }
}

variable "tags" {
  description = "Tags applied to all networking resources created by this module."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "subnets" {
  description = "Subnets to create within the Virtual Network. Each entry requires a stable key for for_each identity."
  type = list(object({
    key                                           = string
    name                                          = string
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    service_endpoint_policy_ids                   = optional(list(string), [])
    private_endpoint_network_policies             = optional(string)
    private_link_service_network_policies_enabled = optional(bool)
    nsg_id                                        = optional(string)
    nsg_key                                       = optional(string)
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for subnet in var.subnets : subnet.key])) == length(var.subnets)
    error_message = "Each subnet key must be unique."
  }

  validation {
    condition     = length(distinct([for subnet in var.subnets : subnet.name])) == length(var.subnets)
    error_message = "Each subnet name must be unique within the Virtual Network."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", subnet.key))
    ])
    error_message = "Each subnet key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      can(regex("^[\\w\\(\\)\\.-]{1,80}$", subnet.name))
    ])
    error_message = "Each subnet name must be 1-80 valid Azure subnet name characters."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      length(subnet.address_prefixes) > 0
    ])
    error_message = "Each subnet must specify at least one address prefix."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      alltrue([for prefix in subnet.address_prefixes : can(cidrhost(prefix, 0))])
    ])
    error_message = "Each subnet address_prefix must be a valid IPv4 CIDR block."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      try(subnet.nsg_id, null) == null || try(subnet.nsg_key, null) == null
    ])
    error_message = "Specify only one of nsg_id or nsg_key per subnet, not both."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      try(subnet.nsg_id, null) == null ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Network/networkSecurityGroups/[\\w\\(\\)\\.-]+$", subnet.nsg_id))
    ])
    error_message = "nsg_id must be a valid Network Security Group resource ID when specified."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      alltrue([
        for endpoint in try(subnet.service_endpoints, []) :
        can(regex("^Microsoft\\.[A-Za-z0-9.]+$", endpoint))
      ])
    ])
    error_message = "service_endpoints must use Microsoft.<Service> format (e.g. Microsoft.Storage, Microsoft.Storage.Global)."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      alltrue([
        for prefix in subnet.address_prefixes :
        anytrue([
          for vnet_cidr in var.address_space :
          cidrcontains(vnet_cidr, cidrhost(prefix, 0))
        ])
      ])
    ])
    error_message = "Each subnet address prefix must fall within the virtual network address space."
  }

  validation {
    condition     = length(flatten([for subnet in var.subnets : subnet.address_prefixes])) == length(distinct(flatten([for subnet in var.subnets : subnet.address_prefixes])))
    error_message = "Subnet address prefixes must be unique across all subnets."
  }

  validation {
    condition = alltrue([
      for i, left in flatten([for subnet in var.subnets : subnet.address_prefixes]) :
      alltrue([
        for j, right in flatten([for subnet in var.subnets : subnet.address_prefixes]) :
        i >= j || !(cidrcontains(left, cidrhost(right, 0)) && cidrcontains(right, cidrhost(left, 0)))
      ])
    ])
    error_message = "Subnet address prefixes must not overlap."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      alltrue([
        for delegation in try(subnet.delegations, []) :
        can(regex("^Microsoft\\.[A-Za-z0-9]+/[A-Za-z0-9]+$", delegation.service_delegation.name))
      ])
    ])
    error_message = "delegation service_delegation.name must use Microsoft.<Provider>/<ResourceType> format."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      try(subnet.nsg_key, null) == null ||
      contains([for nsg in var.network_security_groups : nsg.key], subnet.nsg_key)
    ])
    error_message = "subnet nsg_key must reference a key defined in network_security_groups."
  }

  validation {
    condition = alltrue([
      for subnet in var.subnets :
      try(subnet.private_endpoint_network_policies, null) == null ||
      contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], subnet.private_endpoint_network_policies)
    ])
    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }
}

variable "network_security_groups" {
  description = "Optional Network Security Groups to create and associate via subnet nsg_key."
  type = list(object({
    key  = string
    name = string
    tags = optional(map(string), {})
    security_rules = optional(list(object({
      name                         = string
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string)
      destination_port_range       = optional(string)
      source_port_ranges           = optional(list(string))
      destination_port_ranges      = optional(list(string))
      source_address_prefix        = optional(string)
      destination_address_prefix   = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefixes = optional(list(string))
      description                  = optional(string)
    })), [])
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for nsg in var.network_security_groups : nsg.key])) == length(var.network_security_groups)
    error_message = "Each network security group key must be unique."
  }

  validation {
    condition = alltrue([
      for nsg in var.network_security_groups :
      can(regex("^[\\w\\(\\)\\.-]{1,80}$", nsg.name))
    ])
    error_message = "Each NSG name must be 1-80 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for nsg in var.network_security_groups :
      length(distinct([for rule in try(nsg.security_rules, []) : rule.priority])) == length(try(nsg.security_rules, []))
    ])
    error_message = "NSG security rule priorities must be unique within each NSG."
  }

  validation {
    condition = alltrue([
      for nsg in var.network_security_groups :
      alltrue([
        for rule in try(nsg.security_rules, []) :
        rule.priority >= 100 && rule.priority <= 4096
      ])
    ])
    error_message = "NSG security rule priority must be between 100 and 4096."
  }

  validation {
    condition = alltrue([
      for nsg in var.network_security_groups :
      alltrue([
        for rule in try(nsg.security_rules, []) :
        contains(["Inbound", "Outbound"], rule.direction)
      ])
    ])
    error_message = "NSG security rule direction must be Inbound or Outbound."
  }

  validation {
    condition = alltrue([
      for nsg in var.network_security_groups :
      alltrue([
        for rule in try(nsg.security_rules, []) :
        contains(["Allow", "Deny"], rule.access)
      ])
    ])
    error_message = "NSG security rule access must be Allow or Deny."
  }
}
