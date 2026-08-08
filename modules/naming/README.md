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


## Requirements

## Requirements

No requirements.

## Providers

## Providers

No providers.

## Modules

## Modules

No modules.

## Resources

## Resources

No resources.

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Application identifier used in tags and optional name segments. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment identifier. | `string` | n/a | yes |
| <a name="input_include_location"></a> [include\_location](#input\_include\_location) | When true, include the location short code in the generated name for globally unique resources. | `bool` | `false` | no |
| <a name="input_instance"></a> [instance](#input\_instance) | Optional instance suffix to distinguish multiple resources of the same type. | `string` | `""` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources are deployed. | `string` | n/a | yes |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Optional short region code. Computed automatically from location when null. | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Short project identifier used as the leading segment in resource names (e.g. cch). | `string` | n/a | yes |
| <a name="input_resource_type"></a> [resource\_type](#input\_resource\_type) | Resource type key from the naming catalog (e.g. acr, cae, postgres). Required for single-name mode. | `string` | `null` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Optional batch naming map. Keys are logical names; values define resource\_type, instance, and include\_location overrides. | <pre>map(object({<br/>    resource_type    = string<br/>    instance         = optional(string, "")<br/>    include_location = optional(bool, false)<br/>  }))</pre> | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allowed_region_codes"></a> [allowed\_region\_codes](#output\_allowed\_region\_codes) | Canonical list of supported Azure region codes for module variable validation. |
| <a name="output_allowed_regions"></a> [allowed\_regions](#output\_allowed\_regions) | Map of supported Azure regions to short codes. |
| <a name="output_environment_short"></a> [environment\_short](#output\_environment\_short) | Abbreviated environment code (dev, stg, prd). |
| <a name="output_location_short"></a> [location\_short](#output\_location\_short) | Short region code derived from location or supplied explicitly. |
| <a name="output_name"></a> [name](#output\_name) | Generated name for single-name mode (resource\_type input). Null when resource\_type is not set. |
| <a name="output_names"></a> [names](#output\_names) | Map of generated names keyed by logical name from the resources input or default for single-name mode. |
| <a name="output_resource_catalog"></a> [resource\_catalog](#output\_resource\_catalog) | Supported resource type catalog with naming constraints. |
| <a name="output_resource_prefix"></a> [resource\_prefix](#output\_resource\_prefix) | Standard resource prefix in the form <project>-<environment> (e.g. cch-dev). |
| <a name="output_resource_prefix_short"></a> [resource\_prefix\_short](#output\_resource\_prefix\_short) | Compact resource prefix without delimiters for globally unique names. |
| <a name="output_standard_labels"></a> [standard\_labels](#output\_standard\_labels) | Standard label map for use in tags and metadata. |
<!-- END_TF_DOCS -->

## Outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
