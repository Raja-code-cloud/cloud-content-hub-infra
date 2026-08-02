# ------------------------------------------------------------------------------
# PostgreSQL Configuration Module — Variables
# ------------------------------------------------------------------------------

variable "server_id" {
  description = "Resource ID of the existing PostgreSQL Flexible Server. This module does not create the server."
  type        = string
  nullable    = false

  validation {
    condition = can(
      regex(
        "^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.DBforPostgreSQL/flexibleServers/[a-z0-9-]+$",
        var.server_id,
      )
    )
    error_message = "server_id must be a valid PostgreSQL Flexible Server resource ID."
  }
}

variable "server_name" {
  description = "Name of the existing PostgreSQL Flexible Server. Used for outputs and cross-validation against server_id."
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

variable "configurations" {
  description = "List of PostgreSQL server configuration parameters to manage on the flexible server."
  type = list(object({
    name    = string
    value   = string
    source  = optional(string)
    enabled = optional(bool, true)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for configuration in var.configurations : configuration.name])) == length(var.configurations)
    error_message = "Each configuration name must be unique."
  }

  validation {
    condition = alltrue([
      for configuration in var.configurations :
      can(regex("^[a-z][a-z0-9_.]{0,254}$", configuration.name))
    ])
    error_message = "Each configuration name must start with a lowercase letter and contain only lowercase letters, digits, underscores, or dots (1-255 characters)."
  }

  validation {
    condition = alltrue([
      for configuration in var.configurations :
      !try(configuration.enabled, true) || length(trimspace(configuration.value)) > 0
    ])
    error_message = "Each enabled configuration must have a non-empty value."
  }

  validation {
    condition = alltrue([
      for configuration in var.configurations :
      try(configuration.source, null) == null ||
      contains(["system-default", "user-override", "user"], configuration.source)
    ])
    error_message = "source must be null or one of: system-default, user-override, user."
  }
}

variable "allow_restricted_configurations" {
  description = "When true, permits managing authentication and transport security configuration parameters. Defaults to false to avoid unintended security changes."
  type        = bool
  nullable    = false
  default     = false
}
