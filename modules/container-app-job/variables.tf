# ------------------------------------------------------------------------------
# Container App Job Module — Variables
# ------------------------------------------------------------------------------

variable "job_name" {
  description = "Name of the Container Apps Job. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.job_name)) && length(var.job_name) >= 2
    error_message = "job_name must be 2-32 lowercase alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Container Apps Job is created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Azure region for the Container Apps Job."
  type        = string
  nullable    = false
}

variable "container_app_environment_id" {
  description = "Resource ID of the existing Container Apps Environment."
  type        = string
  nullable    = false
}

variable "replica_timeout_in_seconds" {
  description = "Maximum seconds a job replica may run before being terminated."
  type        = number
  nullable    = false
  default     = 1800

  validation {
    condition     = var.replica_timeout_in_seconds >= 1 && var.replica_timeout_in_seconds <= 86400
    error_message = "replica_timeout_in_seconds must be between 1 and 86400."
  }
}

variable "replica_retry_limit" {
  description = "Number of retries allowed for a failed job replica."
  type        = number
  nullable    = false
  default     = 1

  validation {
    condition     = var.replica_retry_limit >= 0 && var.replica_retry_limit <= 100
    error_message = "replica_retry_limit must be between 0 and 100."
  }
}

variable "workload_profile_name" {
  description = "Workload profile name in the Container Apps Environment. Omit to use the default Consumption profile."
  type        = string
  nullable    = true
  default     = null
}

variable "tags" {
  description = "Tags applied to the Container Apps Job. Pass merged tags from modules/common."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag."
  }
}

variable "containers" {
  description = "Container definitions for the job template. At least one container is required."
  type = list(object({
    name    = string
    image   = string
    cpu     = number
    memory  = string
    command = optional(list(string))
    args    = optional(list(string))
    env = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })), [])
  }))
  nullable = false

  validation {
    condition     = length(var.containers) >= 1
    error_message = "At least one container definition is required."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      alltrue([
        for env in container.env :
        (env.value != null && env.secret_name == null) || (env.value == null && env.secret_name != null)
      ])
    ])
    error_message = "Each environment variable must specify either value or secret_name, not both."
  }
}

variable "identity" {
  description = "Managed identity configuration. Set to null to deploy without managed identity."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  nullable = true
  default  = null
}

variable "registries" {
  description = "Container registry authentication configurations."
  type = list(object({
    server               = string
    identity             = optional(string)
    username             = optional(string)
    password_secret_name = optional(string)
  }))
  nullable = false
  default  = []
}

variable "secrets" {
  description = "Inline secrets and Key Vault secret references. Secret values are never exposed in outputs."
  type = list(object({
    name                = string
    value               = optional(string)
    key_vault_secret_id = optional(string)
    identity            = optional(string)
  }))
  nullable  = false
  default   = []
  sensitive = true
}

variable "manual_trigger" {
  description = "Manual trigger configuration for on-demand jobs such as database migrations."
  type = object({
    parallelism              = optional(number, 1)
    replica_completion_count = optional(number, 1)
  })
  nullable = false
  default = {
    parallelism              = 1
    replica_completion_count = 1
  }
}
