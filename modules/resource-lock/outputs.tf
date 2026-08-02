# ------------------------------------------------------------------------------
# Resource Lock Module — Outputs
# ------------------------------------------------------------------------------

output "lock_ids" {
  description = "Map of lock keys to Azure Management Lock resource IDs."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.id }
}

output "lock_names" {
  description = "Map of lock keys to management lock names."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.name }
}

output "scopes" {
  description = "Map of lock keys to management lock scopes."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.scope }
}

output "lock_levels" {
  description = "Map of lock keys to applied management lock levels."
  value       = { for key, lock in azurerm_management_lock.this : key => lock.lock_level }
}

output "locks" {
  description = "Non-sensitive management lock metadata for downstream module composition."
  value = {
    for key, lock in azurerm_management_lock.this :
    key => {
      id         = lock.id
      name       = lock.name
      scope      = lock.scope
      scope_type = local.scope_types[key]
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  }
}
