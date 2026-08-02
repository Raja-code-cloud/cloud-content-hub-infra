# ------------------------------------------------------------------------------
# Log Analytics Workspace Module
#
# Creates exactly one Azure Log Analytics Workspace.
# See: modules/log-analytics/README.md
# ------------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "this" {
  name                           = var.workspace_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  sku                            = var.sku
  retention_in_days              = var.retention_in_days
  daily_quota_gb                 = var.daily_quota_gb
  internet_ingestion_access_type = local.internet_ingestion_access_type
  internet_query_access_type     = local.internet_query_access_type
  tags                           = var.tags
}

check "retention_matches_sku" {
  assert {
    condition = (
      local.is_free_sku && var.retention_in_days == 7
      ) || (
      !local.is_free_sku && var.retention_in_days >= 30 && var.retention_in_days <= 730
    )
    error_message = "Free SKU requires retention_in_days = 7. Paid SKUs require retention_in_days between 30 and 730."
  }
}
