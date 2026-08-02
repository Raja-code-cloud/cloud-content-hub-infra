# cloud-content-hub-infra

Enterprise Infrastructure as Code for the Cloud Content Hub platform on Microsoft Azure.

This repository is **infrastructure-only**. It does not contain application code, business logic, or runtime services.

## Repository Philosophy

| Principle | Description |
|-----------|-------------|
| **Infrastructure only** | No application code, no business logic, no runtime dependencies |
| **Environment isolation** | Separate root modules and state files per environment |
| **Provider centralization** | Providers configured at the environment root; modules inherit |
| **Module composability** | Single-responsibility modules composed by environment roots |
| **Standards-first** | Conventions documented before implementation |
| **Security by default** | No secrets in source; OIDC authentication in CI/CD |

## Technology Stack

| Component | Technology |
|-----------|------------|
| IaC | Terraform `>= 1.13.0` |
| Cloud Provider | Microsoft Azure |
| CI/CD | GitHub Actions |

## Supported Providers

Configured exclusively in `environments/*/providers.tf`:

| Provider | Source | Version Constraint | Purpose |
|----------|--------|--------------------|---------|
| `azurerm` | `hashicorp/azurerm` | `~> 5.0` | Primary Azure resources |
| `azapi` | `Azure/azapi` | `~> 2.0` | Azure resources not yet in azurerm |
| `random` | `hashicorp/random` | `~> 3.6` | Random values |
| `time` | `hashicorp/time` | `~> 0.12` | Time-based resources |

Authentication is **not** configured in provider blocks. CI/CD will use GitHub Actions OIDC in a later phase.

## Repository Structure

```
.
├── .github/              # GitHub Actions workflows and PR templates
├── docs/
│   ├── terraform/        # Terraform standards and architecture
│   ├── architecture/     # Platform architecture overview
│   ├── runbooks/         # Operational procedures
│   └── adr/              # Architecture Decision Records
├── deployment/           # Enterprise deployment framework (HOW to deploy)
│   ├── bootstrap/        # Init, backend, state migration
│   ├── deploy/           # Plan, apply, approval gates
│   ├── rollback/         # Rollback strategy
│   ├── destroy/          # Safe teardown
│   ├── validate/         # Quality and security gates
│   ├── state/            # State locking, recovery, drift
│   ├── versioning/       # Version policy
│   ├── release/          # Promotion and tagging (see also release/)
│   └── scripts/          # Orchestration scripts
├── release/              # Release and promotion framework (Dev → Stage → Prod)
│   ├── docs/             # Lifecycle, artifacts, audit, change management
│   ├── runbooks/         # Promotion, rollback, drift recovery
│   ├── scripts/          # promote, rollback, drift, quality gates
│   ├── checklists/       # Pre-promotion checklists
│   └── templates/        # Audit records, release notes, change requests
├── modules/              # Reusable Terraform modules
├── scripts/              # Operational scripts
├── examples/             # Reference implementations
├── policies/             # Azure Policy definitions
└── templates/            # Scaffolding templates
```

## Backend Strategy

| Property | Value |
|----------|-------|
| Backend type | `azurerm` (Azure Storage) |
| State granularity | One state file per environment |
| Workspaces | Not used |

| Environment | State Key |
|-------------|-----------|
| dev | `dev.tfstate` |
| stage | `stage.tfstate` |
| prod | `prod.tfstate` |

Separate state files (instead of Terraform workspaces) provide blast-radius isolation, independent RBAC, and unambiguous CI/CD targeting. See [Backend Strategy](docs/terraform/backend-strategy.md) and [ADR-0001](docs/adr/adr-0001-separate-state-files-per-environment.md).

## Module Philosophy

- Each module owns **one Azure service domain** (single responsibility).
- Modules **never** declare providers, backends, or `required_providers`.
- Modules receive configuration via **variables** and expose results via **outputs**.
- Environment root modules **compose** modules — they do not duplicate module logic.
- Shared naming, tagging, and derived values live in **`modules/common`** — never duplicated.

