# ------------------------------------------------------------------------------
# Input Variables — dev
#
# Only expose values that genuinely differ by environment or deployment.
# Naming, tags, and prefixes are centralized via modules/common and locals.
# Standards: docs/terraform/shared-foundation.md
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment identifier. Must match the environment folder name."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "dev"
    error_message = "The environment variable must be \"dev\" for this root module."
  }
}

variable "subscription_id" {
  description = "Target Azure subscription ID. Supplied via tfvars or CI — never hardcoded in source."
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "Short project identifier for naming and tags."
  type        = string
  nullable    = false
}

variable "application_name" {
  description = "Application identifier for naming and tags."
  type        = string
  nullable    = false
}

variable "location" {
  description = "Primary Azure region for resource deployment."
  type        = string
  nullable    = false
}

variable "location_short" {
  description = "Optional short region code override."
  type        = string
  nullable    = true
  default     = null
}

variable "resource_prefix" {
  description = "Optional resource prefix override."
  type        = string
  nullable    = true
  default     = null
}

variable "owner" {
  description = "Team or individual responsible for the resources."
  type        = string
  nullable    = false
}

variable "business_unit" {
  description = "Business unit accountable for the workload."
  type        = string
  nullable    = false
}

variable "cost_center" {
  description = "Cost center code for chargeback."
  type        = string
  nullable    = false
}

variable "repository_name" {
  description = "Source repository name."
  type        = string
  nullable    = false
  default     = "cloud-content-hub-infra"
}

variable "managed_by" {
  description = "Resource lifecycle manager."
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
  description = "Additional tags merged with the global tag set."
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "additional_tags" {
  description = "Supplementary tags for environment-specific metadata."
  type        = map(string)
  nullable    = false
  default     = {}
}

# --- Secrets (supply via tfvars or CI — never commit real values) --------------

variable "postgresql_administrator_login" {
  description = "PostgreSQL administrator login username."
  type        = string
  nullable    = false
  default     = "psqladmin"
}

variable "postgresql_admin_password" {
  description = "PostgreSQL administrator password. Supply via TF_VAR_postgresql_admin_password or GitHub Actions secrets."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "deployment_principal_id" {
  description = "Optional object ID of the Terraform/GitHub Actions deployment identity. Grants Key Vault Secrets Officer for secret provisioning."
  type        = string
  nullable    = true
  default     = null

  validation {
    condition = (
      var.deployment_principal_id == null ||
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.deployment_principal_id))
    )
    error_message = "deployment_principal_id must be null or a valid UUID."
  }
}

variable "api_key_placeholder" {
  description = "Placeholder API key stored in Key Vault. Replace via CI secrets in real deployments."
  type        = string
  nullable    = false
  sensitive   = true
  default     = "replace-via-github-actions-secret"
}

# --- Container App / CCH runtime -----------------------------------------------

variable "container_image_name" {
  description = "API container image repository name within ACR (without registry prefix or tag)."
  type        = string
  nullable    = false
  default     = "cloud-content-hub-api"
}

variable "container_image_tag" {
  description = "API container image tag to deploy."
  type        = string
  nullable    = false
  default     = "latest"
}

variable "worker_image_name" {
  description = "Worker/beat container image repository name within ACR (without registry prefix or tag)."
  type        = string
  nullable    = false
  default     = "cloud-content-hub-worker"
}

variable "worker_image_tag" {
  description = "Worker/beat container image tag to deploy. Defaults to the API image tag when null."
  type        = string
  nullable    = false
  default     = "latest"
}

variable "container_target_port" {
  description = "API container port exposed through ingress. Cloud Content Hub AI listens on 8000."
  type        = number
  nullable    = false
  default     = 8000

  validation {
    condition     = var.container_target_port >= 1 && var.container_target_port <= 65535
    error_message = "container_target_port must be between 1 and 65535."
  }
}

variable "cch_environment" {
  description = "Value for CCH_ENVIRONMENT (local|test|staging|production)."
  type        = string
  nullable    = false
  default     = "staging"

  validation {
    condition     = contains(["local", "test", "staging", "production"], var.cch_environment)
    error_message = "cch_environment must be one of: local, test, staging, production."
  }
}

variable "cch_log_level" {
  description = "Value for CCH_LOG_LEVEL."
  type        = string
  nullable    = false
  default     = "INFO"
}

variable "cch_openapi_enabled" {
  description = "Value for CCH_OPENAPI_ENABLED. Must be false in production."
  type        = bool
  nullable    = false
  default     = true
}

variable "cch_http_allowed_origins" {
  description = "CORS allow-list serialized into CCH_HTTP_ALLOWED_ORIGINS."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "celery_concurrency" {
  description = "Celery worker concurrency (CELERY_CONCURRENCY)."
  type        = number
  nullable    = false
  default     = 2

  validation {
    condition     = var.celery_concurrency >= 1 && var.celery_concurrency <= 32
    error_message = "celery_concurrency must be between 1 and 32."
  }
}
