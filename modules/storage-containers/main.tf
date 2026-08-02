# ------------------------------------------------------------------------------
# Storage Containers Module
#
# Creates blob containers in an existing Azure Storage Account.
# Does NOT create storage accounts, lifecycle policies, or network rules.
# See: modules/storage-containers/README.md
# ------------------------------------------------------------------------------

resource "azurerm_storage_container" "this" {
  #checkov:skip=CKV_AZURE_34:Default access type is private via locals; public access requires explicit caller configuration.
  #checkov:skip=CKV2_AZURE_8:Module creates application blob containers, not activity log archive containers.
  #checkov:skip=CKV2_AZURE_21:Blob service logging is configured on the storage account, not per container.
  for_each = local.containers

  name                  = each.value.name
  storage_account_id    = each.value.storage_account_id
  container_access_type = each.value.container_access_type
  metadata              = length(each.value.metadata) > 0 ? each.value.metadata : null
}

# Future-ready: Blob container immutability policies
# resource "azurerm_storage_container_immutability_policy" "this" {
#   for_each = {
#     for key, container in local.containers :
#     key => container if try(container.immutability_policy, null) != null
#   }
#   ...
# }

# Future-ready: Blob container legal holds
# resource "azurerm_storage_container_legal_hold" "this" {
#   for_each = {
#     for key, container in local.containers :
#     key => container if try(container.legal_hold, null) == true
#   }
#   ...
# }
