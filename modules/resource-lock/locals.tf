# ------------------------------------------------------------------------------
# Resource Lock Module — Locals
# ------------------------------------------------------------------------------

locals {
  locks = {
    for lock in var.locks : lock.key => {
      name       = lock.name
      scope      = lock.scope
      lock_level = try(lock.lock_level, "CanNotDelete")
      notes      = try(lock.notes, null)
    }
  }

  scope_types = {
    for key, lock in local.locks :
    key => (
      can(regex("^/subscriptions/[0-9a-f-]{36}$", lock.scope)) ? "subscription" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+$", lock.scope)) ? "resource_group" :
      can(regex("^/subscriptions/[0-9a-f-]{36}/resourceGroups/[\\w\\(\\)\\.-]+/providers/.+$", lock.scope)) ? "resource" :
      "invalid"
    )
  }
}
