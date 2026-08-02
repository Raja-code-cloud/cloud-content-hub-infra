# ------------------------------------------------------------------------------
# Application Insights Module
#
# Creates exactly one workspace-based Azure Application Insights resource.
# Does NOT create alerts, diagnostic settings, availability tests, or workbooks.
# See: modules/application-insights/README.md
# ------------------------------------------------------------------------------

resource "azurerm_application_insights" "this" {
  name                                = var.application_insights_name
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  workspace_id                        = var.workspace_id
  application_type                    = var.application_type
  sampling_percentage                 = var.sampling_percentage
  ip_masking_enabled                  = local.ip_masking_enabled
  internet_ingestion_enabled          = var.internet_ingestion_enabled
  internet_query_enabled              = var.internet_query_enabled
  local_authentication_enabled        = local.local_authentication_enabled
  force_customer_storage_for_profiler = var.force_customer_storage_for_profiler
  tags                                = var.tags
}
