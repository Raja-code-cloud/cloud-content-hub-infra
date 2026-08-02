# ------------------------------------------------------------------------------
# Policy Exemption Module — Variables
# ------------------------------------------------------------------------------

variable "require_expiration_dates" {
  description = "When true, every exemption must specify expires_on. Recommended for production to avoid permanent exemptions."
  type        = bool
  nullable    = false
  default     = false
}

variable "exemptions" {
  description = "List of Azure Policy exemptions. Each entry requires a stable key for for_each identity."
  type = list(object({
    key                             = string
    name                            = string
    display_name                    = optional(string)
    description                     = optional(string)
    scope                           = string
    policy_assignment_id            = string
    policy_definition_reference_ids = optional(list(string))
    exemption_category              = string
    expires_on                      = optional(string)
    metadata                        = optional(map(string))
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for exemption in var.exemptions : exemption.key])) == length(var.exemptions)
    error_message = "Each exemption key must be unique."
  }

  validation {
    condition     = length(distinct([for exemption in var.exemptions : exemption.name])) == length(var.exemptions)
    error_message = "Each exemption name must be unique."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", exemption.key))
    ])
    error_message = "Each exemption key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      length(exemption.name) >= 1 && length(exemption.name) <= 64 &&
      can(regex("^[\\w.-]+$", exemption.name))
    ])
    error_message = "Each exemption name must be 1-64 characters and contain only letters, numbers, hyphens, underscores, or periods."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+$", exemption.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}$", exemption.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", exemption.scope)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", exemption.scope))
    ])
    error_message = "Each scope must be a valid management group, subscription, resource group, or resource ID."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+/providers/Microsoft\\.Authorization/policyAssignments/[\\w.-]+$", exemption.policy_assignment_id)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/policyAssignments/[\\w.-]+$", exemption.policy_assignment_id)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Authorization/policyAssignments/[\\w.-]+$", exemption.policy_assignment_id)) ||
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+/providers/Microsoft\\.Authorization/policyAssignments/[\\w.-]+$", exemption.policy_assignment_id))
    ])
    error_message = "Each policy_assignment_id must be a valid Azure Policy Assignment resource ID."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      contains(["Waiver", "Mitigated"], exemption.exemption_category)
    ])
    error_message = "exemption_category must be Waiver or Mitigated."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      try(exemption.expires_on, null) == null ||
      can(regex("^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z|[0-9]{4}-[0-9]{2}-[0-9]{2})$", exemption.expires_on))
    ])
    error_message = "expires_on must be ISO 8601 format (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ) when specified."
  }

  validation {
    condition = var.require_expiration_dates == false || alltrue([
      for exemption in var.exemptions :
      try(exemption.expires_on, null) != null
    ])
    error_message = "require_expiration_dates is true — every exemption must specify expires_on."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      try(exemption.expires_on, null) != null ||
      length(try(exemption.metadata, {})) > 0
    ])
    error_message = "Exemptions without expires_on must include metadata documenting the governance justification."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      alltrue([
        for ref_id in try(exemption.policy_definition_reference_ids, []) :
        length(ref_id) > 0
      ])
    ])
    error_message = "policy_definition_reference_ids must not contain empty strings."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      try(exemption.policy_definition_reference_ids, null) == null ||
      length(exemption.policy_definition_reference_ids) == length(distinct(exemption.policy_definition_reference_ids))
    ])
    error_message = "policy_definition_reference_ids must be unique within each exemption."
  }

  validation {
    condition = alltrue([
      for exemption in var.exemptions :
      try(exemption.description, null) == null || length(exemption.description) <= 1024
    ])
    error_message = "description must be 1024 characters or fewer when specified."
  }
}
