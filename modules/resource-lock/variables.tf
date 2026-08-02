# ------------------------------------------------------------------------------
# Resource Lock Module — Variables
# ------------------------------------------------------------------------------

variable "locks" {
  description = "List of Azure Management Locks to apply to existing scopes. Each entry requires a stable key for for_each identity at scale."
  type = list(object({
    key        = string
    name       = string
    scope      = string
    lock_level = optional(string, "CanNotDelete")
    notes      = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for lock in var.locks : lock.key])) == length(var.locks)
    error_message = "Each lock key must be unique."
  }

  validation {
    condition = length(distinct([
      for lock in var.locks : "${lock.scope}/${lock.name}"
    ])) == length(var.locks)
    error_message = "Each lock name must be unique within its scope."
  }

  validation {
    condition = alltrue([
      for lock in var.locks :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", lock.key))
    ])
    error_message = "Each lock key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for lock in var.locks :
      can(regex("^[\\w\\(\\)\\.-]{1,90}$", lock.name))
    ])
    error_message = "Each lock name must be 1-90 valid Azure name characters."
  }

  validation {
    condition = alltrue([
      for lock in var.locks :
      contains(["CanNotDelete", "ReadOnly"], try(lock.lock_level, "CanNotDelete"))
    ])
    error_message = "lock_level must be CanNotDelete or ReadOnly."
  }

  validation {
    condition = alltrue([
      for lock in var.locks :
      can(regex("^/subscriptions/[0-9a-f-]{36}$", lock.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", lock.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", lock.scope))
    ])
    error_message = "Each scope must be a valid subscription, resource group, or Azure resource ID."
  }

  validation {
    condition = alltrue([
      for lock in var.locks :
      try(lock.notes, null) == null || length(lock.notes) <= 512
    ])
    error_message = "notes must be 512 characters or fewer when specified."
  }
}
