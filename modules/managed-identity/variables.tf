# ------------------------------------------------------------------------------
# Managed Identity Module — Variables
# ------------------------------------------------------------------------------

variable "identity_name" {
  description = "Name of the User Assigned Managed Identity. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.identity_name) >= 3 && length(var.identity_name) <= 128 && (
        can(regex("^[A-Za-z0-9]{3,128}$", var.identity_name)) ||
        can(regex("^[A-Za-z0-9][A-Za-z0-9-]{1,126}[A-Za-z0-9]$", var.identity_name))
      )
    )
    error_message = "identity_name must be 3-128 characters, alphanumeric and hyphens only, and cannot start or end with a hyphen."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the User Assigned Managed Identity is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the User Assigned Managed Identity."
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

variable "tags" {
  description = "Tags applied to the managed identity. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
