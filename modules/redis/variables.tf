# ------------------------------------------------------------------------------
# Azure Cache for Redis Module — Variables
# ------------------------------------------------------------------------------

variable "redis_cache_name" {
  description = "Name of the Azure Cache for Redis instance. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.redis_cache_name)) && length(var.redis_cache_name) >= 1 && length(var.redis_cache_name) <= 63
    error_message = "redis_cache_name must be 1-63 lowercase alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Redis cache is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Redis cache."
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
  description = "Redis SKU. Basic/Standard for non-private workloads; Premium required for private endpoints and VNet injection."
  type        = string
  nullable    = false
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "sku_name must be Basic, Standard, or Premium."
  }
}

variable "family" {
  description = "Redis SKU family. C for Basic/Standard; P for Premium."
  type        = string
  nullable    = false
  default     = "C"

  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "family must be C or P."
  }
}

variable "capacity" {
  description = "Redis cache size within the selected SKU family."
  type        = number
  nullable    = false
  default     = 0

  validation {
    condition     = var.capacity >= 0 && var.capacity <= 6
    error_message = "capacity must be between 0 and 6."
  }
}

variable "minimum_tls_version" {
  description = "Minimum TLS version accepted by the Redis cache."
  type        = string
  nullable    = false
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "minimum_tls_version must be 1.0, 1.1, or 1.2."
  }
}

variable "non_ssl_port_enabled" {
  description = "When true, enables the non-TLS Redis port (6379). Keep false for production workloads."
  type        = bool
  nullable    = false
  default     = false
}

variable "public_network_access_enabled" {
  description = "When false, Redis accepts only private network access (Premium SKU with private endpoint recommended)."
  type        = bool
  nullable    = false
  default     = true
}

variable "redis_version" {
  description = "Major Redis version."
  type        = string
  nullable    = false
  default     = "6"

  validation {
    condition     = contains(["4", "6"], var.redis_version)
    error_message = "redis_version must be 4 or 6."
  }
}

variable "redis_configuration" {
  description = "Optional Redis configuration overrides."
  type = object({
    maxmemory_policy   = optional(string)
    maxmemory_reserved = optional(number)
    maxmemory_delta    = optional(number)
  })
  nullable = true
  default  = null
}

variable "tags" {
  description = "Tags applied to the Redis cache. Pass merged tags from modules/common."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
