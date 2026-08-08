# ------------------------------------------------------------------------------
# Naming Module — Variables
#
# Provides deterministic, reusable Azure resource naming.
# See: docs/terraform/shared-foundation.md#naming-strategy
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Short project identifier used as the leading segment in resource names (e.g. cch)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.project_name))
    error_message = "project_name must be 2-8 lowercase alphanumeric characters starting with a letter."
  }
}

variable "application_name" {
  description = "Application identifier used in tags and optional name segments."
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
  description = "Azure region where resources are deployed."
  type        = string
  nullable    = false

  validation {
    condition = contains([
      "eastus", "eastus2", "centralus", "westus2", "westus3",
      "northeurope", "westeurope", "uksouth", "ukwest",
      "swedencentral", "francecentral", "germanywestcentral",
      "australiaeast", "southeastasia", "japaneast", "brazilsouth",
    ], var.location)
    error_message = "location must be a supported Azure region. See modules/naming/locals.tf for the full list."
  }
}

variable "location_short" {
  description = "Optional short region code. Computed automatically from location when null."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition     = var.location_short == null || can(regex("^[a-z0-9]{2,5}$", var.location_short))
    error_message = "location_short must be null or 2-5 lowercase alphanumeric characters."
  }
}

variable "resource_type" {
  description = "Resource type key from the naming catalog (e.g. acr, cae, postgres). Required for single-name mode."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition = var.resource_type == null ? true : contains([
      "acr", "cae", "api", "worker", "beat", "migrate", "storage", "postgres", "redis", "key_vault",
      "vnet", "subnet", "identity", "log_analytics", "app_insights",
      "monitor", "alerts", "budget", "resource_group",
    ], var.resource_type)
    error_message = "resource_type must be null or a supported catalog key."
  }
}

variable "instance" {
  description = "Optional instance suffix to distinguish multiple resources of the same type."
  type        = string
  nullable    = false
  default     = ""

  validation {
    condition     = var.instance == "" || can(regex("^[a-z][a-z0-9-]{0,18}$", var.instance))
    error_message = "instance must be empty or 1-19 lowercase alphanumeric characters or hyphens starting with a letter."
  }
}

variable "include_location" {
  description = "When true, include the location short code in the generated name for globally unique resources."
  type        = bool
  nullable    = false
  default     = false
}

variable "resources" {
  description = "Optional batch naming map. Keys are logical names; values define resource_type, instance, and include_location overrides."
  type = map(object({
    resource_type    = string
    instance         = optional(string, "")
    include_location = optional(bool, false)
  }))
  nullable = false
  default  = {}
}
