# ------------------------------------------------------------------------------
# Container Apps Environment Module
#
# Creates exactly one Azure Container Apps Environment.
# Does NOT create container apps, Dapr components, certificates, private endpoints,
# diagnostic settings, or role assignments.
# See: modules/container-app-environment/README.md
# ------------------------------------------------------------------------------

resource "azurerm_container_app_environment" "this" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  logs_destination               = local.logs_destination
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  tags                           = var.tags

  dynamic "workload_profile" {
    for_each = local.workload_profiles

    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = try(workload_profile.value.minimum_count, null)
      maximum_count         = try(workload_profile.value.maximum_count, null)
    }
  }
}

check "internal_load_balancer_requires_subnet" {
  assert {
    condition     = !var.internal_load_balancer_enabled || var.infrastructure_subnet_id != null
    error_message = "infrastructure_subnet_id is required when internal_load_balancer_enabled is true."
  }
}

check "workload_profiles_required_when_enabled" {
  assert {
    condition     = !var.workload_profile_enabled || length(var.workload_profiles) > 0
    error_message = "At least one workload profile must be defined when workload_profile_enabled is true."
  }
}

check "vnet_integration_requires_subnet" {
  assert {
    condition     = var.infrastructure_subnet_id != null || !var.zone_redundancy_enabled
    error_message = "infrastructure_subnet_id is required when zone_redundancy_enabled is true."
  }
}
