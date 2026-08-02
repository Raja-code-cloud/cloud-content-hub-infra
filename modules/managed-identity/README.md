# Azure User Assigned Managed Identity Module

Creates exactly **one** Azure User Assigned Managed Identity (UAMI). No role assignments, federated credentials, or access policies are created.

## Purpose

- Provide a reusable, environment-agnostic managed identity for platform workloads
- Expose Client ID, Principal ID, and Tenant ID for downstream RBAC and integration modules
- Enforce consistent tagging via the shared foundation
- Serve as the identity foundation for Container Apps, Key Vault, Storage, and PostgreSQL modules (future phases)

## Architecture

```
environments/<env>/
    module "common"            ──▶ tags, names, location
    module "resource_group"    ──▶ resource group scope
    module "managed_identity"  ──▶ azurerm_user_assigned_identity
            │
            ▼
    Future modules (separate implementations)
    ├── role assignments       (principal_id)
    ├── federated credentials  (resource_id)
    ├── key vault access       (principal_id)
    └── container apps         (resource_id / client_id)
```

This module creates **only** the managed identity resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `identity_name` | Managed identity name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Azure Resource Manager ID |
| `client_id` | Client ID for application and service configuration |
| `principal_id` | Object ID for Azure RBAC role assignments |
| `resource_id` | Azure Resource Manager ID |
| `name` | Identity name |
| `tenant_id` | Azure AD Tenant ID |
| `identity` | Non-sensitive metadata object for downstream modules |

## Example Usage

### Environment Root Module

```hcl
module "common" {
  source = "../../modules/common"

  project_name     = var.project_name
  application_name = var.application_name
  environment      = var.environment
  location         = var.location
  owner            = var.owner
  business_unit    = var.business_unit
  cost_center      = var.cost_center
  tags             = var.tags
  additional_tags  = var.additional_tags
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = module.common.resource_names["resource_group"]
  location = module.common.location
  tags     = module.common.tags
}

module "managed_identity" {
  source = "../../modules/managed-identity"

  identity_name       = module.common.resource_names["identity"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags
}
```

### Downstream RBAC (Future Module — Not This Module)

```hcl
# Role assignment module (future phase)
# principal_id = module.managed_identity.principal_id
# scope        = module.resource_group.id
```

### Container Apps Integration (Future Module)

```hcl
# container-app module (future phase)
# identity_ids = [module.managed_identity.resource_id]
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed identity name |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **No permissions granted** — This module does not assign roles, access policies, or federated credentials. Apply least privilege in dedicated RBAC modules.
- **Principal ID** — Use `principal_id` (not `client_id`) when creating Azure RBAC role assignments.
- **Client ID** — Use `client_id` when configuring applications to authenticate as this identity.
- **Tags** — Always pass `module.common.tags` for ownership and audit traceability.
- **Scope** — Create one identity per workload boundary; avoid sharing identities across unrelated services.

## Cost Considerations

User Assigned Managed Identities are **free**. There is no charge for creating or holding a UAMI.

Costs may arise indirectly from resources the identity accesses (Storage, Key Vault, etc.) — those are billed to the accessed resources, not the identity itself.

## Operational Guidance

- Identity names are immutable in practice — choose names via `modules/naming` before first deployment.
- Deleting and recreating an identity produces a new Client ID and Principal ID — update all downstream references.
- Store `client_id` and `tenant_id` in application configuration; use Key Vault for sensitive runtime secrets (future module).
- Federated credentials for GitHub Actions OIDC will be added in a dedicated module using `resource_id`.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Resource Group Module](../resource-group/README.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
