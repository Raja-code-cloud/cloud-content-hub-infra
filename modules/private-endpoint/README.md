# Azure Private Endpoint Module

Creates **Azure Private Endpoints** for existing Private Link-enabled resources. Does not create virtual networks, subnets, private DNS zones, DNS records, or target Azure resources.

## Purpose

- Provision one or many private endpoints via reusable `for_each` composition
- Support any Azure resource that exposes a Private Link subresource
- Integrate with existing private DNS zones through optional DNS zone groups
- Expose network interface metadata and private IP addresses for downstream routing and diagnostics

This module creates **only** `azurerm_private_endpoint` resources.

## Architecture

```
environments/<env>/
    module "networking"              ──▶ VNet, subnets (subnet_id)
    module "private_dns"             ──▶ existing zones (private_dns_zone_ids)
    module "key_vault" / "storage"   ──▶ target resources (target_resource_id)
    module "private_endpoint"        ──▶ azurerm_private_endpoint (for_each)
            │
            ▼
    Workloads in VNet resolve target services via private IP + Private DNS
```

Private endpoints consume existing networking and DNS infrastructure. Target resources must already exist and support Private Link.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 5.0 |

Providers are inherited from the environment root module.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `private_endpoints` | List of private endpoints to create | `list(object)` | `[]` | no |
| `tags` | Default tags merged with per-endpoint tags | `map(string)` | `{}` | no |

### Private Endpoint Object

| Field | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `key` | yes | — | Stable Terraform identifier (2–64 lowercase alphanumeric/hyphen) |
| `private_endpoint_name` | yes | — | Azure private endpoint name |
| `resource_group_name` | yes | — | Resource group for the private endpoint |
| `location` | yes | — | Azure region |
| `subnet_id` | yes | — | Subnet resource ID for endpoint placement |
| `target_resource_id` | yes | — | Private Link-enabled target resource ID |
| `subresource_names` | yes | — | Private Link subresource names (e.g. `vault`, `blob`) |
| `private_dns_zone_group` | no | `null` | Optional DNS zone group with existing zone IDs |
| `network_interface_name` | no | `null` | Alias for custom network interface name |
| `custom_network_interface_name` | no | `null` | Custom NIC name for the private endpoint |
| `private_service_connection_name` | no | `{name}-psc` | Private service connection name |
| `is_manual_connection` | no | `false` | Requires manual approval when `true` |
| `request_message` | no | `null` | Approval request message (max 140 chars) |
| `tags` | no | `{}` | Per-endpoint tags merged over module `tags` |
| `enabled` | no | `true` | When `false`, endpoint is excluded from management |

### Supported Targets

This module is generic and does not hardcode target types. Common subresource names:

| Service | Example subresource | Typical Private DNS zone |
|---------|---------------------|--------------------------|
| Azure Storage | `blob`, `file`, `table`, `queue` | `privatelink.blob.core.windows.net` |
| Azure Key Vault | `vault` | `privatelink.vaultcore.azure.net` |
| Azure Container Registry | `registry` | `privatelink.azurecr.io` |
| PostgreSQL Flexible Server | `postgresqlServer` | `privatelink.postgres.database.azure.com` |
| Azure Cache for Redis | `redisCache` | `privatelink.redis.cache.windows.net` |
| Azure SQL | `sqlServer` | `privatelink.database.windows.net` |

Refer to [Azure Private Link documentation](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview) for subresource names on future services.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `private_endpoint_ids` | no | Map of keys to private endpoint ARM IDs |
| `private_endpoint_names` | no | Map of keys to private endpoint names |
| `network_interface_ids` | no | Map of keys to network interface IDs |
| `network_interface_names` | no | Map of keys to network interface names |
| `private_ip_addresses` | no | Map of keys to allocated private IPs |
| `target_resource_ids` | no | Map of keys to target resource IDs |
| `private_endpoints` | no | Metadata map for downstream composition |

## Example Usage

