# Azure Container App Module

Creates exactly **one** generic Azure Container App. Application-agnostic — no Cloud Content Hub or workload-specific logic.

## Purpose

- Deploy any containerized application on Azure Container Apps
- Support scale-to-zero, managed identity, ACR pull, ingress, autoscaling, health probes, secrets, and optional Dapr
- Compose with upstream platform modules (environment, identity, registry, Application Insights, Key Vault)
- Enforce consistent tagging via the shared foundation

This module does **not** create DNS records, certificates, custom domains, RBAC, diagnostic settings, or private endpoints.

## Architecture

```
environments/<env>/
    module "common"                    ──▶ tags, names, location
    module "resource_group"            ──▶ resource group scope
    module "log_analytics"             ──▶ platform logging
    module "container_app_environment" ──▶ hosting environment
    module "managed_identity"          ──▶ ACR pull / Key Vault access
    module "acr"                       ──▶ container images
    module "application_insights"      ──▶ telemetry (optional)
    module "key_vault"                 ──▶ secrets (optional)
    module "container_app"             ──▶ azurerm_container_app
            │
            ▼
    Future modules (separate implementations)
    ├── role assignment               (AcrPull, Key Vault Secrets User)
    ├── custom domain / certificate
    ├── private endpoint
    └── diagnostic settings
```

## Features

| Area | Support |
|------|---------|
| Containers | Multiple containers, init containers, env vars, secret env vars, commands/args |
| Registry | Multiple registries, managed identity auth (no admin credentials) |
| Identity | System-assigned, user-assigned, multiple user-assigned identities |
| Ingress | External/internal, HTTP/HTTP2/TCP, CORS, IP restrictions, traffic splitting |
| Scaling | Scale-to-zero, min/max replicas, HTTP/TCP/custom KEDA rules, Azure Queue rules |
| Probes | Startup, readiness, liveness — fully configurable |
| Secrets | Inline values and Key Vault references |
| Dapr | Optional sidecar (disabled by default) |
| Observability | Application Insights connection string via env (optional) |
| Revisions | Single or Multiple mode with traffic weights |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13.0 |
| azurerm | ~> 4.0 |

Providers are inherited from the environment root module.

## Inputs

### Core

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `container_app_name` | App name (from caller) | `string` | — | yes |
| `resource_group_name` | Target resource group | `string` | — | yes |
| `container_app_environment_id` | Container Apps Environment ID | `string` | — | yes |
| `revision_mode` | `Single` or `Multiple` | `string` | `Single` | no |
| `workload_profile_name` | Dedicated workload profile name | `string` | `null` | no |
| `max_inactive_revisions` | Max inactive revisions retained | `number` | `null` | no |
| `tags` | Merged tags from shared foundation | `map(string)` | — | yes |

### Container (`containers`)

| Field | Description |
|-------|-------------|
| `name` | Container name |
| `image` | Image repository or full image reference |
| `image_tag` | Image tag when `image` has no tag (default `latest`) |
| `cpu` | vCPU allocation (0–4) |
| `memory` | Memory in Gi (e.g. `0.5Gi`, `1.0Gi`) |
| `command` / `startup_command` | Override container entrypoint |
| `args` | Container arguments |
| `env` | Environment variables (`value` or `secret_name`) |
| `liveness_probe` / `readiness_probe` / `startup_probe` | Health probe configuration |
| `volume_mounts` | Volume mount definitions |

### Scaling (`scale`)

| Field | Default | Description |
|-------|---------|-------------|
| `min_replicas` | `0` | Minimum replicas (0 = scale-to-zero) |
| `max_replicas` | `10` | Maximum replicas |
| `http_rules` | `[]` | HTTP concurrent request scaling |
| `custom_rules` | `[]` | Custom KEDA scalers |
| `tcp_rules` | `[]` | TCP concurrent connection scaling |
| `azure_queue_rules` | `[]` | Azure Queue depth scaling |

### Ingress (`ingress`)

Set to `null` for background workers without HTTP ingress.

| Field | Default | Description |
|-------|---------|-------------|
| `enabled` | `true` | Enable ingress block |
| `external_enabled` | `true` | `false` for internal-only |
| `target_port` | — | Container port |
| `transport` | `auto` | `auto`, `http`, `http2`, `tcp` |
| `allow_insecure_connections` | `false` | Allow HTTP |
| `traffic_weights` | `[100% latest]` | Revision traffic split (Multiple mode) |

### Identity, Registry, Secrets, Dapr

