# Deployment Framework

Enterprise deployment framework for **cloud-content-hub-infra**.

This framework defines **how** infrastructure is deployed — not **what** infrastructure exists. Terraform modules and environment compositions are unchanged; this layer orchestrates bootstrap, validation, deployment, rollback, and destruction.

## Philosophy

| Principle | Description |
|-----------|-------------|
| **Process over resources** | Scripts and runbooks orchestrate Terraform; they do not create Azure resources directly |
| **Environment isolation** | One state file, one directory, one approval gate per environment |
| **Fail closed** | Validation gates block deploy; production requires multiple confirmations |
| **Auditability** | Every operation produces logs and artifacts |
| **CI/CD parity** | Local scripts mirror GitHub Actions workflows |

## Directory Structure

```
deployment/
├── README.md                 # This file — framework overview
├── bootstrap/                # First-time and backend initialization
├── deploy/                   # Plan, apply, and environment-specific procedures
├── rollback/                 # Failed deployment and state recovery
├── destroy/                  # Safe teardown procedures
├── validate/                 # Quality and security gate documentation
├── state/                    # State locking, migration, drift, import
├── versioning/               # Terraform, provider, and module version policy
├── release/                  # Promotion, tagging, hotfix strategy
└── scripts/                  # Executable orchestration scripts
    ├── lib/common.sh         # Shared functions
    ├── bootstrap/            # Init and backend scripts
    ├── deploy/               # Plan and apply scripts
    ├── rollback/             # Rollback helpers
    ├── destroy/              # Destroy scripts
    └── validate/             # Validation runner
```

## Deployment Lifecycle

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Bootstrap  │───▶│  Validate   │───▶│    Plan     │───▶│    Apply    │
│  init/state │    │  fmt/lint/  │    │  review     │    │  approval   │
│             │    │  security   │    │  artifact   │    │  gate       │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                  │                  │                  │
       │                  │                  ▼                  │
       │                  │           ┌─────────────┐          │
       │                  │           │  Rollback   │◀─────────┘
       │                  │           │  on failure │
       │                  │           └─────────────┘
       │                  │
       ▼                  ▼
┌─────────────┐    ┌─────────────┐
│   State     │    │   Release   │
│  management │    │  promotion  │
└─────────────┘    └─────────────┘
```

## Quick Start

### 1. Bootstrap (one-time per environment)

```bash
# Select environment and initialize Terraform + remote backend
./deployment/scripts/bootstrap/select-environment.sh dev
./deployment/scripts/bootstrap/init-backend.sh dev
./deployment/scripts/bootstrap/validate-providers.sh dev
```

See [bootstrap/README.md](bootstrap/README.md).

### 2. Validate (before every deploy)

```bash
./deployment/scripts/validate/run-all.sh dev
```

See [validate/README.md](validate/README.md).

### 3. Deploy

```bash
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

See [deploy/README.md](deploy/README.md).

## Environment Matrix

| Environment | Directory | State Key | Apply Approval | Destroy |
|-------------|-----------|-----------|----------------|---------|
| Development | `environments/dev` | `dev.tfstate` | Optional | Allowed (with confirmation) |
| Staging | `environments/stage` | `stage.tfstate` | 1+ reviewer | Allowed (with confirmation) |
| Production | `environments/prod` | `prod.tfstate` | 2+ reviewers | **Blocked** (manual DR only) |

## GitHub Actions Integration

Local scripts mirror existing workflows:

| Framework Script | GitHub Workflow |
|------------------|-----------------|
| `validate/run-all.sh` | `terraform-pr.yml` (orchestrated checks) |
| `deploy/plan.sh` | `terraform-plan.yml` |
| `deploy/apply.sh` | `terraform-apply.yml` |
| `destroy/destroy.sh` | `terraform-destroy.yml` |
| Tag push | `release.yml` |
| Promote environment | `release-promotion.yml` |
| Emergency prod | `release-emergency.yml` |
| Rollback | `release-rollback.yml` |
| Drift detection | `terraform-drift.yml` |

Workflow definitions: [docs/cicd/README.md](../docs/cicd/README.md).

## Prerequisites

| Requirement | Version / Notes |
|-------------|-----------------|
| Terraform | `1.13.0` (see [versioning/README.md](versioning/README.md)) |
| Azure CLI | For authentication (OIDC in CI, `az login` locally) |
| Backend storage | Bootstrapped before first apply |
| `backend.hcl` | Per environment — copy from `backend.hcl.example` |
| `terraform.tfvars` | Per environment — copy from `terraform.tfvars.example` |

## Authentication

| Context | Method |
|---------|--------|
| GitHub Actions | OIDC federated credentials (planned — see `docs/cicd/README.md`) |
| Local operator | `az login` + subscription context |
| Service principal | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` |

Never commit credentials. Supply secrets via environment variables or GitHub Environment secrets.

## Runbooks

Operational procedures for on-call and platform engineers:

| Runbook | Path |
|---------|------|
| New environment | [docs/runbooks/new-environment.md](../docs/runbooks/new-environment.md) |
| Deploy | [docs/runbooks/deploy.md](../docs/runbooks/deploy.md) |
| Rollback | [docs/runbooks/rollback.md](../docs/runbooks/rollback.md) |
| Emergency recovery | [docs/runbooks/emergency-recovery.md](../docs/runbooks/emergency-recovery.md) |
| State recovery | [docs/runbooks/terraform-state-recovery.md](../docs/runbooks/terraform-state-recovery.md) |
| Provider upgrade | [docs/runbooks/provider-upgrade.md](../docs/runbooks/provider-upgrade.md) |

## Related Documentation

- [Release and Promotion Framework](../release/README.md)
- [Terraform Standards](../docs/terraform/standards.md)
- [Backend Strategy](../docs/terraform/backend-strategy.md)
- [Provider Inheritance](../docs/terraform/provider-inheritance.md)
- [CI/CD Architecture](../docs/cicd/README.md)
- [Dev Integration Review](../docs/terraform/dev-integration-review.md)