### Key Vault

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  tags = module.common.tags

  private_endpoints = [{
    key                   = "key-vault"
    private_endpoint_name = module.common.resource_names["key_vault_pe"]
    resource_group_name   = module.resource_group.name
    location              = module.common.location
    subnet_id             = module.networking.subnet_ids["private_endpoints"]
    target_resource_id    = module.key_vault.resource_id
    subresource_names     = ["vault"]

    private_dns_zone_group = {
      name = "key-vault-dns"
      private_dns_zone_ids = [
        module.private_dns.zone_ids["privatelink.vaultcore.azure.net"],
      ]
    }
  }]
}
```

### Storage

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  tags = module.common.tags

  private_endpoints = [
    {
      key                   = "storage-blob"
      private_endpoint_name = "${module.common.name_prefix}-st-blob-pe"
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking.subnet_ids["private_endpoints"]
      target_resource_id    = module.storage.resource_id
      subresource_names     = ["blob"]

      private_dns_zone_group = {
        name = "storage-blob-dns"
        private_dns_zone_ids = [
          module.private_dns.zone_ids["privatelink.blob.core.windows.net"],
        ]
      }
    },
    {
      key                   = "storage-file"
      private_endpoint_name = "${module.common.name_prefix}-st-file-pe"
      resource_group_name   = module.resource_group.name
      location              = module.common.location
      subnet_id             = module.networking.subnet_ids["private_endpoints"]
      target_resource_id    = module.storage.resource_id
      subresource_names     = ["file"]

      private_dns_zone_group = {
        name = "storage-file-dns"
        private_dns_zone_ids = [
          module.private_dns.zone_ids["privatelink.file.core.windows.net"],
        ]
      }
    },
  ]
}
```

### PostgreSQL Flexible Server

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  tags = module.common.tags

  private_endpoints = [{
    key                   = "postgresql"
    private_endpoint_name = module.common.resource_names["postgres_pe"]
    resource_group_name   = module.resource_group.name
    location              = module.common.location
    subnet_id             = module.networking.subnet_ids["private_endpoints"]
    target_resource_id    = module.postgresql_flexible_server.id
    subresource_names     = ["postgresqlServer"]

    private_dns_zone_group = {
      name = "postgresql-dns"
      private_dns_zone_ids = [
        module.private_dns.zone_ids["privatelink.postgres.database.azure.com"],
      ]
    }
  }]
}
```

### Azure Container Registry

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  tags = module.common.tags

  private_endpoints = [{
    key                   = "acr"
    private_endpoint_name = module.common.resource_names["acr_pe"]
    resource_group_name   = module.resource_group.name
    location              = module.common.location
    subnet_id             = module.networking.subnet_ids["private_endpoints"]
    target_resource_id    = module.acr.resource_id
    subresource_names     = ["registry"]

    private_dns_zone_group = {
      name = "acr-dns"
      private_dns_zone_ids = [
        module.private_dns.zone_ids["privatelink.azurecr.io"],
      ]
    }
  }]
}
```

### Azure Cache for Redis

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  tags = module.common.tags

  private_endpoints = [{
    key                   = "redis"
    private_endpoint_name = module.common.resource_names["redis_pe"]
    resource_group_name   = module.resource_group.name
    location              = module.common.location
    subnet_id             = module.networking.subnet_ids["private_endpoints"]
    target_resource_id    = module.redis.resource_id
    subresource_names     = ["redisCache"]

    private_dns_zone_group = {
      name = "redis-dns"
      private_dns_zone_ids = [
        module.private_dns.zone_ids["privatelink.redis.cache.windows.net"],
      ]
    }
  }]
}
```

### Manual Approval Connection

```hcl
module "private_endpoint" {
  source = "../../modules/private-endpoint"

  private_endpoints = [{
    key                   = "shared-service"
    private_endpoint_name = "pe-shared-service"
    resource_group_name   = module.resource_group.name
    location              = module.common.location
    subnet_id             = module.networking.subnet_ids["private_endpoints"]
    target_resource_id    = var.shared_target_resource_id
    subresource_names     = ["sqlServer"]
    is_manual_connection  = true
    request_message       = "Cloud Content Hub prod connection request"
  }]
}
```

Use manual approval when connecting to resources owned by another team or subscription.

## Private Link Overview

Azure Private Link exposes PaaS services through private IP addresses in your virtual network:

1. A **private endpoint** NIC is placed in your subnet
2. Traffic to the target service traverses the Microsoft backbone privately
3. **Private DNS zones** map the service FQDN to the private endpoint IP
4. The target resource must have Private Link enabled and accept the connection

This module handles step 1 only. DNS zones, VNet links, and target resources are managed elsewhere.

## Operational Guidance

| Operation | Guidance |
|-----------|----------|
| Deploy subnet | Use dedicated private endpoint subnet with `private_endpoint_network_policies = "Disabled"` |
| DNS | Link private DNS zones to the VNet before relying on name resolution |
| Approval | Monitor pending connections when `is_manual_connection = true` |
| Multiple subresources | Create one private endpoint per subresource (Azure limitation) |
| Import | Import using the private endpoint ARM resource ID |
| Disable | Set `enabled = false` to remove endpoint from Terraform management |

### Import Example

```shell
terraform import 'module.private_endpoint.azurerm_private_endpoint.this["key-vault"]' \
  "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Network/privateEndpoints/{name}"
