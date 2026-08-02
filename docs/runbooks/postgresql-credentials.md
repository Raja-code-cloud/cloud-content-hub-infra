# PostgreSQL Credential Management

## Current State

PostgreSQL administrator passwords are supplied via `TF_VAR_postgresql_admin_password` and stored in Terraform state when using `postgresql-flexible-server` and `key-vault-secrets` modules.

## Recommended Production Pattern

1. Generate password outside Terraform (Azure Key Vault, password manager, or `openssl rand -base64 32`).
2. Store in Key Vault manually or via a one-time bootstrap pipeline.
3. Import existing secret into Terraform state **or** use `lifecycle { ignore_changes = [administrator_password] }` after initial apply.
4. Rotate via Azure Portal / CLI and update Key Vault; avoid re-applying password through Terraform.

## Key Vault Integration

The platform stores `postgres-admin-password` in Key Vault via `key-vault-secrets`. Application workloads should read from Key Vault at runtime — not from Terraform outputs.

## CI/CD

Supply passwords via GitHub Actions encrypted secrets:

```
TF_VAR_postgresql_admin_password
```

Never commit passwords to `terraform.tfvars`.

## Future Enhancement (v1.1)

Evaluate `random_password` with `azurerm_key_vault_secret` import pattern to remove plaintext from tfvars while accepting state retention of the secret resource.
