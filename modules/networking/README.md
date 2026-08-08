# Azure Networking Module

Creates foundational **Virtual Network**, **Subnets**, optional **Network Security Groups**, and **subnet–NSG associations**. Does not create private endpoints, DNS zones, NAT gateways, firewalls, VPN, ExpressRoute, route tables, or DDoS plans.

## Purpose

- Provide reusable platform networking for minimal-cost (public) and future enterprise (private) deployments
- Support delegated subnets for Container Apps, databases, and future private endpoints
- Optional service endpoints and NSG associations
- No public IPs, internet gateways, or out-of-scope resources

This module creates:

- `azurerm_virtual_network`
- `azurerm_subnet` (for_each)
- `azurerm_network_security_group` (optional, for_each)
- `azurerm_subnet_network_security_group_association` (optional)

## Architecture

```
environments/<env>/
    module "resource_group"   ──▶ resource_group_name
    module "common"           ──▶ tags, naming
    module "networking"       ──▶ VNet + subnets (+ optional NSGs)
            │
            ├──▶ module "container_app_environment"  (infrastructure_subnet_id)
            ├──▶ module "postgresql_flexible_server"  (delegated_subnet_id — future)
            └──▶ private-endpoints module              (future — subnet IDs only)
```

## Addressing Strategy

| Tier | VNet CIDR | Example Subnets |
|------|-----------|-----------------|
| Minimal (dev) | `/16` single region | CAE `/23`, app `/24`, mgmt `/27` |
| Production | `/16` or `/15` | CAE `/23`, db `/24`, pe `/24`, mgmt `/27` |

Recommended reserved ranges (example for `10.20.0.0/16`):

| Subnet key | CIDR | Purpose |
|------------|------|---------|
| `cae` | `10.20.0.0/23` | Container Apps Environment (delegated) |
| `app` | `10.20.2.0/24` | Application workloads |
| `db` | `10.20.3.0/24` | PostgreSQL Flexible Server (delegated) |
| `pe` | `10.20.4.0/24` | Private endpoints (future) |
| `mgmt` | `10.20.5.0/27` | Management / jump (future) |

Plan non-overlapping prefixes within the VNet address space. The module validates CIDR format, VNet/subnet overlap, and that subnet prefixes fall within the VNet address space.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `resource_group_name` | yes | Resource group for networking resources |
| `location` | yes | Azure region |
| `vnet_name` | yes | Virtual Network name |
| `address_space` | yes | List of VNet CIDR blocks |
| `tags` | no | Tags applied to all resources (default `{}`) |
| `subnets` | no | Subnet definitions (default `[]`) |
| `network_security_groups` | no | Optional NSGs to create (default `[]`) |

### Subnet object

| Field | Required | Description |
|-------|:--------:|-------------|
| `key` | yes | Stable `for_each` identifier |
| `name` | yes | Subnet name |
| `address_prefixes` | yes | List of CIDR blocks |
| `service_endpoints` | no | e.g. `["Microsoft.Storage", "Microsoft.KeyVault"]` |
| `service_endpoint_policy_ids` | no | Service endpoint policy resource IDs |
| `delegations` | no | Subnet delegations for PaaS services |
| `nsg_id` | no | External NSG resource ID to associate |
| `nsg_key` | no | Key of NSG created by this module |
| `private_endpoint_network_policies` | no | For future private endpoint subnets |
| `private_link_service_network_policies_enabled` | no | Private Link service policies |

Specify **either** `nsg_id` (external) **or** `nsg_key` (module-created), not both.

### Delegation example

```hcl
delegations = [{
  name = "Microsoft.App.environments"
  service_delegation = {
    name    = "Microsoft.App/environments"
    actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  }
}]
```

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Virtual Network resource ID |
| `resource_id` | Same as `vnet_id` |
| `vnet_name` | Virtual Network name |
| `address_space` | VNet address space list |
| `subnet_ids` | Map of subnet keys to IDs |
| `subnet_names` | Map of subnet keys to names |
| `subnets` | Metadata map for composition |
| `network_security_group_ids` | Map of created NSG IDs |
| `network_security_group_names` | Map of created NSG names |

## Examples

### Minimal deployment (dev — no NSGs, public platform)

```hcl
module "networking" {
  source = "../../modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  vnet_name           = module.common.resource_names["vnet"]
  address_space       = ["10.20.0.0/16"]
  tags                = module.common.tags

  subnets = [
    {
      key              = "cae"
      name             = "snet-cae"
      address_prefixes = ["10.20.0.0/23"]
    },
  ]
}
```

### Production-ready deployment

```hcl
module "networking" {
  source = "../../modules/networking"

  resource_group_name = module.resource_group.name
  location            = module.common.location
  vnet_name           = "vnet-platform-prod"
  address_space       = ["10.20.0.0/16"]
  tags                = module.common.tags

  network_security_groups = [
    {
      key  = "cae"
      name = "nsg-cae"
      security_rules = [
        {
          name                       = "Allow-HTTPS-Inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    },
    {
      key  = "db"
      name = "nsg-db"
    },
  ]

  subnets = [
    {
      key              = "cae"
      name             = "snet-cae"
      address_prefixes = ["10.20.0.0/23"]
      nsg_key          = "cae"
      delegations = [{
        name = "Microsoft.App.environments"
        service_delegation = {
          name    = "Microsoft.App/environments"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        }
      }]
    },
    {
      key              = "app"
      name             = "snet-app"
      address_prefixes = ["10.20.2.0/24"]
    },
    {
      key              = "db"
      name             = "snet-db"
      address_prefixes = ["10.20.3.0/24"]
      nsg_key          = "db"
      service_endpoints = ["Microsoft.Sql"]
    },
    {
      key                               = "pe"
      name                              = "snet-pe"
      address_prefixes                  = ["10.20.4.0/24"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      key              = "mgmt"
      name             = "snet-mgmt"
      address_prefixes = ["10.20.5.0/27"]
    },
  ]
}
```

