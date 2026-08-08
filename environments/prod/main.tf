# ------------------------------------------------------------------------------
# Root Module — prod
#
# Composes reusable platform modules for the production environment.
# No Azure resources are defined directly in this root module.
# Environment-specific values are centralized in locals.tf.
# ------------------------------------------------------------------------------

module "common" {
  source = "../../modules/common"

  project_name            = var.project_name
  application_name        = var.application_name
  environment             = var.environment
  location                = var.location
  location_short          = var.location_short
  resource_prefix         = var.resource_prefix
  owner                   = var.owner
  business_unit           = var.business_unit
  cost_center             = var.cost_center
  repository_name         = var.repository_name
  managed_by              = var.managed_by
  created_by              = var.created_by
  tags                    = var.tags
  additional_tags         = local.prod_additional_tags
  standard_resource_names = local.standard_resource_names
  enforce_required_tags   = true
}

# --- Foundation ----------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name                 = module.common.resource_names["resource_group"]
  location             = module.common.location
  tags                 = module.common.tags
  create_resource_lock = true
  lock_level           = "CanNotDelete"
  lock_notes           = "Production platform resource group — managed by Terraform."
}

module "networking" {
  count  = local.networking_enabled ? 1 : 0
  source = "../../modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  vnet_name           = module.common.resource_names["vnet"]
  address_space       = local.network_address_space
  tags                = module.common.tags
  subnets             = local.networking_subnet_definitions
}

module "private_dns" {
  count  = local.networking_enabled ? 1 : 0
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    for zone_name in local.private_dns_zone_names : {
      name = zone_name
    }
  ]

  virtual_network_links = [
    for zone_name in local.private_dns_zone_names : {
      key       = "${replace(zone_name, ".", "-")}-link"
      zone_name = zone_name
      link_name = "${module.common.resource_prefix}-${replace(zone_name, ".", "-")}-link"
      vnet_id   = module.networking[0].vnet_id
    }
  ]

  depends_on = [module.networking]
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  workspace_name      = module.common.resource_names["log_analytics"]
  tags                = module.common.tags

  daily_quota_gb    = local.sizing.log_analytics_daily_quota_gb
  retention_in_days = local.sizing.log_analytics_retention_days
}

module "application_insights" {
  source = "../../modules/application-insights"

  application_insights_name = module.common.resource_names["app_insights"]
  resource_group_name       = module.resource_group.name
  location                  = module.common.location
  workspace_id              = module.log_analytics.workspace_resource_id
  tags                      = module.common.tags

  sampling_percentage = local.sizing.app_insights_sampling

  depends_on = [module.log_analytics]
}

module "managed_identity" {
  source = "../../modules/managed-identity"

  identity_name       = module.common.resource_names["identity"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags
}

# --- Data & Registry -----------------------------------------------------------

module "acr" {
  source = "../../modules/acr"

  registry_name       = module.common.resource_names["acr"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  admin_enabled                 = false
  sku                           = local.sizing.acr_sku
  zone_redundancy_enabled       = local.sizing.acr_zone_redundancy
  public_network_access_enabled = local.acr_public_access_enabled
}

module "key_vault" {
  source = "../../modules/key-vault"

  vault_name          = module.common.resource_names["key_vault"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  purge_protection_enabled      = local.sizing.key_vault_purge_protection
  public_network_access_enabled = local.networking_enabled ? false : var.public_network_access_enabled
}

module "storage" {
  source = "../../modules/storage"

  storage_account_name          = module.common.resource_names["storage"]
  resource_group_name           = module.resource_group.name
  location                      = module.common.location
  tags                          = module.common.tags
  account_replication_type      = local.sizing.storage_replication_type
  min_tls_version               = local.sizing.storage_min_tls_version
  https_traffic_only_enabled    = true
  public_network_access_enabled = local.networking_enabled ? false : var.public_network_access_enabled
  network_rules = local.networking_enabled ? {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [module.networking[0].subnet_ids["private-endpoints"]]
  } : null
}

module "storage_containers" {
  source = "../../modules/storage-containers"