See [Shared Foundation](docs/terraform/shared-foundation.md), [Provider Inheritance](docs/terraform/provider-inheritance.md), and [Module Design](docs/terraform/standards.md#module-design).

## Environment Philosophy

Each environment is an independent Terraform root module:

```
environments/<env>/
├── backend.tf          # Remote state (placeholder values)
├── providers.tf        # Provider configuration
├── versions.tf         # Version constraints
├── variables.tf        # Input variables
├── locals.tf           # Derived values and merged tags
├── main.tf             # Module composition
├── outputs.tf          # Output values
└── terraform.tfvars.example
```

Environment-specific values are supplied via `terraform.tfvars` (never committed) or CI-injected variables. No environment values are hardcoded in source.

## Coding Standards

| Area | Standard |
|------|----------|
| Formatting | `terraform fmt -recursive` |
| Validation | `terraform validate` per environment |
| Static analysis | `tflint --recursive` |
| Security scanning | `checkov -d environments/ -d modules/` |
| Documentation | `terraform-docs` per module |
| Naming | `snake_case` for all Terraform identifiers |
| Variables | `description`, `type`, `nullable` required; validation when appropriate |
| Outputs | `description` required; `sensitive = true` for secrets |
| Locals | Naming, derived values, merged tags only |

Full reference: [Terraform Standards](docs/terraform/standards.md)

## Modules

| Module | Description |
|--------|-------------|
| `common` | Shared naming, tagging, and metadata foundation |
| `naming` | Deterministic Azure resource naming conventions |
| `resource-group` | Azure Resource Group (platform foundation) |
| `networking` | Virtual networks, subnets, and connectivity |
| `managed-identity` | User-assigned managed identity (platform authentication) |
| `key-vault` | Azure Key Vault (secrets and key management) |
| `storage` | Azure Storage Account (platform storage foundation) |
| `acr` | Azure Container Registry (container image registry) |
| `container-app-environment` | Azure Container Apps environment |
| `container-app` | Azure Container Apps |
| `postgresql-flexible-server` | Azure Database for PostgreSQL Flexible Server |
| `postgres` | _(placeholder — use `postgresql-flexible-server`)_ |
| `redis` | Azure Cache for Redis |
| `log-analytics` | Log Analytics Workspace (centralized logging platform) |
| `application-insights` | Application Insights |
| `role-assignment` | Azure RBAC role assignments |
| `key-vault-secrets` | Key Vault secret management |
| `diagnostic-settings` | Azure Monitor diagnostic settings |
| `action-group` | Azure Monitor action groups |
| `monitor-alerts` | Azure Monitor metric alert rules |
| `monitor` | _(placeholder — use `diagnostic-settings`, `action-group`, `monitor-alerts`)_ |
| `alerts` | _(placeholder — superseded by `action-group` and `monitor-alerts`)_ |
| `budget` | Cost management and budgets |

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.13.0`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [TFLint](https://github.com/terraform-linters/tflint)
- [terraform-docs](https://terraform-docs.io/)
- [Checkov](https://www.checkov.io/) (optional, for local security scanning)

### Deployment Framework

The [deployment framework](deployment/README.md) defines **how** infrastructure is deployed:

```bash
# Bootstrap (one-time)
./deployment/scripts/bootstrap/init-backend.sh dev

# Validate → Plan → Apply
./deployment/scripts/validate/run-all.sh dev
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

Scripts require Bash (Git Bash or WSL on Windows). See [deployment/README.md](deployment/README.md) and [runbooks](docs/runbooks/README.md).

### Local Development

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # edit with your values
terraform init -backend=false                   # skip backend until bootstrapped
terraform validate
terraform plan -var-file=terraform.tfvars
```

### Validation Pipeline (Local)

```bash
terraform fmt -recursive -check -diff
tflint --init && tflint --recursive

# Per environment
cd environments/dev && terraform init -backend=false && terraform validate
```

## CI/CD

Production-grade GitHub Actions workflows enforce quality gates on every pull request and support manual deployment operations.

Full documentation: **[CI/CD Architecture](docs/cicd/README.md)**

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `terraform-pr.yml` | Pull request | Orchestrates all PR checks (format, validate, lint, docs, security, plan) |
| `terraform-format.yml` | Push, manual | `terraform fmt -check -recursive` |
| `terraform-validate.yml` | Push, manual | `terraform init` + `validate` for all environments and modules |
| `terraform-lint.yml` | Push, manual | TFLint static analysis |
| `terraform-docs.yml` | Push, manual | Verify module documentation is current |
| `terraform-security.yml` | Push, manual | Checkov, tfsec, Trivy (fail on HIGH/CRITICAL) |
| `terraform-plan.yml` | Manual, reusable | Generate and upload plan artifacts |
| `terraform-apply.yml` | Manual only | Apply with approval gate *(disabled until OIDC)* |
| `terraform-destroy.yml` | Manual only | Destroy non-prod with confirmation *(disabled until OIDC)* |
| `release.yml` | Tag `v*.*.*` | Validate, scan, plan, publish release |

### Reusable Components

- **Composite actions:** `.github/actions/setup-terraform`, `.github/actions/setup-tflint`
- **Reusable workflows:** All workflows support `workflow_call` for composition without duplication

### Authentication

Workflows include OIDC-compatible `permissions` blocks. Azure authentication via **GitHub Actions OIDC** will be configured in a later phase. Apply and destroy steps are intentionally disabled until then.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branching strategy, pull request requirements, and contribution expectations.

Key expectations:

- Follow [Terraform Standards](docs/terraform/standards.md) for all changes
- Never commit secrets, credentials, or real backend values
- Never add provider blocks to modules
- Update documentation and ADRs for significant design decisions
- Run the local validation pipeline before opening a pull request

## License

See [LICENSE](LICENSE).
