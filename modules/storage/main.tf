# ------------------------------------------------------------------------------
# Storage Account Module
#
# Creates exactly one Azure Storage Account.
# Does NOT create containers, shares, queues, tables, lifecycle policies, or network rules.
# See: modules/storage/README.md
# ------------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                              = var.storage_account_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = var.account_tier
  account_replication_type          = var.account_replication_type
  account_kind                      = var.account_kind
  access_tier                       = local.supports_access_tier ? var.access_tier : null
  min_tls_version                   = var.min_tls_version
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  allow_nested_items_to_be_public   = var.allow_blob_public_access
  shared_access_key_enabled         = var.shared_access_key_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  tags                              = var.tags

  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }
}

check "file_storage_requires_premium" {
  assert {
    condition     = var.account_kind != "FileStorage" || var.account_tier == "Premium"
    error_message = "FileStorage account_kind requires account_tier Premium."
  }
}

check "block_blob_storage_requires_premium" {
  assert {
    condition     = var.account_kind != "BlockBlobStorage" || var.account_tier == "Premium"
    error_message = "BlockBlobStorage account_kind requires account_tier Premium."
  }
}

check "premium_replication_types" {
  assert {
    condition = var.account_tier != "Premium" || contains([
      "LRS", "ZRS",
    ], var.account_replication_type)
    error_message = "Premium account_tier supports LRS or ZRS replication only."
  }
}
