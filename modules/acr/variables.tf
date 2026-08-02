# ------------------------------------------------------------------------------
# Azure Container Registry Module — Variables
# ------------------------------------------------------------------------------

variable "registry_name" {
  description = "Globally unique name of the Azure Container Registry. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9]{5,50}$", var.registry_name))
    error_message = "registry_name must be 5-50 alphanumeric characters (ACR names cannot contain hyphens)."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the registry is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Container Registry."
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

variable "sku" {
  description = "SKU tier for the Container Registry. Basic is suitable for low-cost dev workloads."
  type        = string
  nullable    = false
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "When true, enables the admin user account. Not recommended for production — use managed identity instead."
  type        = bool
  nullable    = false
  default     = false
}

variable "public_network_access_enabled" {
  description = "When true, allows access to the registry over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "zone_redundancy_enabled" {
  description = "When true, enables zone redundancy. Requires Premium SKU."
  type        = bool
  nullable    = false
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "When true, allows anonymous (unauthenticated) pull access. Requires Standard or Premium SKU."
  type        = bool
  nullable    = false
  default     = false
}

variable "tags" {
  description = "Tags applied to the registry. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
