# ------------------------------------------------------------------------------
# Root Module — dev
#
# Composes all reusable platform modules for the development environment.
# No Azure resources are defined directly in this root module.
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
  additional_tags         = var.additional_tags
  standard_resource_names = local.standard_resource_names
}

# --- Foundation ----------------------------------------------------------------

module "resource_group" {
  source = "../../modules/resource-group"

  name     = module.common.resource_names["resource_group"]
  location = module.common.location
  tags     = module.common.tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  workspace_name      = module.common.resource_names["log_analytics"]
  tags                = module.common.tags

  daily_quota_gb    = 1
  retention_in_days = 30
}

module "application_insights" {
  source = "../../modules/application-insights"

  application_insights_name = module.common.resource_names["app_insights"]
  resource_group_name       = module.resource_group.name
  location                  = module.common.location
  workspace_id              = module.log_analytics.workspace_resource_id
  tags                      = module.common.tags

  sampling_percentage = 50

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

  admin_enabled = false
  sku           = "Basic"
}

module "key_vault" {
  source = "../../modules/key-vault"

  vault_name          = module.common.resource_names["key_vault"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  purge_protection_enabled = false
  sku_name                 = "standard"
}

module "storage" {
  source = "../../modules/storage"

  storage_account_name = module.common.resource_names["storage"]
  resource_group_name  = module.resource_group.name
  location             = module.common.location
  tags                 = module.common.tags
}

module "postgresql_flexible_server" {
  source = "../../modules/postgresql-flexible-server"

  server_name            = module.common.resource_names["postgres"]
  resource_group_name    = module.resource_group.name
  location               = module.common.location
  administrator_login    = var.postgresql_administrator_login
  administrator_password = var.postgresql_admin_password
  tags                   = module.common.tags

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
}

module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags
  databases   = local.postgresql_databases

  depends_on = [module.postgresql_flexible_server]
}

module "redis" {
  source = "../../modules/redis"

  redis_cache_name    = module.common.resource_names["redis"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku_name                      = "Basic"
  family                        = "C"
  capacity                      = 0
  public_network_access_enabled = true
}

# --- Compute Platform ----------------------------------------------------------

module "container_app_environment" {
  source = "../../modules/container-app-environment"

  environment_name           = module.common.resource_names["cae"]
  resource_group_name        = module.resource_group.name
  location                   = module.common.location
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
  tags                       = module.common.tags

  depends_on = [module.log_analytics]
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
    module.postgresql_flexible_server,
    module.redis,
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
    cpu             = 0.5
    memory          = "1.0Gi"
    env             = local.api_env
    liveness_probe  = local.api_probes.liveness
    readiness_probe = local.api_probes.readiness
  }]

  scale = {
    min_replicas = 0
    max_replicas = 3
    http_rules = [{
      name                = "http-scaling"
      concurrent_requests = 30
    }]
  }

  ingress = {
    external_enabled = true
    target_port      = var.container_target_port
    transport        = "http"
  }

  observability = {
    application_insights_connection_string = module.application_insights.connection_string
  }

  depends_on = [
    module.container_app_environment,
    module.role_assignment,
    module.key_vault_secrets,
    module.application_insights,
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

  secrets = local.container_app_key_vault_secret_refs

  containers = [{
    name   = "worker"
    image  = local.worker_container_image
    cpu    = 0.5
    memory = "1.0Gi"
    env    = local.worker_env
  }]

  scale = {
    min_replicas = 0
    max_replicas = 3
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
    cpu     = 0.25
    memory  = "0.5Gi"
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
