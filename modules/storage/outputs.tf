# ------------------------------------------------------------------------------
# Storage Account Module — Outputs
# ------------------------------------------------------------------------------

output "id" {
  description = "The Azure Resource Manager ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "resource_id" {
  description = "The Azure Resource Manager ID of the Storage Account."
  value       = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  description = "The primary blob service endpoint URL."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_queue_endpoint" {
  description = "The primary queue service endpoint URL."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary table service endpoint URL."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file service endpoint URL."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_dfs_endpoint" {
  description = "The primary Azure Data Lake Storage Gen2 endpoint URL. Empty when hierarchical namespace is not enabled."
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "storage_account" {
  description = "Non-sensitive storage account metadata for downstream module composition."
  value = {
    id                    = azurerm_storage_account.this.id
    name                  = azurerm_storage_account.this.name
    location              = azurerm_storage_account.this.location
    primary_blob_endpoint = azurerm_storage_account.this.primary_blob_endpoint
    account_tier          = azurerm_storage_account.this.account_tier
    account_kind          = azurerm_storage_account.this.account_kind
  }
}
