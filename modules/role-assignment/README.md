# Azure Role Assignment Module

Creates **Azure RBAC role assignments** at any supported scope. Does not create role definitions, identities, groups, users, or policies.

## Purpose

- Centralize RBAC assignment management for platform and application resources
- Support hundreds of assignments via stable `for_each` keys
- Assign roles by built-in **role name** or explicit **role definition ID**
- Enable least-privilege access for managed identities, service principals, users, and groups

This module creates **only** `azurerm_role_assignment` resources.

## Architecture

```
environments/<env>/
    module "managed_identity"   ──▶ principal_id (existing)
    module "acr"                  ──▶ scope (resource_id)
    module "storage"              ──▶ scope (resource_id)
    module "key_vault"            ──▶ scope (resource_id)
    module "resource_group"       ──▶ scope (resource_id)
    module "role_assignment"      ──▶ azurerm_role_assignment (for_each)
            │
            ▼
    Downstream modules consume assignment IDs for dependency ordering
```

Principals and scopes must already exist. This module never creates them.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

### `assignments`

List of role assignment objects. Each entry requires a unique `key` for stable Terraform state at scale.

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable identifier for `for_each` (2–64 chars, lowercase alphanumeric/hyphen) |
| `principal_id` | yes | Azure AD object ID (UUID) of the assignee |
| `scope` | yes | Management group, subscription, resource group, or resource scope |
| `role_definition_name` | conditional | Built-in or custom role name (e.g. `Reader`, `AcrPull`) |
| `role_definition_id` | conditional | Full role definition resource ID |
| `principal_type` | no | `User`, `Group`, `ServicePrincipal`, `ForeignGroup` |
| `description` | no | Assignment description |
| `condition` | no | ABAC condition expression |
| `condition_version` | no | Required when `condition` is set (`1.0` or `2.0`) |
| `skip_service_principal_aad_check` | no | Skip AAD propagation check (default `false`) |

Exactly **one** of `role_definition_name` or `role_definition_id` must be specified per assignment.

### Principal Types

| Type | Typical Use |
|------|-------------|
| `ServicePrincipal` | Managed identities, app registrations, workload identities |
| `User` | Individual user accounts |
| `Group` | Azure AD security groups |
| `ForeignGroup` | External directory groups |

Managed identities and workload identities use `ServicePrincipal` as `principal_type`.

### Supported Scopes

| Scope | Format |
|-------|--------|
| Management group | `/providers/Microsoft.Management/managementGroups/{id}` |
| Subscription | `/subscriptions/{subscription-id}` |
| Resource group | `/subscriptions/{subscription-id}/resourceGroups/{name}` |
| Resource | `/subscriptions/{subscription-id}/resourceGroups/{name}/providers/{provider}/{type}/{name}` |

## Outputs

| Name | Description |
|------|-------------|
| `assignment_ids` | Map of keys to role assignment resource IDs |
| `principal_ids` | Map of keys to principal object IDs |
| `scopes` | Map of keys to scopes |
| `role_names` | Map of keys to resolved role definition names |
| `role_definition_ids` | Map of keys to resolved role definition IDs |
| `assignments` | Metadata object map for downstream composition |

## Examples

### Managed Identity → ACR AcrPull

```hcl
module "role_assignment_acr_pull" {
  source = "../../modules/role-assignment"

  assignments = [{
    key              = "identity-acr-acrpull"
    principal_id     = module.managed_identity.principal_id
    principal_type   = "ServicePrincipal"
    scope            = module.acr.resource_id
    role_definition_name = "AcrPull"
    description      = "Allow container app identity to pull images from ACR"
  }]
}
```

### Managed Identity → Storage Blob Data Contributor

```hcl
module "role_assignment_storage" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                  = "identity-storage-blob-contributor"
    principal_id         = module.managed_identity.principal_id
    principal_type       = "ServicePrincipal"
    scope                = module.storage.resource_id
    role_definition_name = "Storage Blob Data Contributor"
    description          = "Allow application identity to read and write blob data"
  }]
}
```

