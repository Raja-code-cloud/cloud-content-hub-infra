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

# --- Container App -------------------------------------------------------------

variable "container_image_name" {
  description = "Container image repository name within ACR (without registry prefix or tag)."
  type        = string
  nullable    = false
  default     = "api"
}

variable "container_image_tag" {
  description = "Container image tag to deploy. Pin immutable tags for stage promotion."
  type        = string
  nullable    = false
  default     = "stage"
}

variable "container_target_port" {
  description = "Container port exposed through ingress."
  type        = number
  nullable    = false
  default     = 8080

  validation {
    condition     = var.container_target_port >= 1 && var.container_target_port <= 65535
    error_message = "container_target_port must be between 1 and 65535."
  }
}

variable "container_ingress_external_enabled" {
  description = "When true, exposes the Container App through external HTTPS ingress."
  type        = bool
  nullable    = false
  default     = true
}
