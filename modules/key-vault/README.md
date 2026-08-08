# Azure Key Vault Module

Creates exactly **one** Azure Key Vault. No secrets, keys, certificates, RBAC assignments, access policies, or private endpoints are created.

## Purpose

- Provide a reusable, environment-agnostic secrets and key management vault
- Enable RBAC-based authorization by default for enterprise security
- Enforce soft delete and purge protection suitable for production workloads
- Expose vault URI and metadata for downstream secret and certificate modules

## Architecture

```
environments/<env>/
    module "common"            ──▶ tags, names, location
    module "resource_group"    ──▶ resource group scope
    module "key_vault"         ──▶ azurerm_key_vault
            │
            ▼
    Future modules (separate implementations)
    ├── RBAC role assignments   (Key Vault Secrets Officer, etc.)
    ├── secrets / keys / certs  (vault_uri)
    ├── private endpoints       (Premium / network module)
    └── diagnostic settings     (log analytics)
```

This module creates **only** the Key Vault resource.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module. The module reads the current tenant ID via `azurerm_client_config` — no hardcoded tenant values.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `vault_name` | Globally unique vault name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group name | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `sku_name` | `standard` or `premium` | `string` | `standard` | no |
| `enable_rbac_authorization` | Use Azure RBAC for data plane | `bool` | `true` | no |
| `purge_protection_enabled` | Prevent permanent deletion | `bool` | `true` | no |
| `soft_delete_retention_days` | Soft-delete retention (7–90 days) | `number` | `90` | no |
| `public_network_access_enabled` | Allow public internet access | `bool` | `true` | no |
| `enabled_for_deployment` | VM certificate deployment | `bool` | `false` | no |
| `enabled_for_disk_encryption` | Azure Disk Encryption integration | `bool` | `false` | no |
| `enabled_for_template_deployment` | ARM template secret retrieval | `bool` | `false` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale

| Setting | Default | Reason |
|---------|---------|--------|
| `sku_name` | `standard` | Cost-effective for most secret workloads |
| `enable_rbac_authorization` | `true` | Enterprise RBAC over legacy access policies |
| `soft_delete_retention_days` | `90` | Maximum retention for recovery window |
| `purge_protection_enabled` | `true` | Prevents accidental permanent deletion |
| `public_network_access_enabled` | `true` | Configurable; disable when private endpoints are added |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Azure Resource Manager ID |
| `vault_uri` | Key Vault data plane URI |
| `name` | Vault name |
| `resource_id` | ARM resource ID (alias of `id`) |
| `location` | Azure region |
| `tenant_id` | Azure AD Tenant ID |
| `vault` | Non-sensitive metadata object |

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

module "key_vault" {
  source = "../../modules/key-vault"

  vault_name          = module.common.resource_names["key_vault"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  public_network_access_enabled = var.environment != "prod"
}
```

### Production Hardening

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  vault_name          = module.common.resource_names["key_vault"]
  resource_group_name = module.resource_group.name
  location            = module.common.location
  tags                = module.common.tags

  sku_name                      = "premium"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
}
```

Private endpoints will be configured in a future networking module.

### Future Integration Points

```hcl
# RBAC (future module)
# scope        = module.key_vault.resource_id
# principal_id = module.managed_identity.principal_id
# role         = "Key Vault Secrets User"

# Secret (future module)
# key_vault_id = module.key_vault.id
# vault_uri    = module.key_vault.vault_uri
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed vault name |
| `modules/resource-group` | Resource group scope |
| Environment root providers | `azurerm` inherited; tenant from deployment context |

## Security Considerations

- **RBAC enabled by default** — Assign roles in a dedicated RBAC module; do not use access policies when RBAC is enabled.
- **Purge protection** — Enabled by default; vault and secrets cannot be permanently deleted until retention expires.
- **No secrets in this module** — Secrets, keys, and certificates are managed by separate modules.
- **Public access** — Disable `public_network_access_enabled` in production when private endpoints are configured.
- **Tenant ID** — Resolved from deployment context via `azurerm_client_config`; ensure CI/CD authenticates to the correct tenant.

## Cost Considerations

| SKU | Use Case | Cost Profile |
|-----|----------|--------------|
| `standard` | Software-protected keys and secrets | Lower cost; suitable for most workloads |
| `premium` | HSM-backed keys | Higher cost; required for FIPS 140-2 Level 3 keys |

Operations (secret read/write) are billed per transaction. Premium SKU adds HSM-protected key hourly charges.

## Operational Guidance

- Vault names are **globally unique** and **immutable** — choose via `modules/naming` before first deploy.
- **Purge protection cannot be disabled** once enabled without deleting and recreating the vault.
- **Soft delete retention** can only be changed within allowed bounds; decreasing may require support.
- Use `vault_uri` for SDK and application configuration; use `resource_id` for RBAC scope.
- Recovery from soft delete: use Azure Portal or CLI within the retention window.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Resource Group Module](../resource-group/README.md)
- [Managed Identity Module](../managed-identity/README.md)
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
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_rbac_authorization"></a> [enable\_rbac\_authorization](#input\_enable\_rbac\_authorization) | When true, uses Azure RBAC for data plane authorization instead of vault access policies. | `bool` | `true` | no |
| <a name="input_enabled_for_deployment"></a> [enabled\_for\_deployment](#input\_enabled\_for\_deployment) | When true, allows Azure Virtual Machines to retrieve certificates stored as secrets. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | When true, allows Azure Disk Encryption to retrieve secrets and keys. | `bool` | `false` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | When true, allows Azure Resource Manager to retrieve secrets during template deployments. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Key Vault. | `string` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | When true, allows access to the Key Vault over the public internet. | `bool` | `true` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | When true, prevents permanent deletion during the retention period after soft delete. | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the Key Vault is created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for the Key Vault. Standard is recommended for most workloads. | `string` | `"standard"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Number of days to retain soft-deleted vaults and objects (7-90). | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Key Vault. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | Name of the Azure Key Vault. Must be globally unique and supplied by the caller — this module does not generate names. | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The Azure Resource Manager ID of the Key Vault. |
| <a name="output_location"></a> [location](#output\_location) | The Azure region of the Key Vault. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Key Vault. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the Key Vault. |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | The Azure AD Tenant ID associated with the Key Vault. |
| <a name="output_vault"></a> [vault](#output\_vault) | Non-sensitive Key Vault metadata for downstream module composition. |
| <a name="output_vault_uri"></a> [vault\_uri](#output\_vault\_uri) | The URI of the Key Vault for data plane operations. |
<!-- END_TF_DOCS -->
