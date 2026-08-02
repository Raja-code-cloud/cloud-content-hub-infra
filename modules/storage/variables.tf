# ------------------------------------------------------------------------------
# Storage Account Module — Variables
# ------------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Globally unique name of the Storage Account. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Storage Account is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Storage Account."
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

variable "account_tier" {
  description = "Storage account tier. Standard for general-purpose workloads; Premium for high-performance scenarios."
  type        = string
  nullable    = false
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "account_tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage replication strategy. LRS is the lowest-cost option for non-production workloads."
  type        = string
  nullable    = false
  default     = "LRS"

  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS",
    ], var.account_replication_type)
    error_message = "account_replication_type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "account_kind" {
  description = "Storage account kind. StorageV2 is recommended for general-purpose blob, file, queue, and table storage."
  type        = string
  nullable    = false
  default     = "StorageV2"

  validation {
    condition = contains([
      "Storage", "StorageV2", "BlobStorage", "BlockBlobStorage", "FileStorage",
    ], var.account_kind)
    error_message = "account_kind must be Storage, StorageV2, BlobStorage, BlockBlobStorage, or FileStorage."
  }
}

variable "access_tier" {
  description = "Default blob access tier for StorageV2 and BlobStorage accounts."
  type        = string
  nullable    = false
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "min_tls_version" {
  description = "Minimum TLS version for HTTPS requests to the storage account."
  type        = string
  nullable    = false
  default     = "TLS1_2"

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], var.min_tls_version)
    error_message = "min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "https_traffic_only_enabled" {
  description = "When true, requires secure transfer (HTTPS) for all requests."
  type        = bool
  nullable    = false
  default     = true
}

variable "allow_blob_public_access" {
  description = "When true, allows nested blob containers to permit anonymous public access."
  type        = bool
  nullable    = false
  default     = false
}

variable "shared_access_key_enabled" {
  description = "When true, allows authenticated access via shared access keys."
  type        = bool
  nullable    = false
  default     = true
}

variable "public_network_access_enabled" {
  description = "When true, allows access to the storage account over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "When true, enables infrastructure encryption for data at rest (double encryption)."
  type        = bool
  nullable    = false
  default     = false
}

variable "tags" {
  description = "Tags applied to the Storage Account. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}

variable "network_rules" {
  description = "Optional network rules restricting storage account access. Recommended when private endpoints are enabled."
  type = object({
    default_action             = optional(string, "Deny")
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  nullable = true
  default  = null

  validation {
    condition = (
      var.network_rules == null ||
      contains(["Allow", "Deny"], var.network_rules.default_action)
    )
    error_message = "network_rules.default_action must be Allow or Deny."
  }
}
