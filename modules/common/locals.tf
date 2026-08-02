# ------------------------------------------------------------------------------
# Common Module — Locals
# ------------------------------------------------------------------------------

locals {
  computed_resource_prefix = coalesce(var.resource_prefix, module.naming.resource_prefix)

  base_tags = {
    Project      = var.project_name
    Application  = var.application_name
    Environment  = var.environment
    Owner        = var.owner
    ManagedBy    = var.managed_by
    Repository   = var.repository_name
    Terraform    = "true"
    CostCenter   = var.cost_center
    BusinessUnit = var.business_unit
    CreatedBy    = var.created_by
  }

  merged_tags = merge(
    local.base_tags,
    var.additional_tags,
    var.tags,
  )

  environment_abbreviations = {
    dev   = "dev"
    stage = "stg"
    prod  = "prd"
  }

  environment_short = local.environment_abbreviations[var.environment]

  standard_labels = merge(
    module.naming.standard_labels,
    {
      owner         = var.owner
      business_unit = var.business_unit
      cost_center   = var.cost_center
      repository    = var.repository_name
      managed_by    = var.managed_by
      created_by    = var.created_by
    }
  )

  required_tag_keys = [
    "Project",
    "Application",
    "Environment",
    "Owner",
    "ManagedBy",
    "CostCenter",
    "BusinessUnit",
  ]

  required_tags_valid = var.enforce_required_tags ? alltrue([
    for key in local.required_tag_keys : lookup(local.merged_tags, key, "") != ""
  ]) : true
}
