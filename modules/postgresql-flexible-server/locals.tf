# ------------------------------------------------------------------------------
# PostgreSQL Flexible Server Module — Locals
# ------------------------------------------------------------------------------

locals {
  high_availability_enabled = var.high_availability_mode != "Disabled"
  vnet_integrated           = var.delegated_subnet_id != null
}
