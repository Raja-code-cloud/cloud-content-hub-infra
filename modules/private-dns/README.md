# Azure Private DNS Module

Creates **Azure Private DNS zones** and **virtual network links**. Does not create private endpoints, DNS records, public DNS zones, DNS forwarders, or virtual networks.

## Purpose

- Provision private DNS zones required for Azure Private Link name resolution
- Link existing virtual networks to private DNS zones
- Support multiple zones and multi-VNet topologies via stable `for_each` keys
- Prepare the platform for future private networking without hardcoding service-specific values

This module creates **only**:

- `azurerm_private_dns_zone`
- `azurerm_private_dns_zone_virtual_network_link`

## Architecture

```
environments/<env>/
    module "networking"       ──▶ existing VNets (vnet_id)
    module "private_dns"      ──▶ private DNS zones + VNet links
            │
            ▼
    module "private_endpoint" ──▶ zone_ids references
    module "postgresql_..."   ──▶ private_dns_zone_id reference
```

Private DNS zones must exist before private endpoints register DNS zone groups. DNS **records** are created automatically by private endpoints — this module does not manage A-records directly.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Required | Description |
|------|:--------:|-------------|
| `resource_group_name` | yes | Resource group for private DNS resources |
| `private_dns_zones` | no | List of private DNS zones to create |
| `virtual_network_links` | no | List of VNet links to existing virtual networks |
| `tags` | no | Tags applied to all resources |

### Private DNS zone object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `name` | yes | — | Private DNS zone FQDN (used as `for_each` key) |
| `registration_enabled` | no | `false` | Reserved for future use; auto-registration is configured on VNet links |

Azure Private DNS zones do not support auto-registration at the zone level. Configure `registration_enabled` on virtual network links instead.

### Virtual network link object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `key` | yes | — | Stable `for_each` identifier |
| `zone_name` | yes | — | Private DNS zone name to link (must exist in `private_dns_zones`) |
| `link_name` | yes | — | Azure virtual network link name |
| `vnet_id` | yes | — | Existing virtual network resource ID |
| `registration_enabled` | no | `false` | Enable auto-registration of VM DNS records in the linked VNet |

## Outputs

| Name | Description |
|------|-------------|
| `zone_ids` | Map of zone names to private DNS zone resource IDs |
| `zone_names` | Map of zone names to zone FQDNs |
| `virtual_network_link_ids` | Map of link keys to virtual network link resource IDs |
| `private_dns_zones` | Non-sensitive zone metadata |
| `virtual_network_links` | Non-sensitive link metadata |

## Examples

### PostgreSQL Flexible Server

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    {
      name = "privatelink.postgres.database.azure.com"
    },
  ]

  virtual_network_links = [
    {
      key        = "hub-postgres-dns"
      zone_name  = "privatelink.postgres.database.azure.com"
      link_name  = "hub-vnet-postgres-dns"
      vnet_id    = module.networking.vnet_id
    },
  ]
}
```

Reference in PostgreSQL module:

```hcl
private_dns_zone_id = module.private_dns.zone_ids["privatelink.postgres.database.azure.com"]
```

### Key Vault

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    {
      name = "privatelink.vaultcore.azure.net"
    },
  ]

  virtual_network_links = [
    {
      key       = "hub-keyvault-dns"
      zone_name = "privatelink.vaultcore.azure.net"
      link_name = "hub-vnet-keyvault-dns"
      vnet_id   = module.networking.vnet_id
    },
  ]
}
```

### Storage (blob, file, queue, table)

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    { name = "privatelink.blob.core.windows.net" },
    { name = "privatelink.file.core.windows.net" },
    { name = "privatelink.queue.core.windows.net" },
    { name = "privatelink.table.core.windows.net" },
  ]

  virtual_network_links = [
    {
      key       = "hub-storage-blob-dns"
      zone_name = "privatelink.blob.core.windows.net"
      link_name = "hub-vnet-blob-dns"
      vnet_id   = module.networking.vnet_id
    },
    {
      key       = "hub-storage-file-dns"
      zone_name = "privatelink.file.core.windows.net"
      link_name = "hub-vnet-file-dns"
      vnet_id   = module.networking.vnet_id
    },
  ]
}
```

### Azure Container Registry

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    {
      name = "privatelink.azurecr.io"
    },
  ]

  virtual_network_links = [
    {
      key       = "hub-acr-dns"
      zone_name = "privatelink.azurecr.io"
      link_name = "hub-vnet-acr-dns"
      vnet_id   = module.networking.vnet_id
    },
  ]
}
```

### Redis and multiple services

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    { name = "privatelink.redis.cache.windows.net" },
    { name = "privatelink.vaultcore.azure.net" },
    { name = "privatelink.postgres.database.azure.com" },
    { name = "privatelink.azurecr.io" },
    { name = "privatelink.blob.core.windows.net" },
  ]

  virtual_network_links = [
    {
      key       = "hub-redis-dns"
      zone_name = "privatelink.redis.cache.windows.net"
      link_name = "hub-vnet-redis-dns"
      vnet_id   = module.networking.vnet_id
    },
  ]
}
```

### Multiple VNets (hub and spoke)

```hcl
module "private_dns" {
  source = "../../modules/private-dns"

