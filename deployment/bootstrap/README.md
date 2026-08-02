# Bootstrap

First-time setup and re-initialization procedures for Terraform environments.

Bootstrap prepares the deployment toolchain and remote state backend. It does **not** deploy application infrastructure — that happens in the [deploy](../deploy/README.md) phase.

## Overview

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `select-environment.sh` | Validate and export environment context |
| 2 | `init-terraform.sh` | Download providers and modules |
| 3 | `init-backend.sh` | Configure azurerm remote state backend |
| 4 | `migrate-state.sh` | Migrate local state to remote (if needed) |
| 5 | `validate-providers.sh` | Confirm provider versions and features |

## Prerequisites

Before bootstrap:

1. **Azure subscription** assigned to the target environment
2. **State storage account** provisioned (one-time platform bootstrap — outside this repo)
3. **`backend.hcl`** created from `backend.hcl.example` with real values
4. **`terraform.tfvars`** created from `terraform.tfvars.example` with real values
5. **Azure authentication** configured (`az login` or service principal env vars)
6. **RBAC** — deploying identity needs:
   - Contributor (or scoped custom role) on target subscription/resource group
   - `Storage Blob Data Contributor` on state storage account
   - `Key Vault Secrets Officer` on Key Vault (for secret provisioning)

## Environment Selection

Every bootstrap script accepts the environment as the first argument:

```bash
./deployment/scripts/bootstrap/select-environment.sh dev
```

Valid values: `dev`, `stage`, `prod`.

Alternatively set `TF_ENV`:

```bash
export TF_ENV=stage
./deployment/scripts/bootstrap/init-backend.sh
```

## Terraform Initialization

### Validate-only (no remote backend)

Use during CI or local composition checks:

```bash
./deployment/scripts/bootstrap/init-terraform.sh dev --skip-backend
```

Equivalent to:

```bash
cd environments/dev
terraform init -backend=false -input=false
```

### Full initialization (with remote backend)

```bash
./deployment/scripts/bootstrap/init-backend.sh dev
```

Requires `environments/dev/backend.hcl` to exist.

## Backend Initialization

Backend configuration uses **partial config** in `backend.tf` with values supplied via `backend.hcl`:

```hcl
# environments/dev/backend.hcl
resource_group_name  = "rg-platform-tfstate"
storage_account_name = "stplatformtfstate"
container_name       = "tfstate"
key                  = "dev.tfstate"
```

### First-time init

```bash
cp environments/dev/backend.hcl.example environments/dev/backend.hcl
# Edit backend.hcl with real values
./deployment/scripts/bootstrap/init-backend.sh dev
```

### Reconfigure backend (changed storage account)

```bash
./deployment/scripts/bootstrap/init-backend.sh dev --reconfigure
```

## State Migration

When moving from local state to remote backend:

```bash
# 1. Ensure backend.hcl is configured
# 2. Migrate existing local state
./deployment/scripts/bootstrap/migrate-state.sh dev
```

This runs `terraform init -migrate-state -backend-config=backend.hcl`.

### Migration checklist

- [ ] Backup existing `terraform.tfstate` locally
- [ ] Verify backend storage account is accessible
- [ ] Confirm state key matches environment (`dev.tfstate`, `stage.tfstate`, `prod.tfstate`)
- [ ] Run `terraform state list` after migration to verify resources
- [ ] Delete local state file only after successful verification

See [state/README.md](../state/README.md) for recovery procedures.

## Provider Validation

After init, validate provider configuration:

```bash
./deployment/scripts/bootstrap/validate-providers.sh dev
```

This runs:

1. `terraform validate`
2. `terraform providers` — version audit
3. Provider feature block verification (azurerm `features {}`)

Expected provider versions (from `versions.tf`):

| Provider | Constraint |
|----------|------------|
| `azurerm` | `~> 5.0` |
| `azapi` | `~> 2.0` |
| `random` | `~> 3.6` |
| `time` | `~> 0.12` |

## Per-Environment Bootstrap

| Environment | State Key | Backend Config | Notes |
|-------------|-----------|----------------|-------|
| dev | `dev.tfstate` | `environments/dev/backend.hcl` | Fastest iteration; optional approvals |
| stage | `stage.tfstate` | `environments/stage/backend.hcl` | Pre-production validation |
| prod | `prod.tfstate` | `environments/prod/backend.hcl` | Requires change advisory; 2+ approvers |

## Bootstrap Sequence Diagram

```
Operator                    Bootstrap Scripts              Azure
   │                              │                        │
   │── select-environment ───────▶│                        │
   │── copy backend.hcl ─────────▶│                        │
   │── init-backend.sh ──────────▶│── terraform init ─────▶│ (state blob)
   │                              │◀── backend configured ─│
   │── validate-providers.sh ────▶│── terraform validate     │
   │◀── ready for deploy ─────────│                        │
```

## Troubleshooting

| Error | Cause | Resolution |
|-------|-------|------------|
| Backend config not found | Missing `backend.hcl` | Copy from `backend.hcl.example` |
| Storage account not found | Wrong backend values | Verify bootstrap storage provisioning |
| Provider version conflict | Lock file out of date | Run `terraform init -upgrade` |
| Access denied on state blob | Missing RBAC | Grant `Storage Blob Data Contributor` |
| Backend init required for plan | TF 1.13 + azurerm backend | Use full backend init, not `-backend=false` |

## Related

- [Backend Strategy](../../docs/terraform/backend-strategy.md)
- [State Management](../state/README.md)
- [New Environment Runbook](../../docs/runbooks/new-environment.md)