### Managed Identity → Key Vault Secrets User

```hcl
module "role_assignment_key_vault" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                  = "identity-kv-secrets-user"
    principal_id         = module.managed_identity.principal_id
    principal_type       = "ServicePrincipal"
    scope                = module.key_vault.resource_id
    role_definition_name = "Key Vault Secrets User"
    description          = "Allow container app identity to read Key Vault secrets"
  }]
}
```

### Managed Identity → PostgreSQL (Future Integration)

PostgreSQL Flexible Server data-plane RBAC is not yet available via standard built-in roles at the server scope. Use this placeholder pattern until a dedicated integration module is implemented:

```hcl
module "role_assignment_postgres_future" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                  = "identity-postgres-reader-placeholder"
    principal_id         = module.managed_identity.principal_id
    principal_type       = "ServicePrincipal"
    scope                = module.resource_group.resource_id
    role_definition_name = "Reader"
    description          = "Placeholder: replace with PostgreSQL-specific RBAC when integration module is available"
  }]
}
```

### Reader on Resource Group

```hcl
module "role_assignment_rg_reader" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                  = "group-rg-reader"
    principal_id         = var.operations_group_object_id
    principal_type       = "Group"
    scope                = module.resource_group.resource_id
    role_definition_name = "Reader"
    description          = "Allow operations team read access to the environment resource group"
  }]
}
```

### Multiple Assignments (One Principal, Multiple Resources)

```hcl
module "role_assignment_platform" {
  source = "../../modules/role-assignment"

  assignments = [
    {
      key                  = "identity-acr-acrpull"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.acr.resource_id
      role_definition_name = "AcrPull"
    },
    {
      key                  = "identity-kv-secrets-user"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.key_vault.resource_id
      role_definition_name = "Key Vault Secrets User"
    },
    {
      key                  = "identity-log-analytics-reader"
      principal_id         = module.managed_identity.principal_id
      principal_type       = "ServicePrincipal"
      scope                = module.log_analytics.workspace_resource_id
      role_definition_name = "Log Analytics Reader"
    },
  ]
}
```

### Role Definition ID (Custom Role)

```hcl
module "role_assignment_custom" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                = "sp-custom-role"
    principal_id       = var.service_principal_object_id
    principal_type     = "ServicePrincipal"
    scope              = module.resource_group.resource_id
    role_definition_id = var.custom_role_definition_id
    description        = "Assign custom role by definition ID"
  }]
}
```

### ABAC Condition (Optional)

