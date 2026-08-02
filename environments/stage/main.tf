# ------------------------------------------------------------------------------
# Root Module — stage
# ------------------------------------------------------------------------------

module "common" {
  source = "../../modules/common"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  location_short   = var.location_short
  resource_prefix  = var.resource_prefix
  owner            = var.owner
  business_unit    = var.business_unit
  cost_center      = var.cost_center
  repository_name  = var.repository_name
  managed_by       = var.managed_by
  created_by       = var.created_by
  tags             = var.tags
  additional_tags  = var.additional_tags
}
