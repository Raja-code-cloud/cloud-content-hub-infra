# ------------------------------------------------------------------------------
# Key Vault Module — Variables
# ------------------------------------------------------------------------------

variable "vault_name" {
  description = "Name of the Azure Key Vault. Must be globally unique and supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.vault_name) >= 3 && length(var.vault_name) <= 24 && (
        can(regex("^[A-Za-z0-9]{3,24}$", var.vault_name)) ||
        can(regex("^[A-Za-z][A-Za-z0-9-]{1,22}[A-Za-z0-9]$", var.vault_name))
      )
    )
    error_message = "vault_name must be 3-24 characters, alphanumeric and hyphens only, start with a letter, and end with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Key Vault is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Key Vault."
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

variable "sku_name" {
  description = "SKU name for the Key Vault. Standard is recommended for most workloads."
  type        = string
  nullable    = false
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "enable_rbac_authorization" {
  description = "When true, uses Azure RBAC for data plane authorization instead of vault access policies."
  type        = bool
  nullable    = false
  default     = true
}

variable "purge_protection_enabled" {
  description = "When true, prevents permanent deletion during the retention period after soft delete."
  type        = bool
  nullable    = false
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults and objects (7-90)."
  type        = number
  nullable    = false
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "public_network_access_enabled" {
  description = "When true, allows access to the Key Vault over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "enabled_for_deployment" {
  description = "When true, allows Azure Virtual Machines to retrieve certificates stored as secrets."
  type        = bool
  nullable    = false
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "When true, allows Azure Disk Encryption to retrieve secrets and keys."
  type        = bool
  nullable    = false
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "When true, allows Azure Resource Manager to retrieve secrets during template deployments."
  type        = bool
  nullable    = false
  default     = false
}

variable "tags" {
  description = "Tags applied to the Key Vault. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
