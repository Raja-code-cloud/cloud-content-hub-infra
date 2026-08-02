# ------------------------------------------------------------------------------
# Action Group Module — Outputs
# ------------------------------------------------------------------------------

output "action_group_ids" {
  description = "Map of action group keys to Azure action group resource IDs."
  value       = { for key, group in azurerm_monitor_action_group.this : key => group.id }
}

output "action_group_names" {
  description = "Map of action group keys to action group names."
  value       = { for key, group in azurerm_monitor_action_group.this : key => group.name }
}

output "short_names" {
  description = "Map of action group keys to short names used in SMS notifications."
  value       = { for key, group in azurerm_monitor_action_group.this : key => group.short_name }
}

output "action_groups" {
  description = "Non-sensitive action group metadata for downstream module composition."
  value = {
    for key, group in azurerm_monitor_action_group.this :
    key => {
      id                  = group.id
      name                = group.name
      resource_group_name = group.resource_group_name
      short_name          = group.short_name
      enabled             = group.enabled
    }
  }
}