| Variable | Description |
|----------|-------------|
| `identity` | `{ type, identity_ids }` — null for no identity |
| `registries` | List of registry auth configs (identity or username/secret) |
| `secrets` | Inline or Key Vault secret references (sensitive) |
| `dapr` | Optional Dapr sidecar (disabled by default) |
| `observability` | Optional Application Insights connection string wiring |
| `lifecycle_options` | Lifecycle flags (secrets ignored for Key Vault drift) |

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | no | Container App resource ID |
| `name` | no | Container App name |
| `fqdn` | no | Latest revision FQDN |
| `latest_revision` | no | Latest revision FQDN |
| `latest_revision_name` | no | Latest revision name |
| `principal_id` | no | System-assigned identity principal ID |
| `identity_id` | no | First user-assigned identity resource ID |
| `identity_ids` | no | All user-assigned identity resource IDs |
| `ingress_url` | no | HTTPS ingress URL when FQDN available |
| `resource_id` | no | Azure Resource Manager ID |
| `environment_id` | no | Container Apps Environment ID |
| `location` | no | Deployment region |
| `outbound_ip_addresses` | no | Outbound public IPs |
| `container_app` | no | Metadata object for downstream modules |

No secret values are exposed in outputs.

## Examples

### Simple Web API

```hcl
module "container_app" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["api"]
  resource_group_name        = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  containers = [{
    name      = "api"
    image     = module.acr.login_server
    image_tag = var.api_image_tag
    cpu       = 0.5
    memory    = "1.0Gi"
    env = [{
      name  = "ASPNETCORE_ENVIRONMENT"
      value = var.environment
    }]
    readiness_probe = {
      transport = "HTTP"
      port      = 8080
      path      = "/health"
    }
  }]

  scale = {
    min_replicas = 0
    max_replicas = 5
    http_rules = [{
      name                = "http-scaling"
      concurrent_requests = 50
    }]
  }

  ingress = {
    external_enabled = true
    target_port      = 8080
    transport        = "http"
  }

  observability = {
    application_insights_connection_string = module.application_insights.connection_string
  }
}
```

### Background Worker (No Ingress)

```hcl
module "container_app_worker" {
  source = "../../modules/container-app"

  container_app_name           = "${module.common.resource_names["api"]}-worker"
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  ingress = null

  containers = [{
    name      = "worker"
    image     = "${module.acr.login_server}/worker"
    image_tag = var.worker_image_tag
    cpu       = 0.25
    memory    = "0.5Gi"
    command   = ["python", "worker.py"]
  }]

  scale = {
    min_replicas = 0
    max_replicas = 3
    custom_rules = [{
      name             = "queue-scaler"
      custom_rule_type = "azure-queue"
      metadata = {
        queueName  = var.queue_name
        accountName = module.storage.name
      }
      authentication = [{
        secret_name       = "storage-connection"
        trigger_parameter = "connection"
      }]
    }]
  }

  secrets = [{
    name  = "storage-connection"
    value = var.storage_connection_string
  }]
}
```

### Internal Service

```hcl
module "container_app_internal" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["api"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  containers = [{
    name      = "internal-api"
    image     = "${module.acr.login_server}/internal-api"
    image_tag = var.internal_api_image_tag
    cpu       = 0.5
    memory    = "1.0Gi"
  }]

  ingress = {
    external_enabled = false
    target_port      = 8080
    transport        = "http"
  }

  scale = {
    min_replicas = 1
    max_replicas = 5
  }
}
```

### Public API with Key Vault Secrets

```hcl
module "container_app" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["api"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  identity = {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [module.managed_identity.resource_id]
  }

  registries = [{
    server   = module.acr.login_server
    identity = module.managed_identity.resource_id
  }]

  secrets = [{
    name                = "database-url"
    key_vault_secret_id = var.database_url_key_vault_secret_id
    identity            = module.managed_identity.resource_id
  }]

  containers = [{
    name      = "api"
    image     = "${module.acr.login_server}/api"
    image_tag = var.api_image_tag
    cpu       = 1.0
    memory    = "2.0Gi"
    env = [{
      name        = "DATABASE_URL"
      secret_name = "database-url"
    }]
    liveness_probe = {
      transport = "HTTP"
      port      = 8080
      path      = "/healthz"
    }
  }]

  ingress = {
    external_enabled = true
    target_port      = 8080
  }
}
```

### Scale-to-Zero API

