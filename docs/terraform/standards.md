# Terraform Standards

Coding, naming, and tooling standards for **cloud-content-hub-infra**.

## Variables

Every variable must include:

| Attribute | Required | Notes |
|-----------|----------|-------|
| `description` | Yes | Clear, complete sentence explaining purpose |
| `type` | Yes | Explicit type — never rely on inference |
| `nullable` | Yes | Explicitly `true` or `false` |
| `default` | When appropriate | Only for environment-agnostic safe defaults |
| `sensitive` | When appropriate | `true` for secrets and credentials |
| `validation` | When appropriate | Guard invalid input at plan time |

### Rules

- **No hardcoded environment values** in module or root source — use `terraform.tfvars` or CI-injected values.
- Prefer specific types over `any` (`string`, `number`, `bool`, `list(...)`, `map(...)`, `object({...})`).
- Use `validation` blocks for enums, regex patterns, and cross-field constraints.
- Group related variables in `variables.tf`; split into `variables-<domain>.tf` only when a file exceeds ~200 lines.

### Example

```hcl
variable "environment" {
  description = "Deployment environment identifier."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "location" {
  description = "Primary Azure region for resource deployment."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Additional tags merged with default tags in locals."
  type        = map(string)
  nullable    = false
  default     = {}
}
```

## Outputs

Every output must include:

| Attribute | Required | Notes |
|-----------|----------|-------|
| `description` | Yes | Explain what the value represents and its consumer |
| `value` | Yes | The output expression |
| `sensitive` | When appropriate | `true` for secrets, keys, connection strings |

### Rules

- **Never expose secrets** in outputs unless marked `sensitive = true` and consumed securely.
- Export only values required by other modules, environments, or CI pipelines.
- Do not output entire resource objects — export specific attributes.
- Prefix outputs with the resource domain when ambiguous (`key_vault_id`, not `id`).

### Example

```hcl
output "resource_group_name" {
  description = "Name of the platform resource group."
  value       = azurerm_resource_group.platform.name
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string. Treat as confidential."
  value       = module.postgres.connection_string
  sensitive   = true
}
```

## Locals

Use `locals` only for:

| Use Case | Example |
|----------|---------|
| Naming | `local.resource_prefix = "${var.project}-${var.environment}"` |
| Derived values | `local.subnet_cidrs = cidrsubnets(var.vnet_cidr, 4, 4, 4)` |
| Reusable expressions | `local.diagnostic_settings = { ... }` |
| Merged tags | `local.default_tags = merge(local.base_tags, var.tags)` |

### Rules

- Do not duplicate expressions — compute once in `locals` and reference everywhere.
- Do not use locals to bypass variable validation.
- Keep locals focused; split into `locals-<domain>.tf` when files grow large.

### Example

```hcl
locals {
  base_tags = {
    environment = var.environment
    managed_by  = "terraform"
    project     = "cloud-content-hub"
  }

  default_tags = merge(local.base_tags, var.tags)
}
```

## Coding Standards

### Resource Naming

| Rule | Convention |
|------|------------|
| Terraform resource name | `snake_case`, descriptive (`azurerm_key_vault.platform`) |
| Azure resource name | Generated via the `naming` module when implemented |
| Address prefix | Match resource type domain (`kv_`, `vnet_`, `aca_`) |

### Variable Naming

- `snake_case` throughout.
- Prefix with domain when ambiguous (`kv_sku_name`, `postgres_sku_name`).
- Boolean variables use affirmative phrasing (`enable_monitoring`, not `disable_monitoring`).

### Output Naming

- `snake_case`, noun-first (`resource_group_id`, `container_app_fqdn`).
- Mirror the attribute being exported where practical.

### File Ordering

Within each module and environment, maintain this file order:

1. `versions.tf` — Terraform and provider version constraints
2. `backend.tf` — Remote state (environments only)
3. `providers.tf` — Provider configuration (environments only)
4. `variables.tf` — Input variables
5. `locals.tf` — Local values
6. `main.tf` — Resources and module calls
7. `outputs.tf` — Output values

Additional domain-specific files (`variables-networking.tf`, `main-postgres.tf`) are inserted after their base file.

### Comments

- Use block headers for file purpose (see existing environment files).
- Comment **why**, not **what** — the code should explain what.
- Do not leave commented-out resources in merged code.

### Documentation

- Every module must have a `README.md` with usage example and input/output tables.
- Run `terraform-docs` to keep README tables current (see `.terraform-docs.yml`).
- Significant design decisions require an ADR in `docs/adr/`.

### Readability

- One logical resource or module call per block where possible.
- Limit line length to ~120 characters.
- Use `terraform fmt` — never argue about formatting.

## Module Design

| Principle | Description |
|-----------|-------------|
| Single responsibility | Each module owns one Azure service domain |
| No provider configuration | Providers inherited from environment root |
| No backend configuration | State managed at environment root |
| No duplicated logic | Shared logic goes in `locals` or a shared module |
| Explicit inputs | All configuration via variables — no hidden magic |
| Minimal outputs | Export only what consumers need |
| Composable | Modules should work independently and together |

## Tooling

These commands form the local validation pipeline and will be enforced in GitHub Actions.

### terraform fmt

Format all Terraform files to canonical style.

```bash
# Check formatting (CI mode)
terraform fmt -recursive -check -diff

# Apply formatting (local development)
terraform fmt -recursive
```

### terraform validate

Validate configuration syntax and internal consistency.

```bash
cd environments/dev
terraform init -backend=false
terraform validate
```

### terraform plan

Preview changes against the target environment.

```bash
cd environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
```

Never run `plan` against prod without change-management approval.

### terraform-docs

Generate module documentation from Terraform metadata.

```bash
terraform-docs markdown table --config .terraform-docs.yml modules/<module-name>
```

Configuration: `.terraform-docs.yml`

### tflint

Static analysis for Terraform best practices and Azure-specific rules.

```bash
tflint --init
tflint --recursive
```

Configuration: `.tflint.hcl`

### checkov

Security and compliance scanning for Terraform.

```bash
checkov -d environments/
checkov -d modules/
```

Configuration: `.checkov.yml`

## Related

- [Provider Inheritance](provider-inheritance.md)
- [Backend Strategy](backend-strategy.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
