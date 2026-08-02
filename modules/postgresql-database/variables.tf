# ------------------------------------------------------------------------------
# PostgreSQL Database Module — Variables
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

variable "databases" {
  description = "List of logical PostgreSQL databases to create on the flexible server."
  type = list(object({
    name            = string
    charset         = optional(string, "UTF8")
    collation       = optional(string, "en_US.utf8")
    prevent_destroy = optional(bool, true)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for database in var.databases : database.name])) == length(var.databases)
    error_message = "Each database name must be unique."
  }

  validation {
    condition = alltrue([
      for database in var.databases :
      can(regex("^[a-z][a-z0-9_]{0,62}$", database.name))
    ])
    error_message = "Each database name must start with a lowercase letter and contain only lowercase letters, digits, or underscores (1-63 characters)."
  }

  validation {
    condition = alltrue([
      for database in var.databases :
      can(regex("^[a-zA-Z0-9_]+\\.[a-z0-9_]+$", database.collation))
    ])
    error_message = "Each database collation must use the locale.encoding format with a lowercase encoding suffix (e.g. en_US.utf8)."
  }
}

variable "tags" {
  description = "Tags for downstream composition and operational metadata. PostgreSQL Flexible Server databases do not support Azure resource tags; values are exposed in outputs only."
  type        = map(string)
  nullable    = false
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(key) >= 1 && length(key) <= 512 && length(value) <= 256
    ])
    error_message = "Each tag key must be 1-512 characters and each value must be 1-256 characters."
  }
}
