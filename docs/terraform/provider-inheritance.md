# Provider Inheritance

How providers are configured and inherited across the **cloud-content-hub-infra** repository.

## Principle

> **Providers are configured exclusively at the environment root level. Modules inherit providers automatically and must never declare provider blocks.**

## Architecture

```
environments/dev/          environments/stage/        environments/prod/
├── versions.tf            ├── versions.tf            ├── versions.tf
│   └── required_providers │   └── required_providers │   └── required_providers
├── providers.tf           ├── providers.tf           ├── providers.tf
│   ├── azurerm (+features)│   ├── azurerm (+features)│   ├── azurerm (+features)
│   ├── azapi              │   ├── azapi              │   ├── azapi
│   ├── random             │   ├── random             │   ├── random
│   └── time               │   └── time               │   └── time
└── main.tf                └── main.tf                └── main.tf
    └── module "networking" { ... }  ──inherits──▶  providers from root
            │
            ▼
    modules/networking/
    ├── main.tf         (resources only — no provider block)
    ├── variables.tf
    └── ...             (no providers.tf, no required_providers)
```

## Root-Level Configuration

Each environment directory (`environments/dev`, `stage`, `prod`) owns:

| File | Responsibility |
|------|----------------|
| `versions.tf` | `required_version` and `required_providers` with pinned semver constraints |
| `providers.tf` | Provider instance configuration (features block for azurerm) |
| `backend.tf` | Remote state backend configuration |

### Supported Providers

| Provider | Source | Constraint | Purpose |
|----------|--------|------------|---------|
| `azurerm` | `hashicorp/azurerm` | `~> 5.0` | Primary Azure resource provider |
| `azapi` | `Azure/azapi` | `~> 2.0` | Azure resources not yet in azurerm |
| `random` | `hashicorp/random` | `~> 3.6` | Random values (passwords, suffixes) |
| `time` | `hashicorp/time` | `~> 0.12` | Time-based resources (rotations, delays) |

### AzureRM Features Block

The `azurerm` provider includes a `features` block with safe enterprise defaults:

- Prevent resource group deletion when it still contains resources
- Do not purge Key Vault on destroy; recover soft-deleted vaults
- Do not permanently delete Log Analytics workspaces on destroy
- Do not purge Cognitive Accounts on destroy

### Authentication

Provider blocks do **not** include authentication configuration (`subscription_id`, `tenant_id`, `client_id`, etc.).

Authentication will be handled in a later phase via **GitHub Actions OpenID Connect (OIDC)** for CI/CD and Azure CLI context for local development.

## Module Rules

Modules under `modules/` must follow these rules:

| Rule | Rationale |
|------|-----------|
| No `provider "..." {}` blocks | Prevents conflicting configuration |
| No `required_providers` block | Version constraints belong at the root |
| No `terraform { backend ... }` | State is managed at the environment root |
| Accept implicit provider inheritance | Terraform passes root providers to child modules |

### Calling a Module

```hcl
module "networking" {
  source = "../../modules/networking"

  location    = var.location
  environment = var.environment
  tags        = local.default_tags
}
```

No `providers` meta-argument is required unless explicitly mapping aliased providers in a future phase.

### Aliased Providers (Future)

If aliased providers are needed (e.g., multi-subscription), they will be declared in the environment `providers.tf` and passed explicitly:

```hcl
module "example" {
  source = "../../modules/example"

  providers = {
    azurerm.connectivity = azurerm.connectivity
  }
}
```

This pattern is not used until a documented requirement exists.

## Validation

To verify provider inheritance during development:

```bash
cd environments/dev
terraform init -backend=false
terraform validate
```

Module-level `terraform init` without root context is discouraged — validate modules through the environment root or CI.

## Related

- [Standards — Module Design](standards.md#module-design)
- [Backend Strategy](backend-strategy.md)
