# ------------------------------------------------------------------------------
# Input Variables — stage
#
# Only expose values that genuinely differ by environment or deployment.
# Naming, sizing, governance, and feature flags are centralized in locals.tf.
# Standards: docs/terraform/shared-foundation.md
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Deployment environment identifier. Must match the environment folder name."
  type        = string
  nullable    = false

  validation {
    condition     = var.environment == "stage"
    error_message = "The environment variable must be \"stage\" for this root module."
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

# --- Feature flags -------------------------------------------------------------

variable "enable_private_networking" {
  description = "When true, deploys VNet, private DNS, and optional private endpoints for private connectivity."
  type        = bool
  nullable    = false
  default     = false
}

variable "enable_private_endpoints" {
  description = "When true with enable_private_networking, creates private endpoints for platform services."
  type        = bool
  nullable    = false
  default     = false
}

variable "public_network_access_enabled" {
  description = "When true, allows public network access on Key Vault, Storage, and PostgreSQL when not VNet-integrated."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_governance" {
  description = "When true, enables Azure Policy assignments and cost budgets for stage governance."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_diagnostics" {
  description = "When true, sends platform resource logs and metrics to Log Analytics."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_monitoring" {
  description = "When true, deploys action groups and metric alerts for platform services."
  type        = bool
  nullable    = false
  default     = true
}

# --- Governance ----------------------------------------------------------------

variable "budget_amount" {
  description = "Monthly budget amount in USD for the platform resource group."
  type        = number
  nullable    = false
  default     = 500

  validation {
    condition     = var.budget_amount > 0
    error_message = "budget_amount must be greater than zero."
  }
}

variable "budget_contact_emails" {
  description = "Email addresses notified when budget thresholds are exceeded."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "alert_contact_emails" {
  description = "Email addresses notified by Azure Monitor action groups."
  type        = list(string)
  nullable    = false
  default     = []
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
  description = "API container image tag to deploy. Pin immutable tags for stage promotion."
  type        = string
  nullable    = false
  default     = "stage"
}

variable "worker_image_name" {
  description = "Worker/beat container image repository name within ACR."
  type        = string
  nullable    = false
  default     = "cloud-content-hub-worker"
}

variable "worker_image_tag" {
  description = "Worker/beat container image tag to deploy."
  type        = string
  nullable    = false
  default     = "stage"
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

variable "container_ingress_external_enabled" {
  description = "When true, exposes the API Container App through external HTTPS ingress."
  type        = bool
  nullable    = false
  default     = true
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
  default     = 4

  validation {
    condition     = var.celery_concurrency >= 1 && var.celery_concurrency <= 32
    error_message = "celery_concurrency must be between 1 and 32."
  }
}