  storage_account_name  = module.storage.name
  storage_account_id    = module.storage.resource_id
  primary_blob_endpoint = module.storage.primary_blob_endpoint
  tags                  = module.common.tags
  containers            = local.storage_containers

  depends_on = [module.storage]
}

module "postgresql_flexible_server" {
  source = "../../modules/postgresql-flexible-server"

  server_name            = module.common.resource_names["postgres"]
  resource_group_name    = module.resource_group.name
  location               = module.common.location
  administrator_login    = var.postgresql_administrator_login
  administrator_password = var.postgresql_admin_password
  tags                   = module.common.tags

  sku_name                      = local.sizing.postgres_sku
  storage_mb                    = local.sizing.postgres_storage_mb
  backup_retention_days         = local.sizing.postgres_backup_retention_days
  geo_redundant_backup_enabled  = local.sizing.postgres_geo_redundant_backup
  high_availability_mode        = local.sizing.postgres_high_availability_mode
  public_network_access_enabled = local.postgres_public_access_enabled
  delegated_subnet_id           = local.networking_enabled ? module.networking[0].subnet_ids["postgres"] : null
  private_dns_zone_id           = local.networking_enabled ? module.private_dns[0].zone_ids["privatelink.postgres.database.azure.com"] : null

  depends_on = [module.networking, module.private_dns]
}

module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags
  databases   = local.postgresql_databases

  depends_on = [module.postgresql_flexible_server]
}

module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id      = module.postgresql_flexible_server.id
  server_name    = module.postgresql_flexible_server.name
  configurations = local.postgresql_configurations

  depends_on = [module.postgresql_flexible_server]
}

module "redis" {
  source = "../../modules/redis"

  redis_cache_name    = module.common.resource_names["redis"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku_name                      = local.sizing.redis_sku_name
  family                        = local.sizing.redis_family
  capacity                      = local.sizing.redis_capacity
  public_network_access_enabled = !local.private_endpoints_enabled
}

# --- Compute Platform ----------------------------------------------------------

module "container_app_environment" {
  source = "../../modules/container-app-environment"

  environment_name           = module.common.resource_names["cae"]
  resource_group_name        = module.resource_group.name
  location                   = module.common.location
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
  tags                       = module.common.tags
  infrastructure_subnet_id   = local.networking_enabled ? module.networking[0].subnet_ids["container-apps"] : null

  depends_on = [module.log_analytics, module.networking]
}

# --- Private Connectivity ------------------------------------------------------

module "private_endpoint" {
  count  = local.private_endpoints_enabled ? 1 : 0
  source = "../../modules/private-endpoint"

  tags              = module.common.tags
  private_endpoints = local.private_endpoint_definitions

  depends_on = [
    module.networking,
    module.private_dns,
    module.key_vault,
    module.storage,
    module.acr,
    module.postgresql_flexible_server,
    module.redis,
  ]
}

# --- RBAC ----------------------------------------------------------------------

module "role_assignment" {
  source = "../../modules/role-assignment"

  assignments = local.role_assignments

  depends_on = [
    module.managed_identity,
    module.acr,
    module.key_vault,
    module.storage,
  ]
}

# --- Secrets -------------------------------------------------------------------

module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id
  secrets      = local.key_vault_secrets

  depends_on = [
    module.key_vault,
    module.role_assignment,
    module.application_insights,
    module.postgresql_flexible_server,
    module.redis,
  ]
}

# --- Governance ----------------------------------------------------------------

module "policy_initiative" {
  source = "../../modules/policy-initiative"

  initiatives = local.feature_flags.enable_governance ? local.policy_initiatives : []
}

module "policy_assignment" {
  source = "../../modules/policy-assignment"

  assignments = local.feature_flags.enable_governance ? local.policy_assignments : []

  depends_on = [module.policy_initiative]
}

module "budget" {
  source = "../../modules/budget"

  budgets = local.feature_flags.enable_budget ? local.budgets : []
}

# --- Observability -------------------------------------------------------------

module "action_group" {
  source = "../../modules/action-group"

