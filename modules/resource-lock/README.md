# Azure Resource Lock Module

Creates **Azure Management Locks** on existing scopes. Does not create Azure resources, policies, RBAC assignments, or budgets.

## Purpose

- Protect subscriptions, resource groups, and individual resources from accidental deletion or modification
- Support multiple locks via stable `for_each` keys
- Apply consistent governance across environments without hardcoded scope values
- Complement Azure Policy and RBAC with resource-level protection

This module creates **only** `azurerm_management_lock` resources.

## Architecture

```
environments/<env>/
    module "resource_group"              ──▶ scope (resource group ID)
    module "key_vault" / "storage" / ... ──▶ scope (resource IDs)
    module "resource_lock"               ──▶ azurerm_management_lock (for_each)
```

Target scopes must exist before locks are applied. Locks do not grant permissions — they restrict delete and modify operations at the Azure control plane.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Supported Lock Types

| Level | Effect |
|-------|--------|
| `CanNotDelete` | Authorized users can read and modify resources but cannot delete them |
| `ReadOnly` | Authorized users can read resources but cannot delete or modify them |

Prefer `CanNotDelete` for production workloads. Use `ReadOnly` only when changes via Terraform or the portal must be fully blocked.

## Supported Scopes

| Scope | Example |
|-------|---------|
| Subscription | `/subscriptions/00000000-0000-0000-0000-000000000000` |
| Resource group | `/subscriptions/.../resourceGroups/rg-platform-prod` |
| Individual resource | `/subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-prod` |

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `locks` | no | List of management locks to create |

### Lock object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `key` | yes | — | Stable `for_each` identifier |
| `name` | yes | — | Management lock name (unique per scope) |
| `scope` | yes | — | Subscription, resource group, or resource ID |
| `lock_level` | no | `CanNotDelete` | `CanNotDelete` or `ReadOnly` |
| `notes` | no | — | Optional lock notes (max 512 characters) |

## Outputs

| Name | Description |
|------|-------------|
| `lock_ids` | Map of keys to management lock resource IDs |
| `lock_names` | Map of keys to lock names |
| `scopes` | Map of keys to lock scopes |
| `lock_levels` | Map of keys to applied lock levels |
| `locks` | Non-sensitive metadata map including scope type |

## Examples

### Resource Group

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "platform-rg"
      name       = "platform-rg-delete-lock"
      scope      = module.resource_group.id
      lock_level = "CanNotDelete"
      notes      = "Prevent accidental deletion of the platform resource group."
    },
  ]
}
```

### Key Vault

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "key-vault"
      name       = "key-vault-delete-lock"
      scope      = module.key_vault.resource_id
      lock_level = "CanNotDelete"
      notes      = "Protect production Key Vault from deletion."
    },
  ]
}
```

### Storage Account

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "storage"
      name       = "storage-delete-lock"
      scope      = module.storage.resource_id
      lock_level = "CanNotDelete"
      notes      = "Protect platform storage account from deletion."
    },
  ]
}
```

### PostgreSQL Flexible Server

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "postgresql"
      name       = "postgresql-delete-lock"
      scope      = module.postgresql_flexible_server.resource_id
      lock_level = "CanNotDelete"
      notes      = "Protect production PostgreSQL Flexible Server from deletion."
    },
  ]
}
```

### Container Apps Environment

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "container-apps-environment"
      name       = "cae-delete-lock"
      scope      = module.container_app_environment.resource_id
      lock_level = "CanNotDelete"
      notes      = "Protect Container Apps Environment from accidental deletion."
    },
  ]
}
```

### Production Resource Group (multiple locks)

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key        = "prod-subscription"
      name       = "prod-subscription-delete-lock"
      scope      = "/subscriptions/${var.subscription_id}"
      lock_level = "CanNotDelete"
      notes      = "Subscription-level delete protection for production."
    },
    {
      key        = "prod-resource-group"
      name       = "prod-rg-delete-lock"
      scope      = module.resource_group.id
      lock_level = "CanNotDelete"
      notes      = "Resource group delete protection for production platform."
    },
    {
      key        = "prod-key-vault"
      name       = "prod-key-vault-delete-lock"
      scope      = module.key_vault.resource_id
      lock_level = "CanNotDelete"
    },
    {
      key        = "prod-postgresql"
      name       = "prod-postgresql-delete-lock"
      scope      = module.postgresql_flexible_server.resource_id
      lock_level = "CanNotDelete"
    },
  ]
}
```

### Combined platform protection

