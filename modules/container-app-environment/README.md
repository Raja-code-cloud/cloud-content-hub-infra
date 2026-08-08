# Azure Container Apps Environment Module

Creates exactly **one** Azure Container Apps Environment linked to an existing Log Analytics Workspace.

## Purpose

- Provide a reusable, environment-agnostic compute platform for Azure Container Apps
- Link platform logs to a centralized Log Analytics Workspace
- Default to Consumption workload profile for scale-to-zero and low cost
- Support future enterprise scaling via optional dedicated workload profiles and VNet integration
- Enforce consistent tagging via the shared foundation

This module does **not** create Container Apps, Dapr components, jobs, certificates, custom domains, private endpoints, role assignments, or diagnostic settings — those are implemented in separate modules.

## Architecture

```
environments/<env>/
    module "common"                    ──▶ tags, names, location
    module "resource_group"            ──▶ resource group scope
    module "log_analytics"             ──▶ existing workspace (dependency)
    module "container_app_environment" ──▶ azurerm_container_app_environment
            │
            ▼
    Future modules (separate implementations)
    ├── container-app               (container_app_environment_id)
    ├── dapr-component              (environment scope)
    ├── certificate                 (custom domains)
    ├── private endpoint            (network module)
    ├── diagnostic settings         (log analytics)
    └── role assignment             (managed identity)
```

This module creates **only** the Container Apps Environment. It does not create the resource group or Log Analytics Workspace.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `environment_name` | Environment name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `log_analytics_workspace_id` | Log Analytics Workspace resource ID | `string` | — | yes |
| `internal_load_balancer_enabled` | Use internal load balancer for ingress | `bool` | `false` | no |
| `zone_redundancy_enabled` | Enable zone redundancy | `bool` | `false` | no |
| `infrastructure_subnet_id` | Delegated subnet for VNet integration | `string` | `null` | no |
| `workload_profile_enabled` | Configure workload profiles on create | `bool` | `true` | no |
| `workload_profiles` | Workload profile definitions | `list(object)` | Consumption only | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Default Rationale (Scale-to-Zero / Low-Cost / Future Scaling)

| Setting | Default | Reason |
|---------|---------|--------|
| `internal_load_balancer_enabled` | `false` | Public ingress; no dedicated ILB infrastructure cost |
| `zone_redundancy_enabled` | `false` | Avoids zone-redundancy overhead for dev/single-user |
| `workload_profile_enabled` | `true` | Enables Consumption profile now; allows dedicated profiles later without environment recreation |
| `workload_profiles` | `[Consumption]` | Scale-to-zero serverless billing; no dedicated VM nodes |
| `infrastructure_subnet_id` | `null` | No VNet integration cost until networking module is applied |

Override defaults per environment via module arguments — do not modify module defaults for production-specific values.

### Workload Profile Guidance

| Profile Type | Use Case |
|--------------|----------|
| `Consumption` | Serverless, scale-to-zero workloads (default) |
| `D4`, `D8`, `D16`, `D32` | General-purpose dedicated compute |
| `E4`, `E8`, `E16`, `E32` | Memory-optimized dedicated compute |
| `NC24-A100`, `NC48-A100`, `NC96-A100` | GPU workloads |

When `workload_profile_enabled = false`, the environment is created without workload profiles (legacy consumption-only mode). Dedicated profiles **cannot** be added later without recreating the environment.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | Container Apps Environment resource ID |
| `name` | no | Environment name |
| `default_domain` | no | Default domain suffix for apps in this environment |
| `static_ip` | no | Static IP when VNet integrated; null otherwise |
| `resource_id` | no | Azure Resource Manager ID |
| `location` | no | Azure region |
| `log_analytics_workspace_id` | no | Linked Log Analytics Workspace resource ID |
| `container_app_environment` | no | Non-sensitive metadata object for downstream modules |

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

module "log_analytics" {
  source = "../../modules/log-analytics"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  workspace_name      = module.common.resource_names["log_analytics"]
  tags                = module.common.tags
}

module "container_app_environment" {
  source = "../../modules/container-app-environment"

  environment_name           = module.common.resource_names["cae"]
  resource_group_name        = module.resource_group.name
  location                   = module.common.location
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
  tags                       = module.common.tags
}
```

Extend `standard_resource_names` in `module.common` when `log_analytics` is not in the default name batch:

```hcl
standard_resource_names = merge(
  var.standard_resource_names,
  {
    log_analytics = { resource_type = "log_analytics" }
  }
)
```

### Production Overrides (VNet + Zone Redundancy)

```hcl
module "container_app_environment" {
  source = "../../modules/container-app-environment"

  environment_name           = module.common.resource_names["cae"]
  resource_group_name        = module.resource_group.name
  location                   = module.common.location
  log_analytics_workspace_id = module.log_analytics.workspace_resource_id
  tags                       = module.common.tags

  infrastructure_subnet_id       = module.networking.container_apps_subnet_id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  workload_profiles = [
    {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    },
    {
      name                  = "general-purpose"
      workload_profile_type = "D4"
      minimum_count         = 1
      maximum_count         = 3
    },
  ]
}
```

### Downstream Integration (Future Modules)

```hcl
# Container App (future module)
# container_app_environment_id = module.container_app_environment.id

# Diagnostic settings (future module)
# target_resource_id = module.container_app_environment.resource_id
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Merged tags, location, pre-computed environment name |
| `modules/resource-group` | Resource group scope |
| `modules/log-analytics` | Existing workspace (`log_analytics_workspace_id` input) |
| `modules/networking` (future) | Delegated subnet for VNet integration |
| Environment root providers | `azurerm` inherited from environment |

