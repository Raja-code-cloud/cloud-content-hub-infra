# ------------------------------------------------------------------------------
# Common Module — Variables
#
# Shared configuration consumed by all Azure modules and environment roots.
# See: docs/terraform/shared-foundation.md
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Short project identifier used in naming and tags (e.g. cch)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project_name))
    error_message = "project_name must be 2-8 lowercase alphanumeric characters starting with a letter."
  }
}

variable "application_name" {
  description = "Application identifier used in naming and tags."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.application_name))
    error_message = "application_name must be 2-22 lowercase alphanumeric characters or hyphens starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "location" {
  description = "Primary Azure region for resource deployment."
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

variable "location_short" {
  description = "Optional short region code. Computed from location when null."
  type        = string
  nullable    = true
  default     = null
}

variable "resource_prefix" {
  description = "Optional override for the computed resource prefix. Leave null to derive from project_name and environment."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.resource_prefix == null || can(regex("^[a-z][a-z0-9-]{2,24}$", var.resource_prefix))
    error_message = "resource_prefix must be null or 3-25 lowercase alphanumeric characters or hyphens starting with a letter."
  }
}

variable "owner" {
  description = "Team or individual responsible for the resources."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must be a non-empty string."
  }
}

variable "business_unit" {
  description = "Business unit accountable for the workload."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.business_unit)) > 0
    error_message = "business_unit must be a non-empty string."
  }
}

variable "cost_center" {
  description = "Cost center code for chargeback and budgeting."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{2,20}$", var.cost_center))
    error_message = "cost_center must be 2-20 alphanumeric characters or hyphens."
  }
}

variable "repository_name" {
  description = "Source repository name for traceability tags."
  type        = string
  nullable    = false
  default     = "cloud-content-hub-infra"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,64}$", var.repository_name))
    error_message = "repository_name must be 3-64 lowercase alphanumeric characters or hyphens."
  }
}

variable "managed_by" {
  description = "Tool or team managing the resource lifecycle."
  type        = string
  nullable    = false
  default     = "terraform"
}

variable "created_by" {
  description = "Identity or pipeline that created the deployment."
  type        = string
  nullable    = false
  default     = "platform-engineering"
}

variable "tags" {
  description = "Additional tags merged into the global tag set after base and additional_tags."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "additional_tags" {
  description = "Supplementary tags supplied by consuming modules or environments."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "standard_resource_names" {
  description = "Optional batch of standard platform resource names to pre-compute via the naming module."
  type = map(object({
    resource_type    = string
    instance         = optional(string, "")
    include_location = optional(bool, false)
  }))
  nullable = false
  default = {
    resource_group = { resource_type = "resource_group" }
    acr            = { resource_type = "acr" }
    cae            = { resource_type = "cae" }
    api            = { resource_type = "api" }
    storage        = { resource_type = "storage" }
    postgres       = { resource_type = "postgres" }
    redis          = { resource_type = "redis" }
    key_vault      = { resource_type = "key_vault" }
  }
}

variable "enforce_required_tags" {
  description = "When true, validates that required organizational tags are non-empty."
  type        = bool
  nullable    = false
  default     = true
}
