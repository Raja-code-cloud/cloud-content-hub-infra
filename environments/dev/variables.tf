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

# --- Container App -------------------------------------------------------------

variable "container_image_name" {
  description = "Container image repository name within ACR (without registry prefix or tag)."
  type        = string
  nullable    = false
  default     = "api"
}

variable "container_image_tag" {
  description = "Container image tag to deploy."
  type        = string
  nullable    = false
  default     = "latest"
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
