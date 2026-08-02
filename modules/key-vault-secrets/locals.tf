# ------------------------------------------------------------------------------
# Key Vault Secrets Module - Locals
# ------------------------------------------------------------------------------

locals {
  # nonsensitive() is required because Terraform prohibits sensitive values in for_each
  # keys. Only non-sensitive metadata is used for iteration; values remain sensitive.
  secrets = {
    for secret in nonsensitive(var.secrets) : secret.key => secret if try(secret.enabled, true)
  }
}
