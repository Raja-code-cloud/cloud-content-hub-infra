# Common Shared Foundation Module

Shared naming, tagging, and metadata for all platform modules. **No Azure resources are created.**

## Usage

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

# Use in resource modules
# name  = module.common.resource_names["acr"]
# tags  = module.common.tags
```

## Features

- Global tagging with merge support
- Pre-computed platform resource names
- Environment and region abbreviations
- Validation via variable rules and `check` blocks

See [Shared Foundation](../../docs/terraform/shared-foundation.md) for full documentation.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |

## Inputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
