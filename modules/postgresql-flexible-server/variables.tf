# ------------------------------------------------------------------------------
# PostgreSQL Flexible Server Module — Variables
# ------------------------------------------------------------------------------

variable "server_name" {
  description = "Name of the PostgreSQL Flexible Server. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.server_name) >= 3 && length(var.server_name) <= 63 && (
        can(regex("^[a-z0-9]{3,63}$", var.server_name)) ||
        can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.server_name))
      )
    )
    error_message = "server_name must be 3-63 lowercase alphanumeric characters or hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the PostgreSQL Flexible Server is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the PostgreSQL Flexible Server."
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

variable "administrator_login" {
  description = "Administrator login username for the PostgreSQL Flexible Server."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(regex("^[a-zA-Z][a-zA-Z0-9]{0,62}$", var.administrator_login)) &&
      !contains(["azure_superuser", "admin", "administrator", "root", "guest", "public"], lower(var.administrator_login))
    )
    error_message = "administrator_login must start with a letter, contain only alphanumeric characters, and cannot be a reserved name."
  }
}

variable "administrator_password" {
  description = "Administrator password. Supply via tfvars, Key Vault, or CI secrets — never hardcode in source."
  type        = string
  nullable    = false
  sensitive   = true

  validation {
    condition     = length(var.administrator_password) >= 8 && length(var.administrator_password) <= 128
    error_message = "administrator_password must be between 8 and 128 characters."
  }
}

variable "sku_name" {
  description = "SKU name for the PostgreSQL Flexible Server (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)."
  type        = string
  nullable    = false
  default     = "B_Standard_B1ms"

  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_[A-Za-z0-9]+$", var.sku_name))
    error_message = "sku_name must match the pattern (B|GP|MO)_Standard_<size>."
  }
}

variable "storage_mb" {
  description = "Storage size in megabytes. Minimum 32768 (32 GB)."
  type        = number
  nullable    = false
  default     = 32768

  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "storage_mb must be between 32768 and 16777216."
  }
}

variable "postgresql_version" {
  description = "PostgreSQL major version."
  type        = string
  nullable    = false
  default     = "16"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.postgresql_version)
    error_message = "postgresql_version must be one of: 11, 12, 13, 14, 15, 16."
  }
}

variable "backup_retention_days" {
  description = "Backup retention period in days."
  type        = number
  nullable    = false
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "When true, enables geo-redundant backup storage."
  type        = bool
  nullable    = false
  default     = false
}

variable "zone" {
  description = "Availability zone for the server (1, 2, or 3). Null for no zone preference."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.zone == null || contains(["1", "2", "3"], var.zone)
    error_message = "zone must be null or one of: 1, 2, 3."
  }
}

variable "high_availability_mode" {
  description = "High availability mode. Disabled, SameZone, or ZoneRedundant."
  type        = string
  nullable    = false
  default     = "Disabled"

  validation {
    condition     = contains(["Disabled", "SameZone", "ZoneRedundant"], var.high_availability_mode)
    error_message = "high_availability_mode must be Disabled, SameZone, or ZoneRedundant."
  }
}

variable "public_network_access_enabled" {
  description = "When true, allows public network access to the server."
  type        = bool
  nullable    = false
  default     = true
}

variable "delegated_subnet_id" {
  description = "Optional subnet ID for VNet-integrated deployment. Requires private_dns_zone_id when set."
  type        = string
  nullable    = true
  default     = null
}

variable "private_dns_zone_id" {
  description = "Optional private DNS zone ID for VNet-integrated deployment."
  type        = string
  nullable    = true
  default     = null
}

variable "tags" {
  description = "Tags applied to the PostgreSQL Flexible Server. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
