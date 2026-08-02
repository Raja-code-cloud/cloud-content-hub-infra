# ------------------------------------------------------------------------------
# Role Assignment Module — Variables
# ------------------------------------------------------------------------------

variable "assignments" {
  description = "List of Azure RBAC role assignments. Each entry must include a stable key for for_each identity at scale."
  type = list(object({
    key                              = string
    principal_id                     = string
    principal_type                   = optional(string)
    scope                            = string
    role_definition_name             = optional(string)
    role_definition_id               = optional(string)
    condition                        = optional(string)
    condition_version                = optional(string)
    skip_service_principal_aad_check = optional(bool, false)
    description                      = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for assignment in var.assignments : assignment.key])) == length(var.assignments)
    error_message = "Each assignment key must be unique."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      (
        (try(assignment.role_definition_name, null) != null && try(assignment.role_definition_id, null) == null) ||
        (try(assignment.role_definition_name, null) == null && try(assignment.role_definition_id, null) != null)
      )
    ])
    error_message = "Each assignment must specify exactly one of role_definition_name or role_definition_id."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", assignment.key))
    ])
    error_message = "Each assignment key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", assignment.principal_id))
    ])
    error_message = "Each principal_id must be a valid UUID."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      assignment.principal_type == null || contains([
        "User",
        "Group",
        "ServicePrincipal",
        "ForeignGroup",
      ], assignment.principal_type)
    ])
    error_message = "principal_type must be User, Group, ServicePrincipal, or ForeignGroup when specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+$", assignment.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}$", assignment.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", assignment.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", assignment.scope))
    ])
    error_message = "Each scope must be a valid management group, subscription, resource group, or resource scope."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.role_definition_name, null) == null ||
      (length(assignment.role_definition_name) >= 1 && length(assignment.role_definition_name) <= 256)
    ])
    error_message = "role_definition_name must be between 1 and 256 characters when specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.role_definition_id, null) == null ||
      can(regex("^/providers/Microsoft\\.Authorization/roleDefinitions/[0-9a-f-]{36}$", assignment.role_definition_id)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/roleDefinitions/[0-9a-f-]{36}$", assignment.role_definition_id))
    ])
    error_message = "role_definition_id must be a valid Azure role definition resource ID when specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.condition, null) == null || try(assignment.condition_version, null) != null
    ])
    error_message = "condition_version is required when condition is specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.condition_version, null) == null ||
      contains(["1.0", "2.0"], assignment.condition_version)
    ])
    error_message = "condition_version must be 1.0 or 2.0 when specified."
  }
}
