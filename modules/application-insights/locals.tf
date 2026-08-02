# ------------------------------------------------------------------------------
# Application Insights Module — Locals
# ------------------------------------------------------------------------------

locals {
  ip_masking_enabled           = !var.disable_ip_masking
  local_authentication_enabled = !var.local_authentication_disabled
}
