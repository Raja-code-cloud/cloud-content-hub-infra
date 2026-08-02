# Azure Key Vault Secrets Module

Manages **secrets in an existing Azure Key Vault**. Does not create Key Vaults, certificates, keys, RBAC assignments, access policies, or identities.

## Purpose

- Store and manage application secrets centrally in Azure Key Vault
- Support hundreds of secrets via stable `for_each` keys
- Accept secret values from Terraform variables, CI/CD secrets, or other module outputs
- Expose only non-sensitive metadata (IDs, URIs, names) — never secret values

This module creates **only** `azurerm_key_vault_secret` resources.

## Architecture

```
environments/<env>/
    module "key_vault"         ──▶ existing vault (key_vault_id)
    module "postgresql_..."    ──▶ generates password (output)
    module "key_vault_secrets" ──▶ azurerm_key_vault_secret (for_each)
            │
            ▼
    module "container_app"     ──▶ key_vault_secret_id references
    module "role_assignment"   ──▶ Key Vault Secrets User (separate module)
```

The Key Vault and RBAC must exist before secrets can be created. Assign `Key Vault Secrets User` to deploying identities via the `role-assignment` module.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `key_vault_id` | Existing Key Vault resource ID | `string` | — | yes |
| `secrets` | List of secrets to manage (sensitive) | `list(object)` | `[]` | no |

### Secret Object

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable Terraform identifier (2–64 chars, lowercase alphanumeric/hyphen) |
| `name` | yes | Key Vault secret name (1–127 alphanumeric/hyphen) |
| `value` | yes | Secret value (sensitive) |
| `content_type` | no | Content type metadata (e.g. `password`, `application/json`) |
| `expiration_date` | no | RFC3339 UTC expiry (e.g. `2026-12-31T23:59:59Z`) |
| `not_before_date` | no | RFC3339 UTC activation date |
| `tags` | no | Optional tags on the secret |
| `enabled` | no | When `false`, secret is excluded from management (default `true`) |

The `secrets` variable is marked **sensitive**. Internally, `nonsensitive()` is applied only for `for_each` iteration keys — values are never exposed in outputs.

### Secret Value Sources

| Source | Pattern |
|--------|---------|
| Terraform variables | `value = var.database_password` in each secret object |
| GitHub Actions | Pass via `TF_VAR_*` into Terraform variables referenced in `value` |
| Module outputs | `value = module.postgresql_flexible_server.admin_password` |
| Generated passwords | `value = random_password.db.result` (future-compatible) |

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `secret_ids` | no | Versioned secret resource IDs |
| `secret_uris` | no | Versioned secret URIs |
| `secret_names` | no | Secret names in Key Vault |
| `secret_versionless_ids` | no | Versionless IDs for Container App / App Service references |
| `secret_versions` | no | Current version identifiers |
| `secrets` | no | Metadata map (no values) |

**Secret values are never exposed in outputs.**

## Example Usage

### Database Password

```hcl
module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id

  secrets = [{
    key          = "postgres-admin-password"
    name         = "postgres-admin-password"
    value        = var.postgresql_admin_password
    content_type = "password"
    tags = {
      purpose = "database"
      engine  = "postgresql"
    }
  }]
}
```

Supply `postgresql_admin_password` via gitignored `terraform.tfvars` or `TF_VAR_postgresql_admin_password` in GitHub Actions.

### API Key

```hcl
module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id

  secrets = [{
    key          = "external-api-key"
    name         = "external-api-key"
    value        = var.external_api_key
    content_type = "api-key"
  }]
}
```

### JWT Signing Secret

```hcl
module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id

  secrets = [{
    key             = "jwt-signing-secret"
    name            = "jwt-signing-secret"
    value           = var.jwt_signing_secret
    content_type    = "text/plain"
    expiration_date = var.jwt_secret_expiration_date
  }]
}
```

### Storage Connection String

```hcl
module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id

  secrets = [{
    key          = "storage-connection-string"
    name         = "storage-connection-string"
    value        = var.storage_connection_string
    content_type = "connection-string"
  }]
}
```

### Third-Party API Token

```hcl
module "key_vault_secrets" {
  source = "../../modules/key-vault-secrets"

  key_vault_id = module.key_vault.resource_id

  secrets = [
    {
      key          = "stripe-api-token"
      name         = "stripe-api-token"
      value        = var.stripe_api_token
      content_type = "api-token"
    },
    {
      key          = "sendgrid-api-key"
      name         = "sendgrid-api-key"
      value        = var.sendgrid_api_key
      content_type = "api-key"
    },
  ]
}
```

### Downstream Container App Reference

```hcl
# Container App module (separate) references versionless ID:
# key_vault_secret_id = module.key_vault_secrets.secret_versionless_ids["postgres-admin-password"]
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/key-vault` | Existing vault (`key_vault_id`) |
| `modules/role-assignment` | Deployer needs `Key Vault Secrets Officer` or equivalent |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **State storage** — Secret values are stored in Terraform state. Use remote state with encryption (Azure Storage SSE, RBAC), strict access controls, and state locking.
- **Sensitive input** — The `secrets` variable is marked `sensitive` to suppress CLI output. Values are still stored in encrypted remote state.
- **No value outputs** — This module never outputs secret values.
- **Least privilege** — Assign `Key Vault Secrets Officer` only to deployment pipelines; workloads receive `Key Vault Secrets User` via separate RBAC module.
- **No logging** — Do not echo secret values in CI logs; use `TF_VAR_*` from encrypted secrets stores.
- **Soft delete** — Key Vault soft-delete retains deleted secrets; coordinate with vault retention policies.

## Secret Rotation Guidance

| Strategy | Approach |
|----------|----------|
| Terraform-managed | Update secret `value` and apply — creates new secret version |
| Pipeline-managed | Rotate in Azure Portal/CLI; add `lifecycle { ignore_changes = [value] }` if adopting external rotation |
| Expiration-driven | Set `expiration_date` and monitor via Azure Monitor alerts |
| Dual-write | Create new secret name/version, update app reference, retire old version |

For production rotation without Terraform value drift, prefer Azure Key Vault rotation policies or pipeline-driven updates with explicit version pinning in consuming applications.

## Operational Notes

- Secret names are immutable — changing a name destroys and recreates the secret.
- Setting `enabled = false` removes the secret from Terraform management (destroy on next apply).
- `not_before_date` must precede `expiration_date` when both are set.
- Versionless IDs (`secret_versionless_ids`) are preferred for Container Apps Key Vault references.
- Import existing secrets using `terraform import` with the versioned secret ID.

### Import Example

```shell
terraform import 'module.key_vault_secrets.azurerm_key_vault_secret.this["postgres-admin-password"]' \
  "https://{vault-name}.vault.azure.net/secrets/postgres-admin-password/{version}"
```

## Best Practices

- Use descriptive `key` values for Terraform and concise `name` values for Key Vault
- Set `content_type` for operational clarity (`password`, `connection-string`, `api-key`)
- Apply `expiration_date` on credentials with known rotation schedules
- Tag secrets with ownership and purpose metadata
- Never commit secret values to source control
- Wire RBAC before first `terraform apply`
- Reference secrets in applications via versionless IDs or managed identity — not hardcoded values

## Related

- [Key Vault Module](../key-vault/README.md)
- [Role Assignment Module](../role-assignment/README.md)
- [Container App Module](../container-app/README.md)
- [Shared Foundation](../../docs/terraform/shared-foundation.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
