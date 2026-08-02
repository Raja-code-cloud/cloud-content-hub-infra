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
    cae            = { resource_type = "cae" }
    api            = { resource_type = "api" }
  }

  container_image = "${module.acr.login_server}/${var.container_image_name}:${var.container_image_tag}"

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
      key                  = "workload-storage-blob-reader"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.storage.resource_id
      role_definition_name = "Storage Blob Data Reader"
      description          = "Allow workload identity to read blob data"
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
}
