# Azure Container Registry Module

Creates exactly **one** Azure Container Registry (ACR). No role assignments, private endpoints, networking, or diagnostic settings are created.

## Purpose

- Provide a reusable, environment-agnostic container image registry
- Support Container Apps and CI/CD image push/pull workflows (future phases)
- Enforce consistent tagging via the shared foundation
- Expose login server and registry metadata for downstream modules

## Architecture

```
environments/<env>/
    module "common"            ──▶ tags, names, location
    module "resource_group"    ──▶ resource group scope
    module "acr"               ──▶ azurerm_container_registry
            │
            ▼
    Future modules (separate implementations)
    ├── role assignments        (AcrPull / AcrPush for managed identity)
    ├── private endpoints       (Premium SKU)
    ├── container-app           (login_server)
    └── diagnostic settings     (log analytics)
```

This module creates **only** the Container Registry resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `registry_name` | Globally unique registry name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `sku` | `Basic`, `Standard`, or `Premium` | `string` | `Basic` | no |
| `admin_enabled` | Enable admin user account | `bool` | `false` | no |
| `public_network_access_enabled` | Allow public internet access | `bool` | `true` | no |
| `zone_redundancy_enabled` | Enable zone redundancy (Premium only) | `bool` | `false` | no |
| `anonymous_pull_enabled` | Allow unauthenticated pulls | `bool` | `false` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Single-User / Dev)

| Setting | Default | Reason |
|---------|---------|--------|
| `sku` | `Basic` | Lowest cost tier for development |
| `admin_enabled` | `false` | Prefer managed identity over static credentials |
| `anonymous_pull_enabled` | `false` | Prevent unauthenticated image pulls |
| `public_network_access_enabled` | `true` | Simplifies dev/CI access before private endpoints |

### Naming Note

ACR names must be **globally unique**, **5–50 alphanumeric characters** (no hyphens). Standard hyphenated names from `modules/naming` may require a compact variant — supply an alphanumeric name via tfvars or extend the naming catalog for ACR.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | Azure Resource Manager ID |
| `name` | no | Registry name |
| `login_server` | no | Login server FQDN (e.g. `myregistry.azurecr.io`) |
| `resource_id` | no | ARM resource ID (alias of `id`) |
| `sku` | no | Configured SKU tier |
| `admin_username` | **yes** | Admin username when `admin_enabled = true`; else `null` |
| `admin_password` | **yes** | Admin password when `admin_enabled = true`; else `null` |
| `registry` | no | Non-sensitive metadata object |

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

module "acr" {
  source = "../../modules/acr"

  registry_name       = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku = var.environment == "prod" ? "Premium" : "Basic"
}
```

Define `acr_name` in `terraform.tfvars` as a globally unique alphanumeric string (e.g. `cchdeveusacr`).

### Production Upgrade

```hcl
module "acr" {
  source = "../../modules/acr"

  registry_name       = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku                           = "Premium"
  public_network_access_enabled = false
  zone_redundancy_enabled       = true
}
```

Private endpoints and firewall rules will be configured in future networking modules.

### Downstream Integration (Future Modules)

```hcl
# Container App (future module)
# image = "${module.acr.login_server}/my-app:latest"

# Role assignment (future module)
# scope = module.acr.resource_id
# role  = "AcrPull"
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **Admin user disabled by default** — Use managed identity with `AcrPull`/`AcrPush` role assignments (future module).
- **Anonymous pull disabled by default** — Enable only when explicitly required.
- **Public access** — Disable `public_network_access_enabled` in production when private endpoints are configured.
- **Admin credentials** — When `admin_enabled = true`, store credentials in Key Vault; outputs are marked `sensitive`.
- **No RBAC in this module** — Role assignments are implemented separately using `resource_id`.

## Cost Considerations

| SKU | Approximate Use Case | Cost Profile |
|-----|---------------------|--------------|
| `Basic` | Dev / single-user | Lowest fixed cost; limited features |
| `Standard` | Staging / moderate throughput | Higher storage and throughput |
| `Premium` | Production / geo-replication / private link | Highest cost; required for private endpoints and zone redundancy |

Storage and network egress charges apply based on image size and pull frequency.

## Operational Notes

- Registry names are **globally unique** and **immutable** — choose carefully before first deploy.
- SKU upgrades (Basic → Standard → Premium) are supported in place; downgrades may require recreation.
- Use `login_server` output for Docker/Helm/Container Apps image references.
- `terraform import` is supported for existing registries if migrating to this module.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Resource Group Module](../resource-group/README.md)
- [Managed Identity Module](../managed-identity/README.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
