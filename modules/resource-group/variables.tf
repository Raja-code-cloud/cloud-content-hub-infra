# ------------------------------------------------------------------------------
# Resource Group Module — Variables
# ------------------------------------------------------------------------------

variable "name" {
  description = "Name of the Azure Resource Group. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.name))
    error_message = "name must be 1-90 characters and contain only alphanumeric characters, underscores, parentheses, hyphens, and periods."
  }
}

variable "location" {
  description = "Azure region where the resource group is created."
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
  description = "Tags applied to the resource group. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}

variable "create_resource_lock" {
  description = "When true, creates an Azure Management Lock on the resource group."
  type        = bool
  nullable    = false
  default     = false
}

variable "lock_level" {
  description = "Management lock level applied when create_resource_lock is true. Supported values: CanNotDelete, ReadOnly."
  type        = string
  nullable    = false
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "lock_level must be CanNotDelete or ReadOnly."
  }
}

variable "lock_name" {
  description = "Optional name for the management lock. Defaults to <resource-group-name>-lock when null."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.lock_name == null || can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.lock_name))
    error_message = "lock_name must be null or 1-90 characters with valid Azure name characters."
  }
}

variable "lock_notes" {
  description = "Optional notes recorded on the management lock."
  type        = string
  nullable    = false
  default     = "Managed by Terraform — prevents accidental deletion of platform resources."
}
