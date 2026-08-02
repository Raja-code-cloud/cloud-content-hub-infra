# ------------------------------------------------------------------------------
# Common Module
#
# Shared naming, tagging, and metadata for all platform modules.
# No Azure resources are created.
# See: docs/terraform/shared-foundation.md
# ------------------------------------------------------------------------------

module "naming" {
  source = "../naming"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  location_short   = var.location_short
  resources        = var.standard_resource_names
}
