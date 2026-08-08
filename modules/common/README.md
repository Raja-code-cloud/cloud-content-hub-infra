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


## Requirements

## Requirements

No requirements.

## Providers

## Providers

No providers.

## Modules

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_naming"></a> [naming](#module\_naming) | ../naming | n/a |

## Resources

## Resources

No resources.

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Supplementary tags supplied by consuming modules or environments. | `map(string)` | `{}` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | Application identifier used in naming and tags. | `string` | n/a | yes |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | Business unit accountable for the workload. | `string` | n/a | yes |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center code for chargeback and budgeting. | `string` | n/a | yes |
| <a name="input_created_by"></a> [created\_by](#input\_created\_by) | Identity or pipeline that created the deployment. | `string` | `"platform-engineering"` | no |
| <a name="input_enforce_required_tags"></a> [enforce\_required\_tags](#input\_enforce\_required\_tags) | When true, validates that required organizational tags are non-empty. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment identifier. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Primary Azure region for resource deployment. | `string` | n/a | yes |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Optional short region code. Computed from location when null. | `string` | `null` | no |
| <a name="input_managed_by"></a> [managed\_by](#input\_managed\_by) | Tool or team managing the resource lifecycle. | `string` | `"terraform"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or individual responsible for the resources. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Short project identifier used in naming and tags (e.g. cch). | `string` | n/a | yes |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Source repository name for traceability tags. | `string` | `"cloud-content-hub-infra"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Optional override for the computed resource prefix. Leave null to derive from project\_name and environment. | `string` | `null` | no |
| <a name="input_standard_resource_names"></a> [standard\_resource\_names](#input\_standard\_resource\_names) | Optional batch of standard platform resource names to pre-compute via the naming module. | <pre>map(object({<br/>    resource_type    = string<br/>    instance         = optional(string, "")<br/>    include_location = optional(bool, false)<br/>  }))</pre> | <pre>{<br/>  "acr": {<br/>    "resource_type": "acr"<br/>  },<br/>  "api": {<br/>    "resource_type": "api"<br/>  },<br/>  "cae": {<br/>    "resource_type": "cae"<br/>  },<br/>  "key_vault": {<br/>    "resource_type": "key_vault"<br/>  },<br/>  "postgres": {<br/>    "resource_type": "postgres"<br/>  },<br/>  "redis": {<br/>    "resource_type": "redis"<br/>  },<br/>  "resource_group": {<br/>    "resource_type": "resource_group"<br/>  },<br/>  "storage": {<br/>    "resource_type": "storage"<br/>  }<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged into the global tag set after base and additional\_tags. | `map(string)` | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_name"></a> [application\_name](#output\_application\_name) | Configured application name. |
| <a name="output_base_tags"></a> [base\_tags](#output\_base\_tags) | Base organizational tags before additional merges. |
| <a name="output_environment"></a> [environment](#output\_environment) | Configured deployment environment. |
| <a name="output_environment_short"></a> [environment\_short](#output\_environment\_short) | Abbreviated environment code. |
| <a name="output_location"></a> [location](#output\_location) | Configured Azure region. |
| <a name="output_location_short"></a> [location\_short](#output\_location\_short) | Short region code for naming. |
| <a name="output_metadata"></a> [metadata](#output\_metadata) | Aggregate metadata for logging, diagnostics, and module composition. |
| <a name="output_naming"></a> [naming](#output\_naming) | Naming module outputs for advanced composition. |
| <a name="output_project_name"></a> [project\_name](#output\_project\_name) | Configured project name. |
| <a name="output_resource_names"></a> [resource\_names](#output\_resource\_names) | Pre-computed standard platform resource names. |
| <a name="output_resource_prefix"></a> [resource\_prefix](#output\_resource\_prefix) | Standard resource prefix (<project>-<environment>). |
| <a name="output_resource_prefix_short"></a> [resource\_prefix\_short](#output\_resource\_prefix\_short) | Compact resource prefix for globally unique names. |
| <a name="output_standard_labels"></a> [standard\_labels](#output\_standard\_labels) | Standard label map combining naming and organizational metadata. |
| <a name="output_tags"></a> [tags](#output\_tags) | Merged global tag set for resource assignment. |
<!-- END_TF_DOCS -->

## Outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
