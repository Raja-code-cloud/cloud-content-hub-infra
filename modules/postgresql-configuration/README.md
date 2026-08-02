# Azure PostgreSQL Configuration Module

Manages **PostgreSQL server configuration parameters** on an existing Azure Database for PostgreSQL Flexible Server. Does not create servers, databases, firewall rules, administrators, private endpoints, users, or RBAC assignments.

## Purpose

- Apply one or many PostgreSQL server parameters via reusable `for_each` composition
- Support any Azure PostgreSQL Flexible Server configuration parameter without hardcoded parameter lists
- Guard against unintended authentication and transport security changes by default
- Expose applied configuration metadata for operations, tuning, and audit

This module creates **only** `azurerm_postgresql_flexible_server_configuration` resources.

## Architecture

```
environments/<env>/
    module "common"                         ──▶ tags, names, location
    module "postgresql_flexible_server"     ──▶ existing server (server_id)
    module "postgresql_configuration"       ──▶ azurerm_postgresql_flexible_server_configuration (for_each)
            │
            ▼
    Related modules (separate implementations)
    ├── postgresql-database           (logical databases)
    ├── postgresql-firewall-rule      (network access)
    ├── diagnostic-settings           (server monitoring)
    └── key-vault-secrets             (connection metadata)
```

The PostgreSQL Flexible Server must exist before configuration parameters can be managed.

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
| `configurations` | List of server parameters to manage | `list(object)` | `[]` | no |
| `allow_restricted_configurations` | Allow authentication/transport security parameters | `bool` | `false` | no |

### Configuration Object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `name` | yes | — | PostgreSQL server parameter name (e.g. `log_connections`) |
| `value` | yes | — | Parameter value accepted by Azure PostgreSQL Flexible Server |
| `source` | no | `null` | Optional metadata describing intended parameter source |
| `enabled` | no | `true` | When `false`, parameter is excluded from Terraform management |

### Supported Parameters

This module accepts **any** valid Azure PostgreSQL Flexible Server configuration parameter name. Parameter names are not hardcoded in the module.

Common examples (documentation only):

| Parameter | Typical use |
|-----------|-------------|
| `log_min_duration_statement` | Slow query logging threshold (ms) |
| `log_connections` | Audit connection events |
| `log_disconnections` | Audit disconnection events |
| `shared_preload_libraries` | Load extensions at server start (requires restart) |
| `statement_timeout` | Abort long-running statements |
| `idle_in_transaction_session_timeout` | Terminate idle transactions |
| `work_mem` | Sort/hash memory per operation |
| `maintenance_work_mem` | Memory for maintenance operations |

Refer to [Azure PostgreSQL server parameters](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/server-parameters) for valid names and values per server version.

### Source Field

The optional `source` field is **metadata only**. The `azurerm` provider manages parameter values; Azure determines the effective source (`system-default`, `user-override`, etc.). Use `source` in configuration for documentation and downstream composition.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `configuration_ids` | no | Map of parameter names to ARM resource IDs |
| `configuration_names` | no | Map of parameter names to PostgreSQL parameter names |
| `applied_values` | no | Map of parameter names to applied values |
| `server_name` | no | PostgreSQL Flexible Server name |
| `configurations` | no | Metadata map for downstream composition |

Configuration values are operational settings, not credentials. Do not store secrets in server parameters.

## Example Usage

### Development Logging

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  configurations = [
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
  ]
}
```

### Production Logging

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  configurations = [
    {
      name   = "log_min_duration_statement"
      value  = "5000"
      source = "user-override"
    },
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
    {
      name  = "log_line_prefix"
      value = "%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h "
    },
  ]
}
```

Higher thresholds reduce log volume while retaining slow-query visibility.

### Performance Tuning

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  configurations = [
    {
      name  = "work_mem"
      value = "16384"
    },
    {
      name  = "maintenance_work_mem"
      value = "262144"
    },
    {
      name  = "random_page_cost"
      value = "1.1"
    },
  ]
}
```

Tune values based on SKU, workload, and monitoring data — do not copy defaults blindly into production.

### Statement Timeout

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  configurations = [
    {
      name  = "statement_timeout"
      value = "60000"
    },
    {
      name  = "idle_in_transaction_session_timeout"
      value = "300000"
    },
  ]
}
```

Values are in milliseconds. `60000` = 60 seconds statement timeout; `300000` = 5 minutes idle-in-transaction timeout.