  resource_group_name = module.resource_group.name
  tags                = module.common.tags

  private_dns_zones = [
    {
      name = "privatelink.blob.core.windows.net"
    },
  ]

  virtual_network_links = [
    {
      key       = "hub-blob-dns"
      zone_name = "privatelink.blob.core.windows.net"
      link_name = "hub-vnet-blob-dns"
      vnet_id   = module.networking_hub.vnet_id
    },
    {
      key       = "spoke-a-blob-dns"
      zone_name = "privatelink.blob.core.windows.net"
      link_name = "spoke-a-vnet-blob-dns"
      vnet_id   = module.networking_spoke_a.vnet_id
    },
    {
      key       = "spoke-b-blob-dns"
      zone_name = "privatelink.blob.core.windows.net"
      link_name = "spoke-b-vnet-blob-dns"
      vnet_id   = module.networking_spoke_b.vnet_id
    },
  ]
}
```

Each VNet requires its own link to the same private DNS zone. Link names must be unique per zone.

## Operational Guidance

1. **Create zones before private endpoints** — Private endpoints reference zone IDs in DNS zone groups.
2. **Link all resolving VNets** — Every VNet that must resolve private endpoint FQDNs needs a virtual network link.
3. **Keep registration disabled for Private Link zones** — Auto-registration is for VM workloads, not Private Link `privatelink.*` zones.
4. **Use one zone per Private Link namespace** — Do not combine unrelated services in a single zone.
5. **Manage DNS records separately** — A-records for private endpoints are created by the private endpoint DNS zone group, not this module.

## Migration Strategy

| Phase | Action |
|-------|--------|
| 1. Foundation | Deploy private DNS zones and hub VNet links |
| 2. Spoke expansion | Add virtual network links for each spoke VNet |
| 3. Private endpoints | Deploy `private-endpoint` module referencing `zone_ids` |
| 4. Service integration | Configure PostgreSQL VNet integration with `private_dns_zone_id` |
| 5. Validation | Verify name resolution from workloads using `nslookup` against Azure DNS (168.63.129.16) |

For brownfield environments, import existing zones and links before applying module management:

```bash
terraform import 'module.private_dns.azurerm_private_dns_zone.this["privatelink.blob.core.windows.net"]' /subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net
```

## Security Best Practices

| Practice | Rationale |
|----------|-----------|
| Do not create public DNS zones in this module | Prevents accidental public exposure of internal names |
| Do not manage DNS records here | Records are tied to private endpoints; separation reduces blast radius |
| Consume existing VNets only | Network boundaries remain controlled by the networking module |
| Disable auto-registration on Private Link zones | Prevents unintended DNS record creation |
| Apply consistent tags | Supports cost allocation and ownership tracking |
| Use RBAC least privilege | Grant `Private DNS Zone Contributor` only to deployment identities |

## Cost Considerations

Private DNS zones incur a small per-zone monthly charge plus query volume costs. Linking multiple VNets to the same zone does not create additional zones. Minimize zone count by sharing standard `privatelink.*` zones across services of the same type.

## Related

- [Networking Module](../networking/README.md)
- [Private Endpoint Module](../private-endpoint/README.md)
- [PostgreSQL Flexible Server Module](../postgresql-flexible-server/README.md)

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
| [azurerm_private_dns_zone.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones) | List of Azure Private DNS zones to create. Zone name is used as the stable for\_each identifier. | <pre>list(object({<br/>    name                 = string<br/>    registration_enabled = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group where private DNS zones and virtual network links are created. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all private DNS zones and virtual network links created by this module. | `map(string)` | `{}` | no |
| <a name="input_virtual_network_links"></a> [virtual\_network\_links](#input\_virtual\_network\_links) | List of virtual network links to associate existing VNets with private DNS zones. Each entry requires a stable key for for\_each identity at scale. | <pre>list(object({<br/>    key                  = string<br/>    zone_name            = string<br/>    link_name            = string<br/>    vnet_id              = string<br/>    registration_enabled = optional(bool, false)<br/>  }))</pre> | `[]` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_dns_zones"></a> [private\_dns\_zones](#output\_private\_dns\_zones) | Non-sensitive private DNS zone metadata for downstream module composition. |
| <a name="output_virtual_network_link_ids"></a> [virtual\_network\_link\_ids](#output\_virtual\_network\_link\_ids) | Map of virtual network link keys to Azure Private DNS virtual network link resource IDs. |
| <a name="output_virtual_network_links"></a> [virtual\_network\_links](#output\_virtual\_network\_links) | Non-sensitive virtual network link metadata for downstream module composition. |
| <a name="output_zone_ids"></a> [zone\_ids](#output\_zone\_ids) | Map of private DNS zone names to Azure Private DNS zone resource IDs. |
| <a name="output_zone_names"></a> [zone\_names](#output\_zone\_names) | Map of private DNS zone names to zone FQDNs. |
<!-- END_TF_DOCS -->