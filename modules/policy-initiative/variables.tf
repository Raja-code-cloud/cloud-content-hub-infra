# ------------------------------------------------------------------------------
# Policy Initiative Module — Variables
# ------------------------------------------------------------------------------

variable "initiatives" {
  description = "List of Azure Policy initiatives (policy set definitions). Each entry must include a stable key for for_each identity at scale."
  type = list(object({
    key                 = string
    name                = string
    display_name        = string
    description         = optional(string)
    management_group_id = optional(string)
    policy_type         = string
    metadata            = optional(map(any))
    parameters          = optional(map(any))
    policy_definitions = list(object({
      policy_definition_id = string
      reference_id         = optional(string)
      parameters           = optional(map(any))
      group_names          = optional(list(string))
      version              = optional(string)
    }))
    policy_groups = optional(list(object({
      name                            = string
      display_name                    = optional(string)
      description                     = optional(string)
      category                        = optional(string)
      additional_metadata_resource_id = optional(string)
    })), [])
  }))
  nullable = false
  default  = []

  validation {
    condition     = length(distinct([for initiative in var.initiatives : initiative.key])) == length(var.initiatives)
    error_message = "Each initiative key must be unique."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", initiative.key))
    ])
    error_message = "Each initiative key must be 2-64 lowercase alphanumeric characters or hyphens."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(initiative.name) >= 1 && length(initiative.name) <= 64 &&
      can(regex("^[\\w.-]+$", initiative.name))
    ])
    error_message = "Each initiative name must be 1-64 characters and contain only letters, numbers, hyphens, underscores, or periods."
  }

  validation {
    condition     = length(distinct([for initiative in var.initiatives : initiative.name])) == length(var.initiatives)
    error_message = "Each initiative name must be unique."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(initiative.display_name) >= 1 && length(initiative.display_name) <= 128
    ])
    error_message = "Each display_name must be between 1 and 128 characters."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      try(initiative.description, null) == null ||
      (length(initiative.description) >= 1 && length(initiative.description) <= 2048)
    ])
    error_message = "Each description must be between 1 and 2048 characters when specified."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      try(initiative.management_group_id, null) == null ||
      can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+$", initiative.management_group_id))
    ])
    error_message = "Each management_group_id must be a valid management group resource ID when specified."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      contains(["BuiltIn", "Custom", "NotSpecified", "Static"], initiative.policy_type)
    ])
    error_message = "Each policy_type must be BuiltIn, Custom, NotSpecified, or Static."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(initiative.policy_definitions) >= 1
    ])
    error_message = "Each initiative must include at least one policy definition reference."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(distinct([for policy_definition in initiative.policy_definitions : policy_definition.policy_definition_id])) ==
      length(initiative.policy_definitions)
    ])
    error_message = "Each initiative must not reference duplicate policy_definition_id values."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(distinct([
        for policy_definition in initiative.policy_definitions :
        coalesce(try(policy_definition.reference_id, null), policy_definition.policy_definition_id)
      ])) == length(initiative.policy_definitions)
    ])
    error_message = "Each initiative must not contain duplicate reference_id values."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      alltrue([
        for policy_definition in initiative.policy_definitions :
        can(regex("^/providers/Microsoft\\.Authorization/policyDefinitions/[0-9a-f-]{36}$", policy_definition.policy_definition_id)) ||
        can(regex("^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/policyDefinitions/[0-9a-f-]{36}$", policy_definition.policy_definition_id)) ||
        can(regex("^/providers/Microsoft\\.Management/managementGroups/[\\w-]+/providers/Microsoft\\.Authorization/policyDefinitions/[0-9a-f-]{36}$", policy_definition.policy_definition_id))
      ])
    ])
    error_message = "Each policy_definition_id must reference a built-in or custom policy definition."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      alltrue([
        for policy_definition in initiative.policy_definitions :
        try(policy_definition.reference_id, null) == null ||
        (
          length(policy_definition.reference_id) >= 1 &&
          length(policy_definition.reference_id) <= 64 &&
          can(regex("^[\\w.-]+$", policy_definition.reference_id))
        )
      ])
    ])
    error_message = "Each reference_id must be 1-64 characters and contain only letters, numbers, hyphens, underscores, or periods."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      length(distinct([for group in coalesce(try(initiative.policy_groups, null), []) : group.name])) ==
      length(coalesce(try(initiative.policy_groups, null), []))
    ])
    error_message = "Each initiative policy_groups name must be unique."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      alltrue([
        for group in coalesce(try(initiative.policy_groups, null), []) :
        length(group.name) >= 1 && length(group.name) <= 64 &&
        can(regex("^[\\w.-]+$", group.name))
      ])
    ])
    error_message = "Each policy_groups name must be 1-64 characters and contain only letters, numbers, hyphens, underscores, or periods."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      alltrue([
        for policy_definition in initiative.policy_definitions :
        alltrue([
          for group_name in coalesce(try(policy_definition.group_names, null), []) :
          contains([for group in coalesce(try(initiative.policy_groups, null), []) : group.name], group_name)
        ])
      ])
    ])
    error_message = "Each policy definition group_names entry must match a policy_groups.name within the same initiative."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      try(initiative.metadata, null) == null ||
      can(jsonencode(initiative.metadata))
    ])
    error_message = "Each metadata map must be JSON-serializable."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      try(initiative.parameters, null) == null ||
      can(jsonencode(initiative.parameters))
    ])
    error_message = "Each parameters map must be JSON-serializable."
  }

  validation {
    condition = alltrue([
      for initiative in var.initiatives :
      alltrue([
        for policy_definition in initiative.policy_definitions :
        try(policy_definition.parameters, null) == null ||
        can(jsonencode(policy_definition.parameters))
      ])
    ])
    error_message = "Each policy definition parameters map must be JSON-serializable."
  }
}
