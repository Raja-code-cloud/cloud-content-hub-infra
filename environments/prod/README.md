# Production Environment

Terraform root module for the **prod** environment.

## Configuration

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform `>= 1.13.0` and provider version constraints |
| `backend.tf` | Remote state backend (`prod.tfstate`) — placeholder values |
| `providers.tf` | Provider configuration (azurerm, azapi, random, time) |
| `variables.tf` | Input variables |
| `locals.tf` | Derived values and merged tags |
| `main.tf` | Module composition (future phases) |
| `outputs.tf` | Output values |
| `terraform.tfvars.example` | Example variable values |

## Usage

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform validate
terraform plan -var-file=terraform.tfvars
```

## Approval Requirements

Production deployments require:

- Pull request approval from Platform Engineering
- Successful plan review in CI
- Change management ticket (per organizational policy)

## Documentation

- [Terraform Foundation](../../docs/terraform/README.md)
- [Backend Strategy](../../docs/terraform/backend-strategy.md)
- [Provider Inheritance](../../docs/terraform/provider-inheritance.md)