  action_groups = local.feature_flags.enable_monitoring ? local.action_groups : []
}

module "monitor_alerts" {
  source = "../../modules/monitor-alerts"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags
  action_group_ids    = local.feature_flags.enable_monitoring ? [module.action_group.action_group_ids["platform"]] : []
  metric_alerts       = local.feature_flags.enable_monitoring ? local.metric_alerts : []

  depends_on = [
    module.action_group,
    module.postgresql_flexible_server,
  ]
}

module "diagnostic_settings" {
  source = "../../modules/diagnostic-settings"

  diagnostic_settings = local.feature_flags.enable_diagnostics ? local.diagnostic_settings : []

  depends_on = [
    module.log_analytics,
    module.key_vault,
    module.storage,
    module.postgresql_flexible_server,
  ]
}

# --- Application ---------------------------------------------------------------

module "container_app" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["api"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  secrets = local.container_app_key_vault_secret_refs

  containers = [{
    name            = "api"
    image           = local.api_container_image
    cpu             = local.sizing.container_cpu
    memory          = local.sizing.container_memory
    env             = local.api_env
    liveness_probe  = local.api_probes.liveness
    readiness_probe = local.api_probes.readiness
  }]

  scale = {
    min_replicas = local.sizing.container_min_replicas
    max_replicas = local.sizing.container_max_replicas
    http_rules = [{
      name                = "http-scaling"
      concurrent_requests = local.sizing.container_scale_concurrency
    }]
  }

  ingress = {
    external_enabled           = var.container_ingress_external_enabled
    target_port                = var.container_target_port
    transport                  = "http"
    allow_insecure_connections = false
  }

  observability = {
    application_insights_connection_string_secret_name = local.app_insights_secret_name
  }

  depends_on = [
    module.container_app_environment,
    module.role_assignment,
    module.key_vault_secrets,
    module.acr,
    module.managed_identity,
  ]
}

module "container_app_worker" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["worker"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  secrets = [
    {
      name                = "database-url"
      key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids["cch-database-url"]
      identity            = module.managed_identity.resource_id
    },
    {
      name                = "redis-url"
      key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids["cch-redis-url"]
      identity            = module.managed_identity.resource_id
    },
  ]

  containers = [{
    name   = "worker"
    image  = local.worker_container_image
    cpu    = local.sizing.worker_cpu
    memory = local.sizing.worker_memory
    env    = local.worker_env
  }]

  scale = {
    min_replicas = local.sizing.worker_min_replicas
    max_replicas = local.sizing.worker_max_replicas
  }

  ingress = null

  depends_on = [
    module.container_app_environment,
    module.role_assignment,
    module.key_vault_secrets,
    module.acr,
    module.managed_identity,
  ]
}

module "container_app_beat" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["beat"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  secrets = [
    {
      name                = "redis-url"
      key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids["cch-redis-url"]
      identity            = module.managed_identity.resource_id
    },
  ]

  containers = [{
    name    = "beat"
    image   = local.worker_container_image
    cpu     = local.sizing.beat_cpu
    memory  = local.sizing.beat_memory
    command = ["celery"]
    args = [
      "--app",
      "cloud_content_hub.workers.runtime:celery_app",
      "beat",
      "--loglevel",
      var.cch_log_level,
      "--schedule",
      "/tmp/celerybeat-schedule",
    ]
    env = local.beat_env
  }]

  scale = {
    min_replicas = 1
    max_replicas = 1
  }

  ingress = null

  depends_on = [
    module.container_app_environment,
    module.role_assignment,
    module.key_vault_secrets,
    module.acr,
    module.managed_identity,
  ]
}

module "container_app_job_migrate" {
  source = "../../modules/container-app-job"

  job_name                     = module.common.resource_names["migrate"]
  resource_group_name          = module.resource_group.name
  location                     = module.common.location
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  secrets = local.migration_job_key_vault_secret_refs

  containers = [{
    name    = "migrate"
    image   = local.api_container_image
    cpu     = 0.5
    memory  = "1.0Gi"
    command = ["alembic"]
    args    = ["upgrade", "head"]
    env     = local.migrate_env
  }]

  depends_on = [
    module.container_app_environment,
    module.role_assignment,
    module.key_vault_secrets,
    module.postgresql_database,
    module.acr,
    module.managed_identity,
  ]
}
