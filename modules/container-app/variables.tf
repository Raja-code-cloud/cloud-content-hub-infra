# ------------------------------------------------------------------------------
# Container App Module — Variables
# ------------------------------------------------------------------------------

# --- Core ---------------------------------------------------------------------

variable "container_app_name" {
  description = "Name of the Container App. Must be supplied by the caller — this module does not generate names."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.container_app_name)) && length(var.container_app_name) >= 2
    error_message = "container_app_name must be 2-32 lowercase alphanumeric characters or hyphens, starting and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the Container App is created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[\\w\\(\\)\\.-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters with valid Azure resource group name characters."
  }
}

variable "container_app_environment_id" {
  description = "Resource ID of the existing Container Apps Environment. This module does not create the environment."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[0-9a-f-]+/resourceGroups/[\\w\\(\\)\\.-]+/providers/Microsoft\\.App/managedEnvironments/[\\w\\(\\)\\.-]+$", var.container_app_environment_id))
    error_message = "container_app_environment_id must be a valid Container Apps Environment resource ID."
  }
}

variable "revision_mode" {
  description = "Revision operational mode. Single allows one active revision; Multiple supports traffic splitting."
  type        = string
  nullable    = false
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode must be Single or Multiple."
  }
}

variable "workload_profile_name" {
  description = "Workload profile name in the Container Apps Environment. Omit to use the default Consumption profile."
  type        = string
  nullable    = true
  default     = null
}

variable "max_inactive_revisions" {
  description = "Maximum number of inactive revisions retained for this Container App."
  type        = number
  nullable    = true
  default     = null

  validation {
    condition     = var.max_inactive_revisions == null || (var.max_inactive_revisions >= 0 && var.max_inactive_revisions <= 100)
    error_message = "max_inactive_revisions must be between 0 and 100 when specified."
  }
}

variable "tags" {
  description = "Tags applied to the Container App. Pass merged tags from modules/common — never hardcode tags in this module."
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.tags) > 0
    error_message = "tags must contain at least one tag. Supply merged tags from the shared foundation."
  }
}

# --- Containers ---------------------------------------------------------------

variable "containers" {
  description = "Container definitions for the app template. At least one container is required."
  type = list(object({
    name            = string
    image           = string
    image_tag       = optional(string, "latest")
    cpu             = number
    memory          = string
    command         = optional(list(string))
    startup_command = optional(list(string))
    args            = optional(list(string))
    env = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })), [])
    liveness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      host                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    readiness_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      host                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
      success_count_threshold = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    startup_probe = optional(object({
      transport               = string
      port                    = number
      path                    = optional(string)
      host                    = optional(string)
      initial_delay           = optional(number)
      interval_seconds        = optional(number)
      timeout                 = optional(number)
      failure_count_threshold = optional(number)
      headers = optional(list(object({
        name  = string
        value = string
      })), [])
    }))
    volume_mounts = optional(list(object({
      name     = string
      path     = string
      sub_path = optional(string)
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
      container.cpu > 0 && container.cpu <= 4
    ])
    error_message = "Each container cpu must be greater than 0 and less than or equal to 4."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      can(regex("^[0-9]+(\\.[0-9]+)?Gi$", container.memory))
    ])
    error_message = "Each container memory must be specified in Gi (e.g. 0.5Gi, 1.0Gi)."
  }

  validation {
    condition = alltrue([
      for container in var.containers :
      can(regex("^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$", container.name))
    ])
    error_message = "Each container name must be lowercase alphanumeric or hyphen, 2-64 characters."
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

variable "init_containers" {
  description = "Optional init container definitions executed before application containers start."
  type = list(object({
    name    = string
    image   = string
    cpu     = optional(number)
    memory  = optional(string)
    command = optional(list(string))
    args    = optional(list(string))
    env = optional(list(object({
      name        = string
      value       = optional(string)
      secret_name = optional(string)
    })), [])
    volume_mounts = optional(list(object({
      name     = string
      path     = string
      sub_path = optional(string)
    })), [])
  }))
  nullable = false
  default  = []
}

# --- Scaling ------------------------------------------------------------------

variable "scale" {
  description = "Autoscaling configuration including replica bounds and KEDA scale rules."
  type = object({
    min_replicas                     = optional(number, 0)
    max_replicas                     = optional(number, 10)
    cooldown_period_in_seconds       = optional(number)
    polling_interval_in_seconds      = optional(number)
    revision_suffix                  = optional(string)
    termination_grace_period_seconds = optional(number)
    http_rules = optional(list(object({
      name                = string
      concurrent_requests = number
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })), [])
    })), [])
    tcp_rules = optional(list(object({
      name                = string
      concurrent_requests = number
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })), [])
    })), [])
    custom_rules = optional(list(object({
      name             = string
      custom_rule_type = string
      metadata         = map(string)
      identity_id      = optional(string)
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })), [])
    })), [])
    azure_queue_rules = optional(list(object({
      name         = string
      queue_name   = string
      queue_length = number
      authentication = list(object({
        secret_name       = string
        trigger_parameter = string
      }))
    })), [])
  })
  nullable = false
  default = {
    min_replicas = 0
    max_replicas = 10
  }

  validation {
    condition     = var.scale.min_replicas >= 0
    error_message = "scale.min_replicas must be greater than or equal to 0."
  }

  validation {
    condition     = var.scale.max_replicas >= var.scale.min_replicas
    error_message = "scale.max_replicas must be greater than or equal to scale.min_replicas."
  }

  validation {
    condition     = var.scale.max_replicas <= 300
    error_message = "scale.max_replicas must be less than or equal to 300."
  }
}

# --- Ingress ------------------------------------------------------------------

