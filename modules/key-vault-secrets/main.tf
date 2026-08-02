# ------------------------------------------------------------------------------
# Key Vault Secrets Module
#
# Manages secrets in an existing Azure Key Vault.
# Does NOT create Key Vaults, certificates, keys, RBAC, or access policies.
# See: modules/key-vault-secrets/README.md
# ------------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "this" {
  for_each = local.secrets

  name            = each.value.name
  value           = each.value.value
  key_vault_id    = var.key_vault_id
  content_type    = try(each.value.content_type, null)
  expiration_date = try(each.value.expiration_date, null)
  not_before_date = try(each.value.not_before_date, null)
  tags            = length(each.value.tags) > 0 ? each.value.tags : null
}