## Security Considerations

- **No RBAC in module** — Assign roles (e.g. Container Apps Contributor) via separate identity modules.
- **No private endpoints** — Configure private connectivity via a future networking module.
- **No certificates or custom domains** — Managed by separate modules to maintain single responsibility.
- **Internal load balancer** — Set `internal_load_balancer_enabled = true` with `infrastructure_subnet_id` for private ingress.
- **Tags** — Always pass `module.common.tags` for ownership and audit traceability.
- **Log Analytics linkage** — Platform logs flow to the linked workspace; restrict workspace access via RBAC separately.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| Consumption profile | Pay per vCPU/memory used; scales to zero when idle — lowest cost default |
| Dedicated profiles | Fixed cost per workload profile node (`minimum_count` × node price) |
| Zone redundancy | Additional infrastructure cost; requires VNet integration |
| VNet integration | Subnet delegation has no direct cost; associated networking resources may |
| Log Analytics | Platform logs ingest into linked workspace (per GB) |

Target monthly cost for default configuration (Consumption-only, no VNet, no zone redundancy) is typically well under $150 for low-traffic single-user workloads. Container app compute and log ingestion are billed separately.

## Scaling Considerations

- **Consumption profile** — Automatic scale-to-zero; ideal for variable or dev workloads.
- **Dedicated profiles** — Add `D*` or `E*` profiles with `minimum_count` / `maximum_count` for predictable performance.
- **Workload profile lock-in** — Environments created without workload profiles cannot add them later. Default `workload_profile_enabled = true` avoids this limitation.
- **Zone redundancy** — Enable for production HA; requires `infrastructure_subnet_id`.
- **VNet integration** — Required for internal load balancer, private endpoints, and many enterprise network policies.

## Operational Guidance

- Set `logs_destination` to `log-analytics` internally (azurerm v5 requirement) when linking a workspace.
- Container Apps Environment must be in the **same region** as the linked Log Analytics Workspace.
- `default_domain` is required by downstream Container App modules for ingress configuration.
- `static_ip` is only populated when `infrastructure_subnet_id` is configured.
- Destroying the environment removes all container apps within it — manage apps via the container-app module lifecycle.
- Changing workload profile composition may force environment recreation — plan carefully in production.

## Related

- [Shared Foundation](../../docs/terraform/shared-foundation.md)
- [Log Analytics Module](../log-analytics/README.md)
- [Resource Group Module](../resource-group/README.md)
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
| [azurerm_container_app_environment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Name of the Container Apps Environment. Must be supplied by the caller — this module does not generate names. | `string` | n/a | yes |
| <a name="input_infrastructure_subnet_id"></a> [infrastructure\_subnet\_id](#input\_infrastructure\_subnet\_id) | Optional resource ID of the delegated subnet for VNet-integrated Container Apps Environment infrastructure. | `string` | `null` | no |
| <a name="input_internal_load_balancer_enabled"></a> [internal\_load\_balancer\_enabled](#input\_internal\_load\_balancer\_enabled) | When true, uses an internal load balancer for ingress. Requires infrastructure\_subnet\_id. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the Container Apps Environment. Should match the linked Log Analytics Workspace region. | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Resource ID of the existing Log Analytics Workspace. This module does not create the workspace. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the Container Apps Environment is created. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the Container Apps Environment. Pass merged tags from modules/common — never hardcode tags in this module. | `map(string)` | n/a | yes |
| <a name="input_workload_profile_enabled"></a> [workload\_profile\_enabled](#input\_workload\_profile\_enabled) | When true, configures workload profiles on the environment. Required to add dedicated profiles later without recreating the environment. | `bool` | `true` | no |
| <a name="input_workload_profiles"></a> [workload\_profiles](#input\_workload\_profiles) | Workload profiles for the Container Apps Environment. Defaults to Consumption-only for scale-to-zero. | <pre>list(object({<br/>    name                  = string<br/>    workload_profile_type = string<br/>    minimum_count         = optional(number)<br/>    maximum_count         = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "Consumption",<br/>    "workload_profile_type": "Consumption"<br/>  }<br/>]</pre> | no |
| <a name="input_zone_redundancy_enabled"></a> [zone\_redundancy\_enabled](#input\_zone\_redundancy\_enabled) | When true, enables zone redundancy for the Container Apps Environment infrastructure. | `bool` | `false` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app_environment"></a> [container\_app\_environment](#output\_container\_app\_environment) | Non-sensitive Container Apps Environment metadata for downstream module composition. |
| <a name="output_default_domain"></a> [default\_domain](#output\_default\_domain) | The default domain suffix for container apps deployed in this environment. |
| <a name="output_id"></a> [id](#output\_id) | The Azure Resource Manager ID of the Container Apps Environment. |
| <a name="output_location"></a> [location](#output\_location) | The Azure region of the Container Apps Environment. |
| <a name="output_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#output\_log\_analytics\_workspace\_id) | The resource ID of the linked Log Analytics Workspace. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Container Apps Environment. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the Container Apps Environment. |
| <a name="output_static_ip"></a> [static\_ip](#output\_static\_ip) | The static IP address of the Container Apps Environment when VNet integration is configured. Null for consumption-only environments without infrastructure subnet. |
<!-- END_TF_DOCS -->