variable "ingress" {
  description = "Ingress configuration. Set to null to deploy an internal worker without HTTP ingress."
  type = object({
    enabled                    = optional(bool, true)
    external_enabled           = optional(bool, true)
    target_port                = number
    exposed_port               = optional(number)
    transport                  = optional(string, "auto")
    allow_insecure_connections = optional(bool, false)
    client_certificate_mode    = optional(string)
    traffic_weights = optional(list(object({
      latest_revision = optional(bool)
      percentage      = number
      label           = optional(string)
      revision_suffix = optional(string)
    })), [])
    cors = optional(object({
      allowed_origins           = list(string)
      allow_credentials_enabled = optional(bool, false)
      allowed_headers           = optional(list(string))
      allowed_methods           = optional(list(string))
      exposed_headers           = optional(list(string))
      max_age_in_seconds        = optional(number)
    }))
    ip_security_restrictions = optional(list(object({
      name             = string
      action           = string
      ip_address_range = string
      description      = optional(string)
    })), [])
  })
  nullable = true
  default  = null

  validation {
    condition = (
      var.ingress == null ||
      (var.ingress.target_port >= 1 && var.ingress.target_port <= 65535)
    )
    error_message = "ingress.target_port must be between 1 and 65535 when ingress is configured."
  }

  validation {
    condition = (
      var.ingress == null ||
      var.ingress.exposed_port == null ||
      (var.ingress.exposed_port >= 1 && var.ingress.exposed_port <= 65535)
    )
    error_message = "ingress.exposed_port must be between 1 and 65535 when specified."
  }

  validation {
    condition = (
      var.ingress == null ||
      contains(["auto", "http", "http2", "tcp"], try(var.ingress.transport, "auto"))
    )
    error_message = "ingress.transport must be auto, http, http2, or tcp."
  }

  validation {
    condition = (
      var.ingress == null ||
      var.ingress.client_certificate_mode == null ||
      contains(["require", "accept", "ignore"], var.ingress.client_certificate_mode)
    )
    error_message = "ingress.client_certificate_mode must be require, accept, or ignore when specified."
  }
}

# --- Identity -----------------------------------------------------------------

variable "identity" {
  description = "Managed identity configuration. Set to null to deploy without managed identity."
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  nullable = true
  default  = null

  validation {
    condition = (
      var.identity == null ||
      contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
    )
    error_message = "identity.type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }

  validation {
    condition = (
      var.identity == null ||
      var.identity.type == "SystemAssigned" ||
      length(var.identity.identity_ids) > 0
    )
    error_message = "identity.identity_ids is required when identity.type is UserAssigned or SystemAssigned, UserAssigned."
  }
}

# --- Registry -----------------------------------------------------------------

variable "registries" {
  description = "Container registry authentication configurations. Supports multiple registries for future multi-registry deployments."
  type = list(object({
    server               = string
    identity             = optional(string)
    username             = optional(string)
    password_secret_name = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition = alltrue([
      for registry in var.registries :
      (
        registry.identity != null && registry.username == null && registry.password_secret_name == null
        ) || (
        registry.identity == null && registry.username != null && registry.password_secret_name != null
      )
    ])
    error_message = "Each registry must use either identity authentication or username/password_secret_name — not both."
  }
}

# --- Secrets ------------------------------------------------------------------

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

  validation {
    condition = alltrue([
      for secret in var.secrets :
      (
        secret.key_vault_secret_id != null && secret.identity != null && secret.value == null
        ) || (
        secret.key_vault_secret_id == null && secret.value != null
      )
    ])
    error_message = "Each secret must be either an inline value or a key_vault_secret_id with identity — not both."
  }
}

# --- Dapr ---------------------------------------------------------------------

variable "dapr" {
  description = "Optional Dapr sidecar configuration. Disabled by default."
  type = object({
    enabled      = optional(bool, false)
    app_id       = optional(string)
    app_port     = optional(number)
    app_protocol = optional(string, "http")
  })
  nullable = false
  default = {
    enabled = false
  }

  validation {
    condition     = !var.dapr.enabled || try(var.dapr.app_id, null) != null
    error_message = "dapr.app_id is required when dapr.enabled is true."
  }

  validation {
    condition = (
      !var.dapr.enabled ||
      try(var.dapr.app_protocol, "http") == null ||
      contains(["http", "grpc"], try(var.dapr.app_protocol, "http"))
    )
    error_message = "dapr.app_protocol must be http or grpc when Dapr is enabled."
  }
}

# --- Volumes ------------------------------------------------------------------

variable "volumes" {
  description = "Template volumes for shared storage across containers."
  type = list(object({
    name          = string
    storage_type  = optional(string, "EmptyDir")
    storage_name  = optional(string)
    mount_options = optional(string)
  }))
  nullable = false
  default  = []

  validation {
    condition = alltrue([
      for volume in var.volumes :
      contains(["AzureFile", "EmptyDir", "NfsAzureFile", "Secret"], volume.storage_type)
    ])
    error_message = "Each volume storage_type must be AzureFile, EmptyDir, NfsAzureFile, or Secret."
  }
}

# --- Observability ------------------------------------------------------------

variable "observability" {
  description = "Optional Application Insights integration via environment variables. Does not create Application Insights."
  type = object({
    application_insights_connection_string             = optional(string)
    application_insights_connection_string_secret_name = optional(string)
    application_insights_secret_name                   = optional(string)
  })
  nullable  = true
  default   = null
  sensitive = true
}

# --- Lifecycle ----------------------------------------------------------------

variable "lifecycle_options" {
  description = "Lifecycle behavior flags. Secret values are always ignored in the resource lifecycle block to support Key Vault references without drift."
  type = object({
    ignore_secret_values = optional(bool, true)
  })
  nullable = false
  default = {
    ignore_secret_values = true
  }
}
