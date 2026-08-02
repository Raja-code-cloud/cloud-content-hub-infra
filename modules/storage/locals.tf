# ------------------------------------------------------------------------------
# Storage Account Module — Locals
# ------------------------------------------------------------------------------

locals {
  supports_access_tier = contains(["StorageV2", "BlobStorage"], var.account_kind)
}
