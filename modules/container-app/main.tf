# ------------------------------------------------------------------------------
# Container App Module
#
# Creates exactly one Azure Container App.
# Does NOT create DNS, certificates, RBAC, diagnostic settings, or private endpoints.
# See: modules/container-app/README.md
# ------------------------------------------------------------------------------

resource "azurerm_container_app" "this" {
  name                         = var.container_app_name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = var.revision_mode
  workload_profile_name        = var.workload_profile_name
  max_inactive_revisions       = var.max_inactive_revisions
  tags                         = var.tags

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "secret" {
    for_each = concat(
      var.secrets,
      var.observability != null && try(var.observability.application_insights_connection_string, null) != null ? [{
        name  = local.application_insights_secret_name
        value = var.observability.application_insights_connection_string
      }] : [],
    )

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

  dynamic "dapr" {
    for_each = var.dapr.enabled ? [var.dapr] : []

    content {
      app_id       = dapr.value.app_id
      app_port     = try(dapr.value.app_port, null)
      app_protocol = try(dapr.value.app_protocol, "http")
    }
  }

  dynamic "ingress" {
    for_each = local.ingress_enabled ? [var.ingress] : []

    content {
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      exposed_port               = try(ingress.value.exposed_port, null)
      transport                  = try(ingress.value.transport, "auto")
      allow_insecure_connections = try(ingress.value.allow_insecure_connections, false)
      client_certificate_mode    = try(ingress.value.client_certificate_mode, null)

      dynamic "traffic_weight" {
        for_each = local.ingress_traffic_weights

        content {
          latest_revision = try(traffic_weight.value.latest_revision, null)
          percentage      = traffic_weight.value.percentage
          label           = try(traffic_weight.value.label, null)
          revision_suffix = try(traffic_weight.value.revision_suffix, null)
        }
      }

      dynamic "cors" {
        for_each = try(ingress.value.cors, null) != null ? [ingress.value.cors] : []

        content {
          allowed_origins           = cors.value.allowed_origins
          allow_credentials_enabled = try(cors.value.allow_credentials_enabled, false)
          allowed_headers           = try(cors.value.allowed_headers, null)
          allowed_methods           = try(cors.value.allowed_methods, null)
          exposed_headers           = try(cors.value.exposed_headers, null)
          max_age_in_seconds        = try(cors.value.max_age_in_seconds, null)
        }
      }

      dynamic "ip_security_restriction" {
        for_each = coalesce(try(ingress.value.ip_security_restrictions, []), [])

        content {
          name             = ip_security_restriction.value.name
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.ip_address_range
          description      = try(ip_security_restriction.value.description, null)
        }
      }
    }
  }

  template {
    min_replicas                     = var.scale.min_replicas
    max_replicas                     = var.scale.max_replicas
    cooldown_period_in_seconds       = try(var.scale.cooldown_period_in_seconds, null)
    polling_interval_in_seconds      = try(var.scale.polling_interval_in_seconds, null)
    revision_suffix                  = try(var.scale.revision_suffix, null)
    termination_grace_period_seconds = try(var.scale.termination_grace_period_seconds, null)

    dynamic "init_container" {
      for_each = var.init_containers

      content {
        name    = init_container.value.name
        image   = init_container.value.image
        cpu     = try(init_container.value.cpu, null)
        memory  = try(init_container.value.memory, null)
        args    = try(init_container.value.args, null)
        command = try(init_container.value.command, null)

        dynamic "env" {
          for_each = init_container.value.env

          content {
            name        = env.value.name
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }

        dynamic "volume_mounts" {
          for_each = init_container.value.volume_mounts

          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = try(volume_mounts.value.sub_path, null)
          }
        }
      }
    }

    dynamic "container" {
      for_each = local.containers_with_observability

      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        args    = try(container.value.args, null)
        command = try(container.value.command, null)

        dynamic "env" {
          for_each = container.value.env

          content {
            name        = env.value.name
            value       = try(env.value.value, null)
            secret_name = try(env.value.secret_name, null)
          }
        }

        dynamic "liveness_probe" {
          for_each = try(container.value.liveness_probe, null) != null ? [container.value.liveness_probe] : []

          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            path                    = try(liveness_probe.value.path, null)
            host                    = try(liveness_probe.value.host, null)
            initial_delay           = try(liveness_probe.value.initial_delay, null)
            interval_seconds        = try(liveness_probe.value.interval_seconds, null)
            timeout                 = try(liveness_probe.value.timeout, null)
            failure_count_threshold = try(liveness_probe.value.failure_count_threshold, null)

            dynamic "header" {
              for_each = coalesce(try(liveness_probe.value.headers, []), [])

              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "readiness_probe" {
          for_each = try(container.value.readiness_probe, null) != null ? [container.value.readiness_probe] : []

          content {
            transport               = readiness_probe.value.transport
            port                    = readiness_probe.value.port
            path                    = try(readiness_probe.value.path, null)
            host                    = try(readiness_probe.value.host, null)
            initial_delay           = try(readiness_probe.value.initial_delay, null)
            interval_seconds        = try(readiness_probe.value.interval_seconds, null)
            timeout                 = try(readiness_probe.value.timeout, null)
            failure_count_threshold = try(readiness_probe.value.failure_count_threshold, null)
            success_count_threshold = try(readiness_probe.value.success_count_threshold, null)

            dynamic "header" {
              for_each = coalesce(try(readiness_probe.value.headers, []), [])

              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "startup_probe" {
          for_each = try(container.value.startup_probe, null) != null ? [container.value.startup_probe] : []

          content {
            transport               = startup_probe.value.transport
            port                    = startup_probe.value.port
            path                    = try(startup_probe.value.path, null)
            host                    = try(startup_probe.value.host, null)
            initial_delay           = try(startup_probe.value.initial_delay, null)
            interval_seconds        = try(startup_probe.value.interval_seconds, null)
            timeout                 = try(startup_probe.value.timeout, null)
            failure_count_threshold = try(startup_probe.value.failure_count_threshold, null)

            dynamic "header" {
              for_each = coalesce(try(startup_probe.value.headers, []), [])

              content {
                name  = header.value.name
                value = header.value.value
              }
            }
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts

          content {
            name     = volume_mounts.value.name
            path     = volume_mounts.value.path
            sub_path = try(volume_mounts.value.sub_path, null)
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.scale.http_rules

      content {
        name                = http_scale_rule.value.name
        concurrent_requests = tostring(http_scale_rule.value.concurrent_requests)

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "tcp_scale_rule" {
      for_each = var.scale.tcp_rules

      content {
        name                = tcp_scale_rule.value.name
        concurrent_requests = tostring(tcp_scale_rule.value.concurrent_requests)

        dynamic "authentication" {
          for_each = tcp_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = var.scale.custom_rules

      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
        identity_id      = try(custom_scale_rule.value.identity_id, null)

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "azure_queue_scale_rule" {
      for_each = var.scale.azure_queue_rules

      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.queue_name
        queue_length = azure_queue_scale_rule.value.queue_length

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication

          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "volume" {
      for_each = var.volumes

      content {
        name          = volume.value.name
        storage_type  = volume.value.storage_type
        storage_name  = try(volume.value.storage_name, null)
        mount_options = try(volume.value.mount_options, null)
      }
    }
  }

  lifecycle {
    ignore_changes = [
      secret,
    ]
  }
}

check "secret_lifecycle_ignore_required" {
  assert {
    condition     = var.lifecycle_options.ignore_secret_values
    error_message = "lifecycle_options.ignore_secret_values must be true when using Key Vault secret references."
  }
}

check "ingress_required_for_external_http_scaling" {
  assert {
    condition     = length(var.scale.http_rules) == 0 || local.ingress_enabled
    error_message = "HTTP scale rules require ingress to be configured."
  }
}

check "dapr_requires_ingress_port_when_enabled" {
  assert {
    condition = (
      !var.dapr.enabled ||
      try(var.dapr.app_port, null) != null ||
      (local.ingress_enabled && try(var.ingress.target_port, null) != null)
    )
    error_message = "dapr.app_port must be specified when ingress is not configured."
  }
}

check "multiple_revision_traffic_weights" {
  assert {
    condition = (
      var.revision_mode != "Multiple" ||
      !local.ingress_enabled ||
      length(local.ingress_traffic_weights) > 0
    )
    error_message = "At least one ingress traffic weight is required when revision_mode is Multiple."
  }
}

check "traffic_weight_percentage_total" {
  assert {
    condition = (
      !local.ingress_enabled ||
      var.revision_mode != "Multiple" ||
      sum([for weight in local.ingress_traffic_weights : weight.percentage]) == 100
    )
    error_message = "Ingress traffic weight percentages must sum to exactly 100 when revision_mode is Multiple."
  }
}

check "registry_identity_requires_user_assigned" {
  assert {
    condition = alltrue([
      for registry in var.registries :
      registry.identity == null || (
        var.identity != null && contains(["UserAssigned", "SystemAssigned, UserAssigned"], var.identity.type)
      )
    ])
    error_message = "Registry identity authentication requires a UserAssigned or SystemAssigned, UserAssigned managed identity on the Container App."
  }
}

check "observability_secret_reference_exists" {
  assert {
    condition = (
      var.observability == null ||
      try(var.observability.application_insights_connection_string, null) != null ||
      try(var.observability.application_insights_connection_string_secret_name, null) == null ||
      contains(
        concat(
          [for secret in var.secrets : secret.name],
          var.observability != null && try(var.observability.application_insights_connection_string, null) != null ? [local.application_insights_secret_name] : [],
        ),
        var.observability.application_insights_connection_string_secret_name
      )
    )
    error_message = "application_insights_connection_string_secret_name must reference a secret defined in secrets or supplied via observability.application_insights_connection_string."
  }
}
