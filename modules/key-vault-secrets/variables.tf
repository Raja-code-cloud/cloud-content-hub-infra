# ------------------------------------------------------------------------------
# Key Vault Secrets Module — Variables
# ------------------------------------------------------------------------------

variable "key_vault_id" {
  description = "Resource ID of the existing Key Vault. This module does not create the Key Vault."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.KeyVault/vaults/[\\w\\(\\)\\.-]+$", var.key_vault_id))
    error_message = "key_vault_id must be a valid Key Vault resource ID."
  }
}

variable "secrets" {
  description = "List of secrets to manage in the Key Vault. Values are sensitive and stored in Terraform state."
  type = list(object({
    key             = string
    name            = string
    value           = string
    content_type    = optional(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
    tags            = optional(map(string), {})
    enabled         = optional(bool, true)
  }))
  nullable  = false
  default   = []
  sensitive = true

  validation {
    condition     = length(distinct([for secret in var.secrets : secret.key])) == length(var.secrets)
    error_message = "Each secret key must be unique."
  }

  validation {
    condition = length(distinct([
      for secret in var.secrets : secret.name if try(secret.enabled, true)
    ])) == length([for secret in var.secrets : secret.name if try(secret.enabled, true)])
    error_message = "Each enabled secret name must be unique within the Key Vault."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", secret.key))
    ])
    error_message = "Each secret key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      can(regex("^[a-zA-Z0-9-]{1,127}$", secret.name))
    ])
    error_message = "Each secret name must be 1-127 alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      !try(secret.enabled, true) || length(secret.value) > 0
    ])
    error_message = "Each enabled secret must have a non-empty value."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      try(secret.expiration_date, null) == null ||
      can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", secret.expiration_date))
    ])
    error_message = "expiration_date must be in RFC3339 UTC format (e.g. 2026-12-31T23:59:59Z)."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      try(secret.not_before_date, null) == null ||
      can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", secret.not_before_date))
    ])
    error_message = "not_before_date must be in RFC3339 UTC format (e.g. 2026-01-01T00:00:00Z)."
  }

  validation {
    condition = alltrue([
      for secret in var.secrets :
      try(secret.not_before_date, null) == null ||
      try(secret.expiration_date, null) == null ||
      secret.not_before_date < secret.expiration_date
    ])
    error_message = "not_before_date must be earlier than expiration_date when both are specified."
  }
}