### Container Apps subnet (delegated)

```hcl
{
  key              = "cae"
  name             = "snet-container-apps"
  address_prefixes = ["10.20.0.0/23"]
  delegations = [{
    name = "Microsoft.App.environments"
    service_delegation = {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }]
}
```

Wire to Container Apps Environment:

```hcl
infrastructure_subnet_id = module.networking.subnet_ids["cae"]
```

### Database subnet

```hcl
{
  key               = "db"
  name              = "snet-postgresql"
  address_prefixes  = ["10.20.3.0/24"]
  service_endpoints = ["Microsoft.Sql"]
  delegations = [{
    name = "Microsoft.DBforPostgreSQL.flexibleServers"
    service_delegation = {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }]
}
```

### Delegated subnet with external NSG

```hcl
{
  key              = "cae"
  name             = "snet-cae"
  address_prefixes = ["10.20.0.0/23"]
  nsg_id           = var.existing_nsg_id
  delegations      = [/* ... */]
}
```

## Future Expansion

| Component | Module | Uses from this module |
|-----------|--------|------------------------|
| Private Endpoints | `private-endpoint` (future) | `subnet_ids["pe"]` |
| Private DNS Zones | `private-dns` (future) | VNet link to `vnet_id` |
| Route Tables | `route-table` (future) | Subnet associations |
| NAT Gateway | `nat-gateway` (future) | Subnet IDs |
| Azure Firewall | `firewall` (future) | Dedicated subnet |

## Operational Guidance

1. **Size CAE subnet `/23` minimum** — Container Apps Environment requires at least `/23`.
2. **Deploy networking before compute** — CAE and PostgreSQL VNet integration need subnet IDs.
3. **Keep dev simple** — Single subnet or VNet-only for public dev; add NSGs in stage/prod.
4. **Document IP plan** — Maintain CIDR allocation in architecture docs to avoid overlap.
5. **Import** — `terraform import azurerm_virtual_network.this /subscriptions/.../virtualNetworks/{name}`

## Security Best Practices

| Practice | Rationale |
|----------|-----------|
| No public IPs in this module | Public ingress via Container Apps platform, not subnet PIPs |
| NSGs on sensitive subnets | Database and management subnets in production |
| Service endpoints where needed | Secure PaaS traffic without full private endpoint cost in dev |
| `private_endpoint_network_policies = "Disabled"` on PE subnet | Required for private endpoint deployment (future) |
| Least-privilege NSG rules | Explicit allow rules; avoid `*` in production where possible |

## Related

- [Container Apps Environment Module](../container-app-environment/README.md)
- [PostgreSQL Flexible Server Module](../postgresql-flexible-server/README.md)

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 5.0 |

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
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space for the Virtual Network as a list of CIDR blocks. | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for networking resources. | `string` | n/a | yes |
| <a name="input_network_security_groups"></a> [network\_security\_groups](#input\_network\_security\_groups) | Optional Network Security Groups to create and associate via subnet nsg\_key. | <pre>list(object({<br/>    key  = string<br/>    name = string<br/>    tags = optional(map(string), {})<br/>    security_rules = optional(list(object({<br/>      name                         = string<br/>      priority                     = number<br/>      direction                    = string<br/>      access                       = string<br/>      protocol                     = string<br/>      source_port_range            = optional(string)<br/>      destination_port_range       = optional(string)<br/>      source_port_ranges           = optional(list(string))<br/>      destination_port_ranges      = optional(list(string))<br/>      source_address_prefix        = optional(string)<br/>      destination_address_prefix   = optional(string)<br/>      source_address_prefixes      = optional(list(string))<br/>      destination_address_prefixes = optional(list(string))<br/>      description                  = optional(string)<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where networking resources are created. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets to create within the Virtual Network. Each entry requires a stable key for for\_each identity. | <pre>list(object({<br/>    key                                           = string<br/>    name                                          = string<br/>    address_prefixes                              = list(string)<br/>    service_endpoints                             = optional(list(string), [])<br/>    service_endpoint_policy_ids                   = optional(list(string), [])<br/>    private_endpoint_network_policies             = optional(string)<br/>    private_link_service_network_policies_enabled = optional(bool)<br/>    nsg_id                                        = optional(string)<br/>    nsg_key                                       = optional(string)<br/>    delegations = optional(list(object({<br/>      name = string<br/>      service_delegation = object({<br/>        name    = string<br/>        actions = list(string)<br/>      })<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all networking resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the Virtual Network. | `string` | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_space"></a> [address\_space](#output\_address\_space) | The address space of the Virtual Network. |
| <a name="output_network_security_group_ids"></a> [network\_security\_group\_ids](#output\_network\_security\_group\_ids) | Map of NSG keys to Network Security Group resource IDs created by this module. |
| <a name="output_network_security_group_names"></a> [network\_security\_group\_names](#output\_network\_security\_group\_names) | Map of NSG keys to Network Security Group names created by this module. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The Azure Resource Manager ID of the Virtual Network. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet keys to subnet resource IDs. |
| <a name="output_subnet_names"></a> [subnet\_names](#output\_subnet\_names) | Map of subnet keys to subnet names. |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Non-sensitive subnet metadata for downstream module composition. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The Azure Resource Manager ID of the Virtual Network. |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The name of the Virtual Network. |
<!-- END_TF_DOCS -->