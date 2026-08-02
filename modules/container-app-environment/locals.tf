# ------------------------------------------------------------------------------
# Container Apps Environment Module — Locals
# ------------------------------------------------------------------------------

locals {
  logs_destination  = "log-analytics"
  workload_profiles = var.workload_profile_enabled ? var.workload_profiles : []
}
