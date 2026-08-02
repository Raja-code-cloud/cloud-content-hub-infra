# ------------------------------------------------------------------------------
# Diagnostic Settings Module — Outputs
# ------------------------------------------------------------------------------

output "diagnostic_setting_ids" {
  description = "Map of diagnostic setting keys to Azure diagnostic setting resource IDs."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.this : key => setting.id }
}

output "diagnostic_setting_names" {
  description = "Map of diagnostic setting keys to diagnostic setting names."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.this : key => setting.name }
}

output "target_resource_ids" {
  description = "Map of diagnostic setting keys to target resource IDs."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.this : key => setting.target_resource_id }
}

output "diagnostic_settings" {
  description = "Non-sensitive diagnostic setting metadata for downstream module composition."
  value = {
    for key, setting in azurerm_monitor_diagnostic_setting.this :
    key => {
      id                         = setting.id
      name                       = setting.name
      target_resource_id         = setting.target_resource_id
      log_analytics_workspace_id = setting.log_analytics_workspace_id
      storage_account_id         = setting.storage_account_id
      eventhub_name              = setting.eventhub_name
    }
  }
}
