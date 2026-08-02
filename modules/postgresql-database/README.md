# Azure PostgreSQL Database Module

Creates **logical databases** on an existing Azure Database for PostgreSQL Flexible Server. Does not create the server, users, firewall rules, configuration parameters, schemas, extensions, or RBAC assignments.

## Purpose

- Provision one or many application databases on an existing PostgreSQL Flexible Server
- Support environment-agnostic, reusable database composition via `for_each`
- Apply safe defaults for charset, collation, and destroy protection
- Expose database identifiers for application configuration, Key Vault secrets, and migration tooling

This module creates **only** `azurerm_postgresql_flexible_server_database` resources.

## Architecture

```
environments/<env>/
    module "common"                      ──▶ tags, names, location
    module "postgresql_flexible_server"  ──▶ existing server (server_id)
    module "postgresql_database"         ──▶ azurerm_postgresql_flexible_server_database (for_each)
            │
            ▼
    Future modules (separate implementations)
    ├── postgresql-firewall-rule      (server_id)
    ├── postgresql-configuration      (server_id)
    ├── postgresql-role / grants      (database users and permissions)
    ├── key-vault-secrets             (connection strings)
    └── diagnostic-settings           (server monitoring)
```

The PostgreSQL Flexible Server must exist before databases can be created.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `server_id` | Existing PostgreSQL Flexible Server resource ID | `string` | — | yes |
| `server_name` | Name of the existing server (cross-validated against `server_id`) | `string` | — | yes |
| `databases` | List of logical databases to create | `list(object)` | `[]` | no |
| `tags` | Composition metadata (not applied as Azure resource tags) | `map(string)` | `{}` | no |

### Database Object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `name` | yes | — | PostgreSQL database name (1–63 chars, lowercase letter start) |
| `charset` | no | `UTF8` | PostgreSQL charset (changing forces replacement) |
| `collation` | no | `en_US.utf8` | PostgreSQL collation with lowercase encoding suffix |
| `prevent_destroy` | no | `true` | When `true`, Terraform blocks destroy of the database |

### Default Rationale

| Setting | Default | Reason |
|---------|---------|--------|
| `charset` | `UTF8` | Universal Unicode support for application data |
| `collation` | `en_US.utf8` | Azure-recommended collation format; avoids uppercase `.UTF8` drift |
| `prevent_destroy` | `true` | Protects production data from accidental `terraform destroy` |

Set `prevent_destroy = false` in development environments when databases are ephemeral.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `database_ids` | no | Map of database names to ARM resource IDs |
| `database_names` | no | Map of database names to PostgreSQL database names |
| `server_name` | no | PostgreSQL Flexible Server name |
| `fully_qualified_database_identifiers` | no | Map of database names to fully qualified ARM identifiers |
| `databases` | no | Metadata map for downstream composition |

## Example Usage

### Single Application Database

```hcl
module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags

  databases = [{
    name = "cloud_content_hub"
  }]
}
```

### Multiple Databases

```hcl
module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags

  databases = [
    {
      name = "cloud_content_hub"
    },
    {
      name      = "cloud_content_hub_analytics"
      collation = "en_GB.utf8"
    },
    {
      name            = "cloud_content_hub_reporting"
      prevent_destroy = true
    },
  ]
}
```

### Development Environment

```hcl
module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags

  databases = [{
    name            = "cloud_content_hub_dev"
    prevent_destroy = false
  }]
}
```

Ephemeral dev databases can set `prevent_destroy = false` to allow teardown during environment recycling.

### Production Environment

```hcl
module "postgresql_database" {
  source = "../../modules/postgresql-database"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name
  tags        = module.common.tags

  databases = [
    {
      name            = "cloud_content_hub"
      charset         = "UTF8"
      collation       = "en_US.utf8"
      prevent_destroy = true
    },
    {
      name            = "cloud_content_hub_read_replica_app"
      prevent_destroy = true
    },
  ]
}
```

Downstream connection string example (store in Key Vault via `key-vault-secrets` module):

```hcl
# postgresql://{admin}@{fqdn}:5432/{database_name}
# database_id = module.postgresql_database.fully_qualified_database_identifiers["cloud_content_hub"]
```

## Naming Guidance

