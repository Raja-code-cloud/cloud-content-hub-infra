# ------------------------------------------------------------------------------
# Container App Module - Locals
# ------------------------------------------------------------------------------

locals {
  normalized_containers = [
    for container in var.containers : merge(container, {
      image   = container.image_tag != null && !strcontains(container.image, ":") ? format("%s:%s", container.image, container.image_tag) : container.image
      command = coalesce(container.startup_command, container.command)
    })
  ]

  application_insights_secret_name = coalesce(
    try(var.observability.application_insights_connection_string_secret_name, null),
    coalesce(try(var.observability.application_insights_secret_name, null), "applicationinsights-connection-string")
  )

  application_insights_env = var.observability != null && (
    try(var.observability.application_insights_connection_string, null) != null ||
    try(var.observability.application_insights_connection_string_secret_name, null) != null
    ) ? [{
      name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
      secret_name = local.application_insights_secret_name
  }] : []

  containers_with_observability = length(local.normalized_containers) > 0 ? concat(
    [merge(local.normalized_containers[0], {
      env = concat(local.normalized_containers[0].env, local.application_insights_env)
    })],
    slice(local.normalized_containers, 1, length(local.normalized_containers))
  ) : []

  ingress_enabled = var.ingress != null && try(var.ingress.enabled, true)

  ingress_traffic_weights = local.ingress_enabled ? (
    length(try(var.ingress.traffic_weights, [])) > 0 ? var.ingress.traffic_weights : [{
      latest_revision = true
      percentage      = 100
      label           = null
      revision_suffix = null
    }]
  ) : []
}
