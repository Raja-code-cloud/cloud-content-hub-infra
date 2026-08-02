# ------------------------------------------------------------------------------
# Storage Containers Module — Variables
# ------------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Name of the existing Storage Account. This module does not create the Storage Account."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "storage_account_id" {
  description = "Resource ID of the existing Storage Account. Required by azurerm v5 for container binding."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Storage/storageAccounts/[a-z0-9]{3,24}$", var.storage_account_id))
    error_message = "storage_account_id must be a valid Storage Account resource ID."
  }

  validation {
    condition     = endswith(var.storage_account_id, "/storageAccounts/${var.storage_account_name}")
    error_message = "storage_account_id must reference the supplied storage_account_name."
  }
}

variable "primary_blob_endpoint" {
  description = "Primary blob endpoint from the storage account module. When omitted, container URLs use the public Azure cloud naming convention."
  type        = string
  default     = null

  validation {
    condition = (
      var.primary_blob_endpoint == null ||
      can(regex("^https://.+/$", var.primary_blob_endpoint))
    )
    error_message = "primary_blob_endpoint must be a valid HTTPS blob endpoint ending with a trailing slash."
  }
}

variable "tags" {
  description = "Tags merged into each container metadata map. Blob containers do not support Azure Resource Manager tags directly."
  type        = map(string)
  default     = {}
}

variable "containers" {
  description = "List of blob containers to create in the existing Storage Account. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key                   = string
    name                  = string
    container_access_type = optional(string, "private")
    metadata              = optional(map(string), {})
    immutability_policy = optional(object({
      immutability_period_in_days   = number
      state                         = string
      allow_protected_append_writes = optional(bool, false)
    }))
    legal_hold = optional(bool)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for container in var.containers : container.key])) == length(var.containers)
    error_message = "Each container key must be unique."
  }

  validation {
    condition = length(distinct([
      for container in var.containers : container.name
    ])) == length(var.containers)
    error_message = "Each container name must be unique within the Storage Account."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", container.key))
    ])
    error_message = "Each container key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      can(regex("^[a-z0-9]([a-z0-9-]{1,61}[a-z0-9])?$", container.name))
    ])
    error_message = "Each container name must be 3-63 lowercase letters, numbers, or hyphens, and cannot start or end with a hyphen."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      !can(regex("--", container.name))
    ])
    error_message = "Container names cannot contain consecutive hyphens."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      contains(["private", "blob", "container"], try(container.container_access_type, "private"))
    ])
    error_message = "container_access_type must be private, blob, or container."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      alltrue([
        for metadata_key in keys(try(container.metadata, {})) :
        can(regex("^[a-zA-Z0-9_-]+$", metadata_key))
      ])
    ])
    error_message = "Each metadata key must contain only alphanumeric characters, underscores, or hyphens."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      try(container.immutability_policy, null) == null ||
      contains(["Locked", "Unlocked"], container.immutability_policy.state)
    ])
    error_message = "immutability_policy.state must be Locked or Unlocked when specified."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      try(container.immutability_policy, null) == null ||
      (
        container.immutability_policy.immutability_period_in_days >= 1 &&
        container.immutability_policy.immutability_period_in_days <= 146000
      )
    ])
    error_message = "immutability_policy.immutability_period_in_days must be between 1 and 146000 when specified."
  }
}
