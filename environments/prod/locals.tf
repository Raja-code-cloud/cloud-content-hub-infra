# ------------------------------------------------------------------------------
# Local Values — prod
#
# Centralizes production configuration: sizing, feature flags, governance,
# networking, monitoring, and derived module inputs. Shared logic lives in
# modules/common — this file holds prod-specific composition only.
# ------------------------------------------------------------------------------

locals {
  # --- Feature flags -----------------------------------------------------------

  networking_enabled        = var.enable_private_networking
  private_endpoints_enabled = var.enable_private_networking && var.enable_private_endpoints

  feature_flags = {
    enable_governance  = var.enable_governance
    enable_diagnostics = var.enable_diagnostics
    enable_monitoring  = var.enable_monitoring && length(var.alert_contact_emails) > 0
    enable_budget      = var.enable_governance && length(var.budget_contact_emails) > 0
  }

  # --- Naming ------------------------------------------------------------------

  standard_resource_names = {
    resource_group = { resource_type = "resource_group" }
    log_analytics  = { resource_type = "log_analytics" }
    app_insights   = { resource_type = "app_insights" }
    identity       = { resource_type = "identity" }
    acr            = { resource_type = "acr" }
    key_vault      = { resource_type = "key_vault" }
    storage        = { resource_type = "storage" }
    postgres       = { resource_type = "postgres" }
    cae            = { resource_type = "cae" }
    api            = { resource_type = "api" }
    vnet           = { resource_type = "vnet" }
    subnet_pe      = { resource_type = "subnet", instance = "pe" }
    subnet_pg      = { resource_type = "subnet", instance = "pg" }
    subnet_cae     = { resource_type = "subnet", instance = "cae" }
    action_group   = { resource_type = "monitor", instance = "ag" }
    pe_kv          = { resource_type = "api", instance = "pe-kv" }
    pe_storage     = { resource_type = "api", instance = "pe-st" }
    pe_acr         = { resource_type = "api", instance = "pe-acr" }
    pe_postgres    = { resource_type = "api", instance = "pe-pg" }
  }

  prod_additional_tags = merge(var.additional_tags, {
    promotion_tier = "production"
    criticality    = "high"
    data_class     = "confidential"
  })

  # --- Sizing (production defaults) ----------------------------------------------

  sizing = {
    log_analytics_daily_quota_gb    = 10
    log_analytics_retention_days    = 90
    app_insights_sampling           = 100
    acr_sku                         = "Premium"
    acr_zone_redundancy             = true
    key_vault_purge_protection      = true
    storage_replication_type        = "GRS"
    storage_min_tls_version         = "TLS1_2"
    postgres_sku                    = "GP_Standard_D2s"
    postgres_storage_mb             = 131072
    postgres_backup_retention_days  = 35
    postgres_geo_redundant_backup   = true
    postgres_high_availability_mode = "SameZone"
    container_cpu                   = 2.0
    container_memory                = "4.0Gi"
    container_min_replicas          = 2
    container_max_replicas          = 10
    container_scale_concurrency     = 100
  }

  # --- Networking --------------------------------------------------------------

  network_address_space = ["10.30.0.0/16"]

  networking_subnet_definitions = local.networking_enabled ? [
    {
      key                               = "private-endpoints"
      name                              = module.common.resource_names["subnet_pe"]
      address_prefixes                  = ["10.30.1.0/24"]
      private_endpoint_network_policies = "Disabled"
      delegations                       = []
    },
    {
      key                               = "postgres"
      name                              = module.common.resource_names["subnet_pg"]
      address_prefixes                  = ["10.30.2.0/24"]
      private_endpoint_network_policies = "Disabled"
      delegations = [{
        name = "postgres-delegation"
        service_delegation = {
          name    = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    },
    {
      key                               = "container-apps"
      name                              = module.common.resource_names["subnet_cae"]
      address_prefixes                  = ["10.30.3.0/24"]
      private_endpoint_network_policies = "Disabled"
      delegations = [{
        name = "container-apps-delegation"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    },
  ] : []

  private_dns_zone_names = [
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.postgres.database.azure.com",
    "privatelink.azurecr.io",
  ]

  acr_public_access_enabled      = local.networking_enabled ? false : var.public_network_access_enabled
  postgres_public_access_enabled = local.networking_enabled ? false : var.public_network_access_enabled

  # --- PostgreSQL --------------------------------------------------------------

  postgresql_configurations = [
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "statement_timeout"
      value = "30000"
    },
    {
      name  = "idle_in_transaction_session_timeout"
      value = "60000"
    },
  ]

  postgresql_databases = [
    {
      name            = "cloud_content_hub"
      prevent_destroy = true
    },
  ]

  # --- Storage -----------------------------------------------------------------

  storage_containers = [
    {
      key  = "assets"
      name = "assets"
    },
    {
      key  = "uploads"
      name = "uploads"
    },
  ]

  # --- Governance --------------------------------------------------------------

  azure_policy_definition_ids = {
    storage_secure_transfer  = "/providers/Microsoft.Authorization/policyDefinitions/404c6381-a8db-451f-a93c-aebf87858e6d"
    key_vault_soft_delete    = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a669-4fb1-9b89-664a10d5541c"
    storage_network_restrict = "/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507f-4c7b-8e9a-8c9760ad1859"
  }

  policy_initiatives = [
    {
      key          = "platform-baseline"
      name         = "${replace(module.common.resource_prefix, "-", "")}-baseline"
      display_name = "Cloud Content Hub Production Platform Baseline"
      description  = "Production baseline policies for secure transfer, Key Vault soft delete, and storage network restrictions."
      policy_type  = "Custom"
      policy_definitions = [
        {
          policy_definition_id = local.azure_policy_definition_ids.storage_secure_transfer
          reference_id         = "storage-secure-transfer"
        },
        {
          policy_definition_id = local.azure_policy_definition_ids.key_vault_soft_delete
          reference_id         = "key-vault-soft-delete"
        },
        {
          policy_definition_id = local.azure_policy_definition_ids.storage_network_restrict
          reference_id         = "storage-network-restrict"
        },
      ]
    },
  ]

  policy_assignments = [
    {
      key                  = "platform-baseline"
      name                 = "platform-baseline"
      display_name         = "Production - Platform baseline initiative"
      scope                = module.resource_group.id
      policy_definition_id = module.policy_initiative.initiative_ids["platform-baseline"]
    },
  ]

  budget_start_date = coalesce(var.budget_start_date, "${formatdate("YYYY-MM", plantimestamp())}-01T00:00:00Z")

  budgets = [
    {
      key        = "platform-monthly"
      name       = "platform-monthly-budget"
      scope      = module.resource_group.id
      amount     = var.budget_amount
      time_grain = "Monthly"
      start_date = local.budget_start_date
      notifications = [
        {
          threshold      = 70
          operator       = "GreaterThan"
          threshold_type = "Actual"
          contact_emails = var.budget_contact_emails
        },
        {
          threshold      = 85
          operator       = "GreaterThan"
          threshold_type = "Actual"
          contact_emails = var.budget_contact_emails
        },
        {
          threshold      = 100
          operator       = "GreaterThan"
          threshold_type = "Forecasted"
          contact_emails = var.budget_contact_emails
        },
      ]
    },
  ]

  # --- Monitoring --------------------------------------------------------------

  action_groups = [
    {
      key                 = "platform"
      action_group_name   = module.common.resource_names["action_group"]
      resource_group_name = module.resource_group.name
      short_name          = substr(replace(module.common.resource_prefix, "-", ""), 0, 12)
      email_receivers = [
        for email in var.alert_contact_emails : {
          name          = replace(email, "@", "-at-")
          email_address = email
        }
      ]
    },
  ]

  metric_alerts = [
    {
      key                  = "postgres-cpu"
      name                 = "${module.common.resource_prefix}-postgres-cpu"
      description          = "PostgreSQL Flexible Server CPU utilization is elevated."
      target_resource_id   = module.postgresql_flexible_server.id
      metric_namespace     = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric_name          = "cpu_percent"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 70
      severity             = 1
      window_size          = "PT15M"
      evaluation_frequency = "PT5M"
    },
    {
      key                  = "postgres-storage"
      name                 = "${module.common.resource_prefix}-postgres-storage"
      description          = "PostgreSQL Flexible Server storage utilization is elevated."
      target_resource_id   = module.postgresql_flexible_server.id
      metric_namespace     = "Microsoft.DBforPostgreSQL/flexibleServers"
      metric_name          = "storage_percent"
      aggregation          = "Average"
      operator             = "GreaterThan"
      threshold            = 80
      severity             = 2
      window_size          = "PT15M"
      evaluation_frequency = "PT5M"
    },
  ]

  diagnostic_settings = [
    {
      key                        = "key-vault"
      diagnostic_name            = "${module.common.resource_prefix}-kv-diag"
      target_resource_id         = module.key_vault.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      logs                       = [{ category_group = "allLogs", enabled = true }]
      metrics                    = [{ category = "AllMetrics", enabled = true }]
    },
    {
      key                        = "storage"
      diagnostic_name            = "${module.common.resource_prefix}-st-diag"
      target_resource_id         = module.storage.resource_id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      logs                       = [{ category_group = "allLogs", enabled = true }]
      metrics                    = [{ category = "AllMetrics", enabled = true }]
    },
    {
      key                        = "postgres"
      diagnostic_name            = "${module.common.resource_prefix}-pg-diag"
      target_resource_id         = module.postgresql_flexible_server.id
      log_analytics_workspace_id = module.log_analytics.workspace_resource_id
      logs                       = [{ category_group = "allLogs", enabled = true }]
      metrics                    = [{ category = "AllMetrics", enabled = true }]
    },
  ]

  # --- RBAC --------------------------------------------------------------------

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

  deployer_role_assignments = [
    {
      key                  = "deployer-kv-secrets-officer"
      principal_id         = var.deployment_principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.key_vault.resource_id
      role_definition_name = "Key Vault Secrets Officer"
      description          = "Allow Terraform deployment identity to manage Key Vault secrets"
    },
  ]

  role_assignments = concat(local.workload_role_assignments, local.deployer_role_assignments)

  # --- Container App -----------------------------------------------------------

  container_image = "${module.acr.login_server}/${var.container_image_name}:${var.container_image_tag}"

  container_app_environment = {
    aspnetcore_environment = "Production"
  }

  app_insights_secret_name = "appinsights-connection-string"

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
      key          = "appinsights-connection-string"
      name         = local.app_insights_secret_name
      value        = module.application_insights.connection_string
      content_type = "connection-string"
      tags = {
        purpose = "observability"
      }
    },
  ]

  container_app_key_vault_secret_refs = [
    {
      name                = local.app_insights_secret_name
      key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids[local.app_insights_secret_name]
      identity            = module.managed_identity.resource_id
    },
  ]

  # --- Private endpoints -------------------------------------------------------

  private_endpoint_definitions = local.private_endpoints_enabled ? [
    {
      key                   = "key-vault"
      private_endpoint_name = module.common.resource_names["pe_kv"]
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking[0].subnet_ids["private-endpoints"]
      target_resource_id    = module.key_vault.resource_id
      subresource_names     = ["vault"]
      private_dns_zone_group = {
        name = "kv-dns"
        private_dns_zone_ids = [
          module.private_dns[0].zone_ids["privatelink.vaultcore.azure.net"],
        ]
      }
    },
    {
      key                   = "storage-blob"
      private_endpoint_name = module.common.resource_names["pe_storage"]
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking[0].subnet_ids["private-endpoints"]
      target_resource_id    = module.storage.resource_id
      subresource_names     = ["blob"]
      private_dns_zone_group = {
        name = "storage-blob-dns"
        private_dns_zone_ids = [
          module.private_dns[0].zone_ids["privatelink.blob.core.windows.net"],
        ]
      }
    },
    {
      key                   = "acr"
      private_endpoint_name = module.common.resource_names["pe_acr"]
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking[0].subnet_ids["private-endpoints"]
      target_resource_id    = module.acr.resource_id
      subresource_names     = ["registry"]
      private_dns_zone_group = {
        name = "acr-dns"
        private_dns_zone_ids = [
          module.private_dns[0].zone_ids["privatelink.azurecr.io"],
        ]
      }
    },
    {
      key                   = "postgresql"
      private_endpoint_name = module.common.resource_names["pe_postgres"]
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking[0].subnet_ids["private-endpoints"]
      target_resource_id    = module.postgresql_flexible_server.id
      subresource_names     = ["postgresqlServer"]
      private_dns_zone_group = {
        name = "postgres-dns"
        private_dns_zone_ids = [
          module.private_dns[0].zone_ids["privatelink.postgres.database.azure.com"],
        ]
      }
    },
  ] : []
}
