# Azure Resource Naming Module

Deterministic, reusable Azure resource naming. **No Azure resources are created.**

## Usage

### Via Common Module (Recommended)

```hcl
module "common" {
  source = "../../modules/common"
  # ...
}

# Pre-computed names
module.common.resource_names["acr"]      # => cch-dev-acr
module.common.resource_names["postgres"] # => cch-dev-postgres
```

### Single Name

```hcl
module "naming" {
  source = "../../modules/naming"

  project_name     = "cch"
  application_name = "cloud-content-hub"
  environment      = "dev"
  location         = "eastus"
  resource_type    = "acr"
}

# module.naming.name => cch-dev-acr
```

### Batch Names

```hcl
module "naming" {
  source = "../../modules/naming"

  project_name     = "cch"
  application_name = "cloud-content-hub"
  environment      = "dev"
  location         = "eastus"

  resources = {
    acr  = { resource_type = "acr" }
    cae  = { resource_type = "cae" }
    api  = { resource_type = "api", instance = "api" }
  }
}
```

## Naming Pattern

```
<project>-<environment>-<resource-type>[-<instance>]
```

Globally unique resources (e.g. storage) use compact names with optional location codes.

See [Shared Foundation](../../docs/terraform/shared-foundation.md#naming-strategy) for full documentation.

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
