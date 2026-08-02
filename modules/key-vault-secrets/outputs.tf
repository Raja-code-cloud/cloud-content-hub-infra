# ------------------------------------------------------------------------------
# Key Vault Secrets Module — Outputs
# ------------------------------------------------------------------------------

output "secret_ids" {
  description = "Map of secret keys to versioned Key Vault secret ARM resource IDs."
  value       = { for key, secret in azurerm_key_vault_secret.this : key => secret.resource_id }
}

output "secret_uris" {
  description = "Map of secret keys to versioned Key Vault secret URIs (https://{vault}.vault.azure.net/secrets/{name}/{version})."
  value       = { for key, secret in azurerm_key_vault_secret.this : key => secret.id }
}

output "secret_names" {
  description = "Map of secret keys to Key Vault secret names."
  value       = { for key, secret in azurerm_key_vault_secret.this : key => secret.name }
}

output "secret_versionless_ids" {
  description = "Map of secret keys to versionless secret IDs for Key Vault reference integrations."
  value       = { for key, secret in azurerm_key_vault_secret.this : key => secret.versionless_id }
}

output "secret_versions" {
  description = "Map of secret keys to current secret version identifiers."
  value       = { for key, secret in azurerm_key_vault_secret.this : key => secret.version }
}

output "secrets" {
  description = "Non-sensitive secret metadata for downstream module composition. Never includes secret values."
  value = {
    for key, secret in azurerm_key_vault_secret.this :
    key => {
      id              = secret.id
      name            = secret.name
      version         = secret.version
      versionless_id  = secret.versionless_id
      resource_id     = secret.resource_id
      content_type    = secret.content_type
      expiration_date = secret.expiration_date
      not_before_date = secret.not_before_date
    }
  }
}
