# ------------------------------------------------------------------------------
# Container Apps Environment Module — Variables
# ------------------------------------------------------------------------------

variable "environment_name" {
  description = "Name of the Container Apps Environment. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,58}[a-z0-9])?$", var.environment_name)) && length(var.environment_name) >= 2
    error_message = "environment_name must be 2-60 lowercase alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Container Apps Environment is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for the Container Apps Environment. Should match the linked Log Analytics Workspace region."
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

variable "log_analytics_workspace_id" {
  description = "Resource ID of the existing Log Analytics Workspace. This module does not create the workspace."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.OperationalInsights/workspaces/[\\w\\(\\)\\.-]+$", var.log_analytics_workspace_id))
    error_message = "log_analytics_workspace_id must be a valid Log Analytics Workspace resource ID."
  }
}

variable "internal_load_balancer_enabled" {
  description = "When true, uses an internal load balancer for ingress. Requires infrastructure_subnet_id."
  type        = bool
  nullable    = false
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "When true, enables zone redundancy for the Container Apps Environment infrastructure."
  type        = bool
  nullable    = false
  default     = false
}

variable "infrastructure_subnet_id" {
  description = "Optional resource ID of the delegated subnet for VNet-integrated Container Apps Environment infrastructure."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition = (
      var.infrastructure_subnet_id == null ||
      can(regex("^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.Network/virtualNetworks/[\\w\\(\\)\\.-]+/subnets/[\\w\\(\\)\\.-]+$", var.infrastructure_subnet_id))
    )
    error_message = "infrastructure_subnet_id must be null or a valid Azure subnet resource ID."
  }
}

variable "workload_profile_enabled" {
  description = "When true, configures workload profiles on the environment. Required to add dedicated profiles later without recreating the environment."
  type        = bool
  nullable    = false
  default     = true
}

variable "workload_profiles" {
  description = "Workload profiles for the Container Apps Environment. Defaults to Consumption-only for scale-to-zero."
  type = list(object({
    name                  = string
    workload_profile_type = string
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  }))
  nullable = false
  default = [{
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }]

  validation {
    condition = alltrue([
      for profile in var.workload_profiles :
      contains([
        "Consumption",
        "Consumption-GPU-NC24-A100",
        "Consumption-GPU-NC8as-T4",
        "D4",
        "D8",
        "D16",
        "D32",
        "E4",
        "E8",
        "E16",
        "E32",
        "NC24-A100",
        "NC48-A100",
        "NC96-A100",
      ], profile.workload_profile_type)
    ])
    error_message = "Each workload_profile_type must be a supported Azure Container Apps workload profile type."
  }

  validation {
    condition = alltrue([
      for profile in var.workload_profiles :
      profile.workload_profile_type != "Consumption" || profile.name == "Consumption"
    ])
    error_message = "A Consumption workload profile must be named 'Consumption'."
  }

  validation {
    condition     = length([for profile in var.workload_profiles : profile if profile.workload_profile_type == "Consumption"]) <= 1
    error_message = "At most one Consumption workload profile is allowed."
  }

  validation {
    condition = alltrue([
      for profile in var.workload_profiles :
      profile.minimum_count == null || profile.minimum_count >= 0
    ])
    error_message = "workload_profiles minimum_count must be greater than or equal to 0 when specified."
  }

  validation {
    condition = alltrue([
      for profile in var.workload_profiles :
      profile.maximum_count == null || profile.maximum_count >= 1
    ])
    error_message = "workload_profiles maximum_count must be greater than or equal to 1 when specified."
  }

  validation {
    condition = alltrue([
      for profile in var.workload_profiles :
      profile.minimum_count == null ||
      profile.maximum_count == null ||
      profile.minimum_count <= profile.maximum_count
    ])
    error_message = "workload_profiles minimum_count must be less than or equal to maximum_count when both are specified."
  }
}

variable "tags" {
  description = "Tags applied to the Container Apps Environment. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
