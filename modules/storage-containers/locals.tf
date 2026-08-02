# ------------------------------------------------------------------------------
# Storage Containers Module — Locals
# ------------------------------------------------------------------------------

locals {
  blob_endpoint = coalesce(
    var.primary_blob_endpoint,
    "https://${var.storage_account_name}.blob.core.windows.net/"
  )

  normalized_endpoint = trimsuffix(local.blob_endpoint, "/")

  containers = {
    for container in var.containers : container.key => {
      name                  = container.name
      storage_account_id    = var.storage_account_id
      container_access_type = try(container.container_access_type, "private")
      metadata              = merge(var.tags, try(container.metadata, {}))
      immutability_policy   = try(container.immutability_policy, null)
      legal_hold            = try(container.legal_hold, null)
    }
  }

  container_urls = {
    for key, container in azurerm_storage_container.this :
    key => "${local.normalized_endpoint}/${container.name}"
  }

  # Future-ready: container immutability policies and legal holds will be applied here.
  # immutability_policies = { ... }
  # legal_holds           = { ... }
}