```

### Cross-Subscription Targets

`target_resource_id` may reference resources in another subscription when RBAC and Private Link policies allow it. The private endpoint remains in the caller's subscription and subnet. Document ownership and approval workflows for cross-subscription connections.

## Migration Strategy

| Phase | Action |
|-------|--------|
| 1. Prepare | Create private endpoint subnet and private DNS zones |
| 2. Link DNS | Associate zones with the workload VNet |
| 3. Deploy PE | Apply this module with DNS zone groups |
| 4. Validate | Confirm private IP allocation and DNS resolution from a test host |
| 5. Cutover | Update applications to use private FQDNs; disable public access on targets |
| 6. Reconcile | Import existing endpoints if migrating from Portal/ARM templates |

Migrate one service at a time to limit blast radius. Keep public access enabled until private connectivity is verified.

## Security Best Practices

| Practice | Rationale |
|----------|-----------|
| Dedicated PE subnet | Isolates private endpoint NICs from application subnets |
| Disable public access on targets | Ensures traffic uses Private Link after cutover |
| DNS zone groups | Prevents DNS hijacking to public endpoints |
| Automatic approval by default | Reduces friction for same-tenant resources (`is_manual_connection = false`) |
| Manual approval for shared services | Requires explicit owner consent for cross-team connections |
| NSG on PE subnet | Apply least-privilege rules; note NSG on PE subnet has limitations |
| No secrets in Terraform | Private endpoints expose network paths, not credentials |
| Tag ownership | Use merged tags to identify service, environment, and owner |

Do not store credentials or connection strings in this module. Manage secrets via `key-vault-secrets`.

## Best Practices

- Use stable `key` values for Terraform; use descriptive `private_endpoint_name` values for Azure
- Pass subnet IDs from the `networking` module
- Pass private DNS zone IDs from the `private-dns` module — never create zones here
- Create separate endpoints for each subresource (blob vs file, etc.)
- Export `private_ip_addresses` to monitoring and firewall documentation
- Test DNS resolution from Container Apps environment or jump host before cutover

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/networking` | Subnet for private endpoint placement |
| `modules/private-dns` | Existing private DNS zones for zone groups |
| Target service modules | Key Vault, Storage, ACR, PostgreSQL, Redis, SQL |
| Environment root providers | `azurerm` inherited from environment |

## Related

- [Networking Module](../networking/README.md)
- [Key Vault Module](../key-vault/README.md)
- [Storage Module](../storage/README.md)
- [PostgreSQL Flexible Server Module](../postgresql-flexible-server/README.md)
- [Terraform Standards](../../docs/terraform/standards.md)

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
| [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints) | List of Azure Private Endpoints to create. Each entry requires a stable key for for\_each identity at scale. | <pre>list(object({<br/>    key                   = string<br/>    private_endpoint_name = string<br/>    resource_group_name   = string<br/>    location              = string<br/>    subnet_id             = string<br/>    target_resource_id    = string<br/>    subresource_names     = list(string)<br/>    private_dns_zone_group = optional(object({<br/>      name                 = string<br/>      private_dns_zone_ids = list(string)<br/>    }))<br/>    network_interface_name          = optional(string)<br/>    custom_network_interface_name   = optional(string)<br/>    private_service_connection_name = optional(string)<br/>    is_manual_connection            = optional(bool, false)<br/>    request_message                 = optional(string)<br/>    tags                            = optional(map(string), {})<br/>    enabled                         = optional(bool, true)<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags applied to all private endpoints. Merged with optional per-endpoint tags. | `map(string)` | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids) | Map of private endpoint keys to private endpoint network interface IDs. |
| <a name="output_network_interface_names"></a> [network\_interface\_names](#output\_network\_interface\_names) | Map of private endpoint keys to private endpoint network interface names. |
| <a name="output_private_endpoint_ids"></a> [private\_endpoint\_ids](#output\_private\_endpoint\_ids) | Map of private endpoint keys to Azure Resource Manager IDs. |
| <a name="output_private_endpoint_names"></a> [private\_endpoint\_names](#output\_private\_endpoint\_names) | Map of private endpoint keys to private endpoint names. |
| <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints) | Non-sensitive private endpoint metadata for downstream module composition. |
| <a name="output_private_ip_addresses"></a> [private\_ip\_addresses](#output\_private\_ip\_addresses) | Map of private endpoint keys to allocated private IP addresses. |
| <a name="output_target_resource_ids"></a> [target\_resource\_ids](#output\_target\_resource\_ids) | Map of private endpoint keys to target Private Link resource IDs. |
<!-- END_TF_DOCS -->
