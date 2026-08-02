# ------------------------------------------------------------------------------
# Log Analytics Module — Variables
# ------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group where the Log Analytics Workspace is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Log Analytics Workspace."
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

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition = (
      length(var.workspace_name) >= 4 && length(var.workspace_name) <= 63 && (
        can(regex("^[A-Za-z0-9]{4}$", var.workspace_name)) ||
        can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.workspace_name))
      )
    )
    error_message = "workspace_name must be 4-63 characters, alphanumeric and hyphens only, and cannot start or end with a hyphen."
  }
}

variable "sku" {
  description = "Log Analytics Workspace SKU. PerGB2018 is recommended for pay-as-you-go workloads."
  type        = string
  nullable    = false
  default     = "PerGB2018"

  validation {
    condition = contains([
      "Free",
      "PerNode",
      "Premium",
      "Standard",
      "Standalone",
      "Unlimited",
      "CapacityReservation",
      "PerGB2018",
    ], var.sku)
    error_message = "sku must be a supported Log Analytics Workspace SKU."
  }
}

variable "retention_in_days" {
  description = "Data retention in days. Free SKU requires 7. Paid SKUs support 30-730."
  type        = number
  nullable    = false
  default     = 30

  validation {
    condition     = var.retention_in_days >= 7 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 7 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB. Use -1 for unlimited (Azure default). Set a positive value to cap ingestion cost."
  type        = number
  nullable    = false
  default     = 1

  validation {
    condition     = var.daily_quota_gb == -1 || (var.daily_quota_gb >= 0.1 && var.daily_quota_gb <= 1000)
    error_message = "daily_quota_gb must be -1 (unlimited) or between 0.1 and 1000."
  }
}

variable "internet_ingestion_enabled" {
  description = "When true, allows ingestion of data from public internet sources."
  type        = bool
  nullable    = false
  default     = true
}

variable "internet_query_enabled" {
  description = "When true, allows querying workspace data over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "tags" {
  description = "Tags applied to the workspace. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
