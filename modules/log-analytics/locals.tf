# ------------------------------------------------------------------------------
# Log Analytics Module — Locals
# ------------------------------------------------------------------------------

locals {
  is_free_sku = var.sku == "Free"

  internet_ingestion_access_type = var.internet_ingestion_enabled ? "Enabled" : "Disabled"
  internet_query_access_type     = var.internet_query_enabled ? "Enabled" : "Disabled"
}
