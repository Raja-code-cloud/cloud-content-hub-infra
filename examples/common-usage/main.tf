# Example — shared foundation consumption (no Azure resources)

variable "project_name" {
  description = "Short project identifier."
  type        = string
  nullable    = false
  default     = "cch"
}

variable "application_name" {
  description = "Application identifier."
  type        = string
  nullable    = false
  default     = "cloud-content-hub"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  nullable    = false
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  nullable    = false
  default     = "eastus"
}

variable "owner" {
  description = "Resource owner."
  type        = string
  nullable    = false
  default     = "platform-engineering"
}

variable "business_unit" {
  description = "Business unit."
  type        = string
  nullable    = false
  default     = "engineering"
}

variable "cost_center" {
  description = "Cost center."
  type        = string
  nullable    = false
  default     = "ENG-001"
}

module "common" {
  source = "../../modules/common"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  owner            = var.owner
  business_unit    = var.business_unit
  cost_center      = var.cost_center

  additional_tags = {
    Example = "common-usage"
  }
}

module "custom_name" {
  source = "../../modules/naming"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  resource_type    = "subnet"
  instance         = "aca"
}
