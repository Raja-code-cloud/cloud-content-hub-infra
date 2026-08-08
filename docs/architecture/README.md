# Architecture Overview

This document describes the high-level infrastructure architecture for the Cloud Content Hub platform on Azure.

## Design Principles

1. **Separation of concerns** — Infrastructure is managed independently from application repositories.
2. **Modularity** — Reusable Terraform modules encapsulate resource patterns.
3. **Tiered environment composition** — dev uses a minimal stack; stage and prod share an expanded composition with environment-specific parameters.
4. **Security by default** — Private endpoints, managed identities, and Key Vault for secrets in stage/prod.
5. **Observability** — Centralized logging, monitoring, and alerting in stage/prod.

## Environment Composition

| Capability | dev | stage | prod |
|------------|:---:|:-----:|:----:|
| Core platform (RG, LA, App Insights, MI, ACR, KV, Storage, PostgreSQL) | Yes | Yes | Yes |
| Azure Cache for Redis | Yes | Yes | Yes |
| PostgreSQL database module | Yes | Yes | Yes |
| API / worker / beat Container Apps | Yes | Yes | Yes |
| Migration Container Apps Job | Yes | Yes | Yes |
| Private networking / VNet | No | Yes | Yes |
| Private endpoints (incl. Redis when enabled) | No | Yes | Yes |
| Governance (policy, budget) | No | Yes | Yes |
| Monitoring (action groups, alerts) | No | Yes | Yes |
| Diagnostic settings | No | Yes | Yes |
| Resource lock | No | Yes | Yes |
| Custom policy initiative | No | No | Yes |

## Reference Architecture (stage / prod)

```
+------------------------------------------------------------------+
|                     Azure Subscription                            |
|  +------------------------------------------------------------+  |
|  |                    Resource Group                           |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  | Networking  |  |  Key Vault  |  | Managed Identity   |  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  |     ACR     |  | Container   |  |  Container Apps    |  |  |
|  |  |             |  | App Env     |  |                    |  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  | PostgreSQL  |  |   Storage   |  | Private Endpoints  |  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  |   Redis     |  | Worker/Beat |  | Migration Job      |  |  |
|  |  +-------------+  +-------------+  +--------------------+  |  |
|  |  +------------------------------------------------------+  |  |
|  |  | Log Analytics | App Insights | Monitor Alerts       |  |  |
|  |  +------------------------------------------------------+  |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

## Module Dependency Order

When composing resources, wire modules in this order:

1. `naming` (via `common`)
2. `common` — shared foundation
3. `resource-group`
4. `networking` → `private-dns` (when private networking enabled)
5. `log-analytics` → `application-insights`
6. `managed-identity`, `acr`, `key-vault`, `storage` → `storage-containers`
7. `postgresql-flexible-server` → `postgresql-database`, `postgresql-configuration`
8. `redis`
9. `container-app-environment` → `private-endpoint` (when enabled)
10. `role-assignment` → `key-vault-secrets` (includes `CCH-DATABASE-URL`, `CCH-REDIS-URL`, `CCH-MIGRATION-DATABASE-URL`)
11. `policy-initiative` → `policy-assignment`, `budget` (when governance enabled)
12. `action-group`, `monitor-alerts`, `diagnostic-settings` (when monitoring enabled)
13. `container-app` (API) → `container-app` (worker/beat) → `container-app-job` (migrate)

### Deprecated modules (do not use)

| Module | Replacement |
|--------|-------------|
| `postgres` | `postgresql-flexible-server` |
| `monitor` | `diagnostic-settings`, `action-group`, `monitor-alerts` |
| `alerts` | `action-group`, `monitor-alerts` |

## Environment Strategy

| Environment | Purpose | Subscription |
|-------------|---------|--------------|
| dev | Development and experimentation | Non-production |
| stage | Pre-production validation (mirrors prod networking) | Non-production |
| prod | Production workloads | Production (isolated) |

## State Management

- One remote state file per environment (`dev.tfstate`, `stage.tfstate`, `prod.tfstate`)
- Backend: Azure Storage with blob locking
- Bootstrap: `deployment/scripts/bootstrap/provision-state-storage.sh`

See [Backend Strategy](../terraform/backend-strategy.md) and [ADR-0001](../adr/adr-0001-separate-state-files-per-environment.md).

## Related Documents

- [Terraform Foundation](../terraform/README.md)
- [Audit Remediation](../terraform/AUDIT_REMEDIATION.md)
- [Runbooks](../runbooks/README.md)
- [Architecture Decision Records](../adr/README.md)