```hcl
module "role_assignment_conditional" {
  source = "../../modules/role-assignment"

  assignments = [{
    key                  = "identity-storage-conditional"
    principal_id         = module.managed_identity.principal_id
    principal_type       = "ServicePrincipal"
    scope                = module.storage.resource_id
    role_definition_name = "Storage Blob Data Reader"
    condition            = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEqualsIgnoreCase 'logs'"
    condition_version    = "2.0"
    description          = "Read-only access to logs container"
  }]
}
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| Principal resources | Managed identity, user, group, or service principal must exist |
| Scope resources | Target management group, subscription, RG, or resource must exist |
| Environment root providers | `azurerm` inherited from environment |
| `modules/role-assignment` | Creates assignments only — no upstream module is required |

Wire assignments **before** dependent workloads (e.g. assign `AcrPull` before deploying Container Apps that pull from ACR).

## Best Practices

- Use **stable keys** derived from purpose (`identity-acr-acrpull`), not from indices
- Prefer **data-plane roles** (`AcrPull`, `Key Vault Secrets User`) over broad control-plane roles
- Assign at the **narrowest scope** (resource > resource group > subscription)
- Set `principal_type = "ServicePrincipal"` for managed identities and workload identities
- Group related assignments in a single module call for atomic RBAC plans
- Use `description` on every assignment for audit traceability

## Least Privilege Guidance

| Need | Prefer | Avoid |
|------|--------|-------|
| Read resource metadata | `Reader` | `Contributor`, `Owner` |
| Pull container images | `AcrPull` | `AcrPush`, `Contributor` |
| Read secrets | `Key Vault Secrets User` | `Key Vault Administrator` |
| Read blob data | `Storage Blob Data Reader` | `Storage Account Contributor` |
| Write blob data | `Storage Blob Data Contributor` | `Storage Account Key Operator` |
| Query logs | `Log Analytics Reader` | `Log Analytics Contributor` |

Grant only the permissions required for the workload. Review assignments regularly and remove unused access.

## Common Built-in Roles

| Role | Scope | Use Case |
|------|-------|----------|
| `Reader` | Any | Read-only visibility |
| `AcrPull` | ACR | Pull container images |
| `Key Vault Secrets User` | Key Vault | Read secret values |
| `Storage Blob Data Reader` | Storage account | Read blob data |
| `Storage Blob Data Contributor` | Storage account | Read/write blob data |
| `Log Analytics Reader` | Log Analytics workspace | Query workspace data |
| `Monitoring Reader` | Any | Read monitoring data |

## Troubleshooting

| Issue | Cause | Resolution |
|-------|-------|------------|
| `AuthorizationFailed` | Insufficient caller permissions | Ensure deploying identity has `User Access Administrator` or `Owner` at scope |
| `PrincipalNotFound` | Principal does not exist or wrong ID | Verify `principal_id` UUID; for managed identity use `principal_id` not `client_id` |
| `RoleAssignmentExists` | Duplicate assignment | Import existing assignment or remove duplicate from `assignments` |
| AAD propagation delay | New service principal not yet replicated | Set `skip_service_principal_aad_check = true` only when necessary |
| `scope` validation error | Invalid scope format | Use full ARM resource ID including `/subscriptions/...` prefix |
| Custom role not found | Wrong role definition ID | Verify subscription-level custom role ID format |

### Import Existing Assignment

```shell
terraform import 'module.role_assignment.azurerm_role_assignment.this["identity-acr-acrpull"]' \
  "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.ContainerRegistry/registries/{acr}/providers/Microsoft.Authorization/roleAssignments/{assignment-id}"
```

## Related

- [Managed Identity Module](../managed-identity/README.md)
- [Container App Module](../container-app/README.md)
- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)

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
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assignments"></a> [assignments](#input\_assignments) | List of Azure RBAC role assignments. Each entry must include a stable key for for\_each identity at scale. | <pre>list(object({<br/>    key                              = string<br/>    principal_id                     = string<br/>    principal_type                   = optional(string)<br/>    scope                            = string<br/>    role_definition_name             = optional(string)<br/>    role_definition_id               = optional(string)<br/>    condition                        = optional(string)<br/>    condition_version                = optional(string)<br/>    skip_service_principal_aad_check = optional(bool, false)<br/>    description                      = optional(string)<br/>  }))</pre> | `[]` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_assignment_ids"></a> [assignment\_ids](#output\_assignment\_ids) | Map of assignment keys to Azure role assignment resource IDs. |
| <a name="output_assignments"></a> [assignments](#output\_assignments) | Non-sensitive role assignment metadata for downstream module composition. |
| <a name="output_principal_ids"></a> [principal\_ids](#output\_principal\_ids) | Map of assignment keys to principal object IDs. |
| <a name="output_role_definition_ids"></a> [role\_definition\_ids](#output\_role\_definition\_ids) | Map of assignment keys to resolved role definition IDs. |
| <a name="output_role_names"></a> [role\_names](#output\_role\_names) | Map of assignment keys to resolved role definition names. |
| <a name="output_scopes"></a> [scopes](#output\_scopes) | Map of assignment keys to assignment scopes. |
<!-- END_TF_DOCS -->