```hcl
module "resource_lock" {
  source = "../../modules/resource-lock"

  locks = [
    {
      key   = "rg-lock"
      name  = "${module.resource_group.name}-lock"
      scope = module.resource_group.id
    },
    {
      key   = "storage-lock"
      name  = "${module.storage.name}-lock"
      scope = module.storage.resource_id
    },
    {
      key   = "acr-lock"
      name  = "${module.acr.name}-lock"
      scope = module.acr.resource_id
    },
  ]
}
```

When `lock_level` is omitted, it defaults to `CanNotDelete`.

## Operational Guidance

1. **Apply locks after resources are stable** — Locks on resources still being provisioned can block required updates.
2. **Use `CanNotDelete` for Terraform-managed production** — Allows configuration changes while preventing deletion.
3. **Avoid `ReadOnly` on Terraform-managed resources** — `ReadOnly` blocks Terraform apply operations that modify locked resources.
4. **Remove locks before destructive maintenance** — Temporarily remove locks when intentional deletion or major refactoring is required.
5. **Document lock purpose in `notes`** — Helps operators understand why protection exists.
6. **Do not duplicate resource-group module locks** — The `resource-group` module has its own optional lock; use one approach consistently.

## Governance Strategy

| Layer | Tool | Purpose |
|-------|------|---------|
| Prevent non-compliant creation | Azure Policy | Enforce standards at creation |
| Restrict who can act | RBAC | Least-privilege access control |
| Prevent accidental deletion | Management Locks (this module) | Last line of defense |
| Cost control | Budgets | Spending alerts and limits |

Recommended rollout:

| Environment | Lock strategy |
|-------------|---------------|
| Development | Optional resource group lock only |
| Staging | `CanNotDelete` on resource group and data services |
| Production | `CanNotDelete` on subscription or resource group plus critical individual resources |

## Best Practices

| Practice | Rationale |
|----------|-----------|
| Default to `CanNotDelete` | Balances protection with operational flexibility |
| Lock at resource group level first | Protects all child resources with one lock |
| Add resource-level locks for critical assets | Key Vault, databases, and storage warrant extra protection |
| Use descriptive lock names | Include resource type and environment |
| Align with change management | Remove locks through approved change process only |
| Combine with Azure Policy | Policy prevents misconfiguration; locks prevent deletion |

## Lifecycle Considerations

- **Terraform destroy** — `CanNotDelete` locks block deletion of locked resources and scopes. Remove locks before destroying protected infrastructure.
- **ReadOnly locks** — Block all modifications including Terraform updates, scaling, and configuration changes.
- **Inherited effect** — Locks on a resource group apply to child resources. Avoid stacking redundant locks unless resource-level audit clarity is required.
- **Import** — Import existing locks before applying module management in brownfield environments.

```bash
terraform import 'module.resource_lock.azurerm_management_lock.this["platform-rg"]' /subscriptions/.../resourceGroups/rg-platform/providers/Microsoft.Authorization/locks/platform-rg-delete-lock
```

## Cost Considerations

Azure Management Locks are **free**. They have no direct cost impact.

## Related

- [Resource Group Module](../resource-group/README.md)
- [Policy Assignment Module](../policy-assignment/README.md)
- [Policy Exemption Module](../policy-exemption/README.md)
- [Role Assignment Module](../role-assignment/README.md)

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

No requirements.

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 5.0.1 |

## Modules

## Modules

No modules.

## Resources

## Resources

| Name | Type |
|------|------|
| [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_locks"></a> [locks](#input\_locks) | List of Azure Management Locks to apply to existing scopes. Each entry requires a stable key for for\_each identity at scale. | <pre>list(object({<br/>    key        = string<br/>    name       = string<br/>    scope      = string<br/>    lock_level = optional(string, "CanNotDelete")<br/>    notes      = optional(string)<br/>  }))</pre> | `[]` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lock_ids"></a> [lock\_ids](#output\_lock\_ids) | Map of lock keys to Azure Management Lock resource IDs. |
| <a name="output_lock_levels"></a> [lock\_levels](#output\_lock\_levels) | Map of lock keys to applied management lock levels. |
| <a name="output_lock_names"></a> [lock\_names](#output\_lock\_names) | Map of lock keys to management lock names. |
| <a name="output_locks"></a> [locks](#output\_locks) | Non-sensitive management lock metadata for downstream module composition. |
| <a name="output_scopes"></a> [scopes](#output\_scopes) | Map of lock keys to management lock scopes. |
<!-- END_TF_DOCS -->