| Rule | Convention |
|------|------------|
| Database name | Lowercase letters, digits, underscores; start with a letter |
| Length | 1–63 characters |
| Reserved names | Do not use `postgres`, `template0`, `template1`, `azure_maintenance`, `azure_sys` |
| Application prefix | Use project or service prefix (e.g. `cloud_content_hub`, `cloud_content_hub_analytics`) |
| Environment suffix | Prefer environment in server name or tags — not always in database name for prod |

Database names are immutable in practice — changing `name` destroys and recreates the database.

## Operational Guidance

| Operation | Guidance |
|-----------|----------|
| Create | Databases are created on the existing server; allow up to 30 minutes per database |
| Charset / collation change | Forces database replacement — data loss unless migrated externally |
| Destroy | Blocked when `prevent_destroy = true`; set to `false` before intentional removal |
| Import | Use `terraform import` with the database ARM resource ID |
| Empty list | `databases = []` creates no resources — safe for phased rollout |

### Import Example

```shell
terraform import 'module.postgresql_database.azurerm_postgresql_flexible_server_database.this["cloud_content_hub"]' \
  "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.DBforPostgreSQL/flexibleServers/{server}/databases/cloud_content_hub"
```

### Lifecycle Implications

Each database supports `prevent_destroy` via Terraform lifecycle:

- **`prevent_destroy = true` (default):** `terraform destroy` and resource removal fail with a lifecycle error. Protects production data from accidental deletion.
- **`prevent_destroy = false`:** Database can be destroyed by Terraform. Use for dev/test only.

To destroy a protected database:

1. Set `prevent_destroy = false` in configuration
2. Add a `moved` block in the root module to avoid replacement:

```hcl
moved {
  from = module.postgresql_database.azurerm_postgresql_flexible_server_database.protected["cloud_content_hub"]
  to   = module.postgresql_database.azurerm_postgresql_flexible_server_database.unprotected["cloud_content_hub"]
}
```

3. Run `terraform apply` to reconcile state
4. Remove the database from `databases` or run `terraform destroy`

Protected and unprotected databases are managed by separate resource blocks because Terraform requires literal `prevent_destroy` lifecycle values. Toggling `prevent_destroy` without a `moved` block forces database replacement.

**Important:** Changing `charset` or `collation` always forces replacement regardless of `prevent_destroy`. Plan migrations before modifying these attributes.

## Security Considerations

This module intentionally does **not** manage:

- Database users or roles
- Permission grants (`GRANT` / `REVOKE`)
- Schemas or extensions
- Firewall rules or private endpoints
- Server configuration parameters

| Concern | Guidance |
|---------|----------|
| Credentials | Manage via separate modules; never hardcode passwords |
| Least privilege | Application users should not use the server administrator account |
| Connection strings | Store in Key Vault via `key-vault-secrets`; reference from Container Apps |
| State | Database metadata is in Terraform state; protect remote state access |
| Tags | Azure does not support tags on database resources; module `tags` are output metadata only |

## Disaster Recovery Considerations

| Scenario | Consideration |
|----------|---------------|
| Server restore | Databases are restored with the server from Azure backup; Terraform state may drift |
| Database deletion | `prevent_destroy` reduces accidental loss; rely on server PITR for recovery |
| Geo-redundant backup | Configured on the server module — not this module |
| Cross-region DR | Requires separate server and database provisioning in DR region |
| Terraform state loss | Import existing databases using ARM IDs from Azure Portal |

After server point-in-time restore, run `terraform plan` and import or reconcile any drift.

## Best Practices

- Create the server via `postgresql-flexible-server` before this module
- Pass `server_id` and `server_name` from server module outputs
- Use `UTF8` and `en_US.utf8` unless locale-specific collation is required
- Keep `prevent_destroy = true` in production
- Use unique, descriptive database names aligned with application boundaries
- Manage users, grants, and schemas in dedicated modules or migration tooling
- Store connection metadata in Key Vault — not in Terraform outputs as secrets
- Validate duplicate database names at plan time (enforced by module validation)

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/postgresql-flexible-server` | Existing server (`server_id`, `server_name`) |
| `modules/common` | Tags and naming conventions |
| Environment root providers | `azurerm` inherited from environment |

## Related

- [PostgreSQL Flexible Server Module](../postgresql-flexible-server/README.md)
- [Key Vault Secrets Module](../key-vault-secrets/README.md)
- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Terraform Standards](../../docs/terraform/standards.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