```hcl
module "container_app" {
  source = "../../modules/container-app"

  container_app_name           = module.common.resource_names["api"]
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  tags                         = module.common.tags

  containers = [{
    name      = "api"
    image     = "mcr.microsoft.com/azuredocs/containerapps-helloworld"
    image_tag = "latest"
    cpu       = 0.25
    memory    = "0.5Gi"
  }]

  scale = {
    min_replicas = 0
    max_replicas = 3
    http_rules = [{
      name                = "scale-on-requests"
      concurrent_requests = 10
    }]
  }

  ingress = {
    external_enabled = true
    target_port      = 80
  }
}
```

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `modules/common` | Tags, names, location |
| `modules/resource-group` | Resource group scope |
| `modules/container-app-environment` | Hosting environment ID |
| `modules/managed-identity` | ACR pull and Key Vault access |
| `modules/acr` | Container image registry |
| `modules/application-insights` | Telemetry connection string (optional) |
| `modules/key-vault` | Secret references (optional) |
| Role assignment modules (future) | `AcrPull`, `Key Vault Secrets User` |

## Security Considerations

- **No admin credentials** — Use managed identity for ACR (`registries[].identity`).
- **Key Vault references** — Prefer `key_vault_secret_id` over inline secret values.
- **No secrets in outputs** — Secret values never appear in Terraform outputs or state diffs via outputs.
- **Internal ingress** — Set `ingress.external_enabled = false` for east-west traffic within the environment.
- **RBAC** — Assign `AcrPull` and Key Vault roles via separate modules before deployment.
- **Identity** — Use `SystemAssigned`, `UserAssigned`, or both depending on registry and Key Vault requirements.

## Networking

- **External ingress** — Public HTTPS endpoint via environment default domain.
- **Internal ingress** — Accessible only within the Container Apps Environment.
- **TCP ingress** — Set `transport = "tcp"` and configure `exposed_port`.
- **Egress** — Outbound IPs exposed via `outbound_ip_addresses` output.
- **VNet integration** — Configure at the environment level; apps inherit environment networking.

## Revisions

| Mode | Use Case |
|------|----------|
| `Single` (default) | One active revision; simplest operations |
| `Multiple` | Blue/green and canary deployments with `traffic_weights` |

Traffic weight percentages must sum to **100** when `revision_mode = Multiple`.

## Health Probes

Each probe supports `transport` (`HTTP`, `HTTPS`, `TCP`), `port`, `path`, timing thresholds, and custom headers. Configure per container:

- **Startup** — Delay liveness/readiness until initialization completes
- **Readiness** — Remove unhealthy instances from load balancing
- **Liveness** — Restart containers that fail health checks

## Scaling

Default `min_replicas = 0` enables scale-to-zero for cost efficiency. Add `http_rules`, `custom_rules`, `tcp_rules`, or `azure_queue_rules` for event-driven scaling.

Dedicated workload profiles are selected via `workload_profile_name` when the environment supports them.

## Best Practices

- Pass `module.common.tags` for every deployment.
- Assign `AcrPull` to the managed identity before first deploy.
- Use Key Vault secret references for production credentials.
- Set readiness probes for all HTTP services.
- Use `revision_mode = Multiple` for zero-downtime image promotions.
- Wire Application Insights via `observability` or explicit `env` entries.

## Cost Considerations

| Factor | Impact |
|--------|--------|
| `min_replicas = 0` | No compute cost when idle (scale-to-zero) |
| CPU / memory | Billed per vCPU-second and GiB-second when running |
| HTTP scaling | Scales on concurrent requests — tune threshold to avoid over-scaling |
| Dedicated profiles | Environment-level dedicated nodes billed separately |
| Log Analytics | Container logs ingest via linked workspace |

## Operational Guidance

- Secret values are ignored in lifecycle after creation to support Key Vault reference rotation without Terraform drift.
- For image-only CI/CD updates with `revision_mode = Single`, use `terraform apply` with updated `image_tag` or switch to `Multiple` with `revision_suffix`.
- `latest_revision_fqdn` and `ingress_url` are available after first successful revision.
- Dapr requires `dapr.app_id` and typically `dapr.app_port` matching ingress `target_port`.
- Destroying a Container App removes all revisions; coordinate with downstream DNS modules.

## Lifecycle and Image Updates

Terraform requires static `lifecycle` blocks. This module always ignores `secret` value changes (recommended for Key Vault references). For image tag promotions without full Terraform replacement:

1. Use `revision_mode = Multiple` with `scale.revision_suffix`
2. Shift traffic via `ingress.traffic_weights`
3. Or update images through your CI/CD pipeline targeting Azure APIs directly

## Related

- [Container Apps Environment Module](../container-app-environment/README.md)
- [Managed Identity Module](../managed-identity/README.md)
- [ACR Module](../acr/README.md)
- [Application Insights Module](../application-insights/README.md)
- [Shared Foundation](../../docs/terraform/shared-foundation.md)

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
