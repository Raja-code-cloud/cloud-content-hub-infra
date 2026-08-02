# ------------------------------------------------------------------------------
# Application Insights Module — Variables
# ------------------------------------------------------------------------------

variable "application_insights_name" {
  description = "Name of the Application Insights resource. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,260}$", var.application_insights_name))
    error_message = "application_insights_name must be 1-260 characters and contain only alphanumeric characters, underscores, parentheses, hyphens, and periods."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where Application Insights is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "location" {
  description = "Azure region for Application Insights. Should match the linked Log Analytics Workspace region."
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

variable "workspace_id" {
  description = "Resource ID of the existing Log Analytics Workspace. This module does not create the workspace."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.OperationalInsights/workspaces/[\\w\\(\\)\\.-]+$", var.workspace_id))
    error_message = "workspace_id must be a valid Log Analytics Workspace resource ID."
  }
}

variable "application_type" {
  description = "Type of application monitored by Application Insights."
  type        = string
  nullable    = false
  default     = "web"

  validation {
    condition = contains([
      "web", "other", "java", "Node.JS", "phone", "ios", "store", "MobileCenter",
    ], var.application_type)
    error_message = "application_type must be a supported Application Insights application type."
  }
}

variable "sampling_percentage" {
  description = "Percentage of telemetry data sampled (0-100). Lower values reduce ingestion cost."
  type        = number
  nullable    = false
  default     = 50

  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "sampling_percentage must be between 0 and 100."
  }
}

variable "disable_ip_masking" {
  description = "When true, disables IP masking in telemetry data."
  type        = bool
  nullable    = false
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "When true, allows ingestion of telemetry over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "internet_query_enabled" {
  description = "When true, allows querying telemetry over the public internet."
  type        = bool
  nullable    = false
  default     = true
}

variable "local_authentication_disabled" {
  description = "When true, disables local authentication in favour of Azure AD authentication."
  type        = bool
  nullable    = false
  default     = true
}

variable "force_customer_storage_for_profiler" {
  description = "When true, forces customer-managed storage for profiler data."
  type        = bool
  nullable    = false
  default     = false
}

variable "tags" {
  description = "Tags applied to Application Insights. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}
