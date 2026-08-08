# Azure Resource Group Module

Creates exactly **one** Azure Resource Group with an optional management lock. This is the foundation module that every other platform module depends on.

## Purpose

- Provide a single, reusable resource group for each environment deployment
- Enforce consistent tagging via the shared foundation
- Optionally protect the resource group with Azure Management Locks
- Expose stable outputs for downstream module composition

## Architecture

```
environments/<env>/
    module "common"          ──▶ tags, names, location
    module "resource_group"  ──▶ azurerm_resource_group (+ optional lock)
            │
            ▼
    Future modules (acr, networking, key-vault, ...)
            └── resource_group_id / name from this module
```

This module:

- **Receives** the resource group name from the caller (via `modules/common` naming outputs)
- **Never** generates names internally
- **Never** hardcodes tags — accepts merged tags from `modules/common`
- Creates **no resources** other than the resource group and optional management lock

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | Resource group name (supplied by caller) | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |
| `create_resource_lock` | Enable Azure Management Lock | `bool` | `false` | no |
| `lock_level` | Lock level: `CanNotDelete` or `ReadOnly` | `string` | `CanNotDelete` | no |
| `lock_name` | Optional lock name override | `string` | `null` | no |
| `lock_notes` | Notes on the management lock | `string` | managed default | no |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource group ID |
| `name` | Resource group name |
| `location` | Azure region |
| `resource_group` | Object with `id`, `name`, `location`, `tags` |
| `lock_id` | Management lock ID (null when lock disabled) |
| `lock_level` | Applied lock level (null when lock disabled) |

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

  create_resource_lock = var.environment == "prod"
  lock_level           = "CanNotDelete"
}
```

### Production with ReadOnly Lock

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  name     = module.common.resource_names["resource_group"]
  location = module.common.location
  tags     = module.common.tags

  create_resource_lock = true
  lock_level           = "ReadOnly"
  lock_notes           = "Production platform resource group — ReadOnly lock applied by Terraform."
}
```

### Downstream Module Reference

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.common.tags
}
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed resource group name |
| Environment root providers | `azurerm` provider inherited from `environments/<env>/providers.tf` |

## Security Considerations

- **Tags** — Always pass merged tags from `modules/common` to maintain ownership, cost center, and environment traceability.
- **Management locks** — Enable `create_resource_lock` in production to prevent accidental deletion. Use `ReadOnly` only when no Terraform changes to locked resources are expected (locks block modifications too).
- **Naming** — Resource group names are supplied externally; validate naming via `modules/naming` before passing to this module.
- **Scope** — The management lock applies to the resource group and its child resources.

## Cost

Azure Resource Groups are **free**. Management locks have **no additional cost**.

## Best Practices

1. Create **one resource group per environment** at the platform level using this module.
2. Pass `module.common.resource_names["resource_group"]` as the name — do not construct names inline.
3. Pass `module.common.tags` — never hardcode tags in this module or its call site.
4. Enable `create_resource_lock` for `stage` and `prod` at minimum.
5. Export `module.resource_group.id` to all downstream modules that require a resource group scope.
6. Do not create multiple resource groups per environment unless a documented architectural requirement exists (use separate module invocations).

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)
- [Example: Common Usage](../../examples/common-usage/README.md)

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
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_resource_lock"></a> [create\_resource\_lock](#input\_create\_resource\_lock) | When true, creates an Azure Management Lock on the resource group. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the resource group is created. | `string` | n/a | yes |
| <a name="input_lock_level"></a> [lock\_level](#input\_lock\_level) | Management lock level applied when create\_resource\_lock is true. Supported values: CanNotDelete, ReadOnly. | `string` | `"CanNotDelete"` | no |
| <a name="input_lock_name"></a> [lock\_name](#input\_lock\_name) | Optional name for the management lock. Defaults to <resource-group-name>-lock when null. | `string` | `null` | no |
| <a name="input_lock_notes"></a> [lock\_notes](#input\_lock\_notes) | Optional notes recorded on the management lock. | `string` | `"Managed by Terraform — prevents accidental deletion of platform resources."` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Azure Resource Group. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the resource group. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the Azure Resource Group. |
| <a name="output_location"></a> [location](#output\_location) | The Azure region of the Resource Group. |
| <a name="output_lock_id"></a> [lock\_id](#output\_lock\_id) | The ID of the management lock when create\_resource\_lock is true. Null when no lock is created. |
| <a name="output_lock_level"></a> [lock\_level](#output\_lock\_level) | The applied management lock level when create\_resource\_lock is true. Null when no lock is created. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Azure Resource Group. |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | Resource group object containing id, name, location, and tags. |
<!-- END_TF_DOCS -->
