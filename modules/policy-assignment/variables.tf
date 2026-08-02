# ------------------------------------------------------------------------------
# Policy Assignment Module — Variables
# ------------------------------------------------------------------------------

variable "assignments" {
  description = "List of Azure Policy assignments. Each entry must include a stable key for for_each identity at scale."
  type = list(object({
    key                  = string
    name                 = string
    display_name         = optional(string)
    description          = optional(string)
    scope                = string
    policy_definition_id = string
    parameters           = optional(map(any))
    enforcement_mode     = optional(string)
    location             = optional(string)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    non_compliance_messages = optional(list(object({
      content                        = string
      policy_definition_reference_id = optional(string)
    })), [])
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
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", assignment.key))
    ])
    error_message = "Each assignment key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      length(assignment.name) >= 1 && length(assignment.name) <= 64 &&
      can(regex("^[\\w.-]+$", assignment.name))
    ])
    error_message = "Each assignment name must be 1-64 characters and contain only letters, numbers, hyphens, underscores, or periods."
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
      can(regex("^/providers/Microsoft\\.Authorization/(policyDefinitions|policySetDefinitions)/[0-9a-f-]{36}$", assignment.policy_definition_id)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/(policyDefinitions|policySetDefinitions)/[0-9a-f-]{36}$", assignment.policy_definition_id)) ||
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+/providers/Microsoft\\.Authorization/(policyDefinitions|policySetDefinitions)/[0-9a-f-]{36}$", assignment.policy_definition_id))
    ])
    error_message = "Each policy_definition_id must reference a built-in or custom policy definition or policy set definition."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.enforcement_mode, null) == null ||
      contains(["Default", "DoNotEnforce"], assignment.enforcement_mode)
    ])
    error_message = "enforcement_mode must be Default or DoNotEnforce when specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.identity, null) == null || try(assignment.location, null) != null
    ])
    error_message = "location is required when identity is specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.identity, null) == null ||
      contains(["SystemAssigned", "UserAssigned"], assignment.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned or UserAssigned when identity is specified."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.identity, null) == null ||
      assignment.identity.type != "UserAssigned" ||
      length(coalesce(try(assignment.identity.identity_ids, null), [])) > 0
    ])
    error_message = "identity.identity_ids must contain at least one user-assigned identity resource ID when identity.type is UserAssigned."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.identity, null) == null ||
      assignment.identity.type != "SystemAssigned" ||
      length(coalesce(try(assignment.identity.identity_ids, null), [])) == 0
    ])
    error_message = "identity.identity_ids must not be specified when identity.type is SystemAssigned."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.identity, null) == null ||
      assignment.identity.type != "UserAssigned" ||
      alltrue([
        for identity_id in assignment.identity.identity_ids :
        can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[\\w\\(\\)\\.-]+$", identity_id))
      ])
    ])
    error_message = "Each identity.identity_ids entry must be a valid user-assigned managed identity resource ID."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      try(assignment.parameters, null) == null ||
      can(jsonencode(assignment.parameters))
    ])
    error_message = "Each parameters map must be JSON-serializable."
  }

  validation {
    condition = alltrue([
      for assignment in var.assignments :
      alltrue([
        for message in coalesce(try(assignment.non_compliance_messages, null), []) :
        length(message.content) >= 1 && length(message.content) <= 4096
      ])
    ])
    error_message = "Each non_compliance_messages content must be between 1 and 4096 characters."
  }
}