### Connection Logging

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  configurations = [
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
    {
      name  = "log_hostname"
      value = "on"
    },
  ]
}
```

### Restricted Security Parameters (Explicit Opt-In)

```hcl
module "postgresql_configuration" {
  source = "../../modules/postgresql-configuration"

  server_id   = module.postgresql_flexible_server.id
  server_name = module.postgresql_flexible_server.name

  allow_restricted_configurations = true

  configurations = [
    {
      name  = "require_secure_transport"
      value = "on"
    },
  ]
}
```

Authentication and transport parameters are blocked unless `allow_restricted_configurations = true`.

## Operational Guidance

| Operation | Guidance |
|-----------|----------|
| Apply | Most parameters apply dynamically; some require server restart (see Azure docs) |
| Change value | Update `value` and run `terraform apply` — Azure applies the new setting |
| Remove parameter | Remove from `configurations` — Terraform destroys the managed override |
| Disable management | Set `enabled = false` to exclude a parameter from Terraform without changing Azure |
| Import | Import existing overrides using the configuration ARM resource ID |
| Empty list | `configurations = []` creates no resources — safe for phased rollout |

### Import Example

```shell
terraform import 'module.postgresql_configuration.azurerm_postgresql_flexible_server_configuration.this["log_connections"]' \
  "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.DBforPostgreSQL/flexibleServers/{server}/configurations/log_connections"
```

### Restart-Required Parameters

Some parameters require a server restart before taking effect, including:

- `shared_preload_libraries`
- `max_connections` (in some cases)
- `azure.extensions`

Plan maintenance windows before changing restart-required parameters in production.

## Performance Tuning Notes

| Parameter | Consideration |
|-----------|---------------|
| `work_mem` | Increase cautiously — value is per sort/hash operation per connection |
| `maintenance_work_mem` | Affects VACUUM, CREATE INDEX, ALTER TABLE performance |
| `shared_buffers` | Often Azure-managed; verify SKU limits before overriding |
| `effective_cache_size` | Query planner hint; does not allocate memory |
| `statement_timeout` | Protects against runaway queries; set per environment workload |
| `log_min_duration_statement` | Lower in dev for debugging; higher in prod to control log cost |

Always validate tuning changes with query performance metrics and connection pool behaviour.

## Security Considerations

| Concern | Guidance |
|---------|----------|
| Authentication parameters | Blocked by default; requires `allow_restricted_configurations = true` |
| Secrets | Do not store passwords or tokens in configuration values |
| Logging | Connection logging aids audit; review log retention and PII exposure |
| Transport security | Manage `require_secure_transport` only with explicit opt-in |
| Least change | Modify only parameters required for the workload — avoid broad overrides |
| State | Configuration values are stored in Terraform state; protect remote state access |

Restricted parameters (blocked unless opted in):

- `authentication`
- `password_encryption`
- `require_secure_transport`
- `ssl_min_protocol_version`
- `ssl_max_protocol_version`

## Rollback Guidance

| Scenario | Action |
|----------|--------|
| Bad parameter value | Revert `value` in Terraform and `terraform apply` |
| Emergency revert | Set parameter to previous value via Azure Portal/CLI, then reconcile Terraform |
| Remove override | Remove entry from `configurations` — Azure reverts to platform default where applicable |
| Restart-required change | Schedule maintenance; verify server health after apply |
| Terraform state drift | Run `terraform plan`; import or align configuration to Azure |

Keep previous parameter values in version control or change records to enable fast rollback.

## Best Practices

- Pass `server_id` and `server_name` from `postgresql-flexible-server` module outputs
- Use environment-specific configuration lists in `terraform.tfvars` — not hardcoded in module source
- Start with logging and timeout parameters before memory tuning
- Test restart-required parameters in non-production first
- Document rationale for each non-default parameter
- Use `enabled = false` to temporarily stop managing a parameter without deleting Azure state
- Review Azure parameter documentation for SKU and version compatibility

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/postgresql-flexible-server` | Existing server (`server_id`, `server_name`) |
| Environment root providers | `azurerm` inherited from environment |

## Related

- [PostgreSQL Flexible Server Module](../postgresql-flexible-server/README.md)
- [PostgreSQL Database Module](../postgresql-database/README.md)
- [Diagnostic Settings Module](../diagnostic-settings/README.md)
- [Terraform Standards](../../docs/terraform/standards.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
