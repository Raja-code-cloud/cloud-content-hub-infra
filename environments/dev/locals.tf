# ------------------------------------------------------------------------------
# Local Values — dev
#
# Environment-specific derived values. Shared logic lives in modules/common.
# ------------------------------------------------------------------------------

locals {
  standard_resource_names = {
    resource_group = { resource_type = "resource_group" }
    log_analytics  = { resource_type = "log_analytics" }
    app_insights   = { resource_type = "app_insights" }
    identity       = { resource_type = "identity" }
    acr            = { resource_type = "acr" }
    key_vault      = { resource_type = "key_vault" }
    storage        = { resource_type = "storage" }
    postgres       = { resource_type = "postgres" }
    redis          = { resource_type = "redis" }
    cae            = { resource_type = "cae" }
    api            = { resource_type = "api" }
    worker         = { resource_type = "worker" }
    beat           = { resource_type = "beat" }
    migrate        = { resource_type = "migrate" }
  }

  postgresql_database_name = "cloud_content_hub"

  api_container_image    = "${module.acr.login_server}/${var.container_image_name}:${var.container_image_tag}"
  worker_container_image = "${module.acr.login_server}/${var.worker_image_name}:${var.worker_image_tag}"

  # Kept for backward-compatible outputs that previously referenced container_image.
  container_image = local.api_container_image

  cch_environment = var.cch_environment

  database_url = format(
    "postgresql+asyncpg://%s:%s@%s:5432/%s",
    var.postgresql_administrator_login,
    urlencode(var.postgresql_admin_password),
    module.postgresql_flexible_server.fqdn,
    local.postgresql_database_name,
  )

  migration_database_url = local.database_url

  storage_account_url = trimsuffix(module.storage.primary_blob_endpoint, "/")

  workload_role_assignments = [
    {
      key                  = "workload-acr-pull"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.acr.resource_id
      role_definition_name = "AcrPull"
      description          = "Allow workload identity to pull images from ACR"
    },
    {
      key                  = "workload-kv-secrets-user"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.key_vault.resource_id
      role_definition_name = "Key Vault Secrets User"
      description          = "Allow workload identity to read Key Vault secrets"
    },
    {
      key                  = "workload-storage-blob-contributor"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.storage.resource_id
      role_definition_name = "Storage Blob Data Contributor"
      description          = "Allow workload identity to read and write blob data"
    },
  ]

  deployer_role_assignments = var.deployment_principal_id != null ? [
    {
      key                  = "deployer-kv-secrets-officer"
      principal_id         = var.deployment_principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.key_vault.resource_id
      role_definition_name = "Key Vault Secrets Officer"
      description          = "Allow Terraform deployment identity to manage Key Vault secrets"
    },
  ] : []

  role_assignments = concat(local.workload_role_assignments, local.deployer_role_assignments)

  postgresql_databases = [
    {
      name            = local.postgresql_database_name
      prevent_destroy = false
    },
  ]

  key_vault_secrets = [
    {
      key          = "postgres-admin-password"
      name         = "postgres-admin-password"
      value        = var.postgresql_admin_password
      content_type = "password"
      tags = {
        purpose = "database"
        engine  = "postgresql"
      }
    },
    {
      key          = "api-key-placeholder"
      name         = "api-key-placeholder"
      value        = var.api_key_placeholder
      content_type = "api-key"
      tags = {
        purpose = "application"
      }
    },
    {
      key          = "cch-database-url"
      name         = "CCH-DATABASE-URL"
      value        = local.database_url
      content_type = "connection-string"
      tags = {
        purpose = "application"
        setting = "CCH_DATABASE_URL"
      }
    },
    {
      key          = "cch-redis-url"
      name         = "CCH-REDIS-URL"
      value        = module.redis.redis_url
      content_type = "connection-string"
      tags = {
        purpose = "application"
        setting = "CCH_REDIS_URL"
      }
    },
    {
      key          = "cch-migration-database-url"
      name         = "CCH-MIGRATION-DATABASE-URL"
      value        = local.migration_database_url
      content_type = "connection-string"
      tags = {
        purpose = "migration"
        setting = "CCH_DATABASE_URL"
      }
    },
  ]

  container_app_key_vault_secret_refs = [
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

  migration_job_key_vault_secret_refs = [
    {
      name                = "migration-database-url"
      key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids["cch-migration-database-url"]
      identity            = module.managed_identity.resource_id
    },
  ]

  cch_common_env = [
    {
      name  = "CCH_ENVIRONMENT"
      value = local.cch_environment
    },
    {
      name  = "CCH_SERVICE_VERSION"
      value = var.container_image_tag
    },
    {
      name  = "CCH_LOG_LEVEL"
      value = var.cch_log_level
    },
  ]

  api_env = concat(local.cch_common_env, [
    {
      name  = "CCH_OPENAPI_ENABLED"
      value = tostring(var.cch_openapi_enabled)
    },
    {
      name        = "CCH_DATABASE_URL"
      secret_name = "database-url"
    },
    {
      name        = "CCH_REDIS_URL"
      secret_name = "redis-url"
    },
    {
      name  = "CCH_HTTP_ALLOWED_ORIGINS"
      value = jsonencode(var.cch_http_allowed_origins)
    },
    {
      name  = "CCH_AZURE_STORAGE_ACCOUNT_URL"
      value = local.storage_account_url
    },
    {
      name  = "CCH_AZURE_STORAGE_CREDENTIAL_MODE"
      value = "managed_identity"
    },
    {
      name  = "CCH_AZURE_STORAGE_MANAGED_IDENTITY_CLIENT_ID"
      value = module.managed_identity.client_id
    },
    {
      name  = "PORT"
      value = tostring(var.container_target_port)
    },
  ])

  worker_env = concat(local.cch_common_env, [
    {
      name        = "CCH_DATABASE_URL"
      secret_name = "database-url"
    },
    {
      name        = "CCH_REDIS_URL"
      secret_name = "redis-url"
    },
    {
      name  = "CCH_AZURE_STORAGE_ACCOUNT_URL"
      value = local.storage_account_url
    },
    {
      name  = "CCH_AZURE_STORAGE_CREDENTIAL_MODE"
      value = "managed_identity"
    },
    {
      name  = "CCH_AZURE_STORAGE_MANAGED_IDENTITY_CLIENT_ID"
      value = module.managed_identity.client_id
    },
    {
      name  = "CELERY_CONCURRENCY"
      value = tostring(var.celery_concurrency)
    },
  ])

  beat_env = concat(local.cch_common_env, [
    {
      name        = "CCH_REDIS_URL"
      secret_name = "redis-url"
    },
  ])

  migrate_env = [
    {
      name  = "CCH_ENVIRONMENT"
      value = local.cch_environment
    },
    {
      name        = "CCH_DATABASE_URL"
      secret_name = "migration-database-url"
    },
  ]

  api_probes = {
    liveness = {
      transport               = "HTTP"
      port                    = var.container_target_port
      path                    = "/health/live"
      initial_delay           = 10
      interval_seconds        = 30
      failure_count_threshold = 3
    }
    readiness = {
      transport               = "HTTP"
      port                    = var.container_target_port
      path                    = "/health/ready"
      initial_delay           = 15
      interval_seconds        = 15
      failure_count_threshold = 5
    }
  }
}
