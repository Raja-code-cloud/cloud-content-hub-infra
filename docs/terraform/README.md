# Terraform Foundation

Repository-wide Terraform standards for **cloud-content-hub-infra**.

## Documents

| Document | Description |
|----------|-------------|
| [Standards](standards.md) | Variables, outputs, locals, coding conventions, tooling |
| [Shared Foundation](shared-foundation.md) | Naming, tagging, common variables, environment config |
| [Backend Strategy](backend-strategy.md) | Remote state design and per-environment state files |
| [Provider Inheritance](provider-inheritance.md) | Root-level provider configuration and module inheritance |

## Architecture Decision Records

| ADR | Title |
|-----|-------|
| [ADR-0001](../adr/adr-0001-separate-state-files-per-environment.md) | Separate state files per environment |

## Quick Reference

| Concern | Location |
|---------|----------|
| Terraform version | `>= 1.13.0` in `environments/*/versions.tf` |
| Provider configuration | `environments/*/providers.tf` |
| Remote state backend | `environments/*/backend.tf` |
| Environment root module | `environments/{dev,stage,prod}/` |
| Reusable modules | `modules/` (providers inherited — never declared) |

## Environment File Layout

Each environment root module follows this layout:

```
environments/<env>/
├── backend.tf      # Remote state (azurerm) — placeholder values
├── main.tf         # Module composition
├── providers.tf    # Provider configuration (root only)
├── versions.tf     # Terraform and provider version constraints
├── variables.tf    # Input variables
├── outputs.tf      # Output values
├── locals.tf       # Derived values and merged tags
└── terraform.tfvars.example
```

## Toolchain

| Tool | Purpose | Config |
|------|---------|--------|
| `terraform fmt` | Canonical formatting | — |
| `terraform validate` | Configuration validation | — |
| `terraform plan` | Change preview | Per environment |
| `terraform-docs` | Module documentation | `.terraform-docs.yml` |
| `tflint` | Static analysis | `.tflint.hcl` |
| `checkov` | Security and compliance scanning | `.checkov.yml` |

See [Standards — Tooling](standards.md#tooling) for usage commands.
