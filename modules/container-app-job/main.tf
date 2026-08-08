# ------------------------------------------------------------------------------
# Container App Job Module
#
# Creates exactly one Azure Container Apps Job (manual trigger).
# Intended for database migrations and other one-shot operational tasks.
# Does NOT create the Container Apps Environment, RBAC, or diagnostics.
# ------------------------------------------------------------------------------

resource "azurerm_container_app_job" "this" {
  name                         = var.job_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  replica_retry_limit          = var.replica_retry_limit
  workload_profile_name        = var.workload_profile_name
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "secret" {
    for_each = var.secrets

    content {
      name                = secret.value.name
      value               = try(secret.value.key_vault_secret_id, null) == null ? secret.value.value : null
      key_vault_secret_id = try(secret.value.key_vault_secret_id, null)
      identity            = try(secret.value.identity, null)
    }
  }

  dynamic "registry" {
    for_each = var.registries

    content {
      server               = registry.value.server
      identity             = try(registry.value.identity, null)
      username             = try(registry.value.username, null)
      password_secret_name = try(registry.value.password_secret_name, null)
    }
  }

  manual_trigger_config {
    parallelism              = var.manual_trigger.parallelism
    replica_completion_count = var.manual_trigger.replica_completion_count
  }

  template {
    dynamic "container" {
      for_each = var.containers

      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        command = try(container.value.command, null)
        args    = try(container.value.args, null)

        dynamic "env" {
          for_each = container.value.env

          content {
            name        = env.value.name
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      secret,
    ]
  }
}
