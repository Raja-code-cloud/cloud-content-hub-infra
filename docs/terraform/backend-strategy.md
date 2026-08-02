# Backend Strategy

Remote state management design for **cloud-content-hub-infra**.

## Overview

| Property | Value |
|----------|-------|
| Backend type | `azurerm` (Azure Storage) |
| State granularity | One state file per environment |
| Workspaces | **Not used** |
| Locking | Azure blob lease (native to azurerm backend) |

## State File Mapping

| Environment | Directory | State Key |
|-------------|-----------|-----------|
| Development | `environments/dev` | `dev.tfstate` |
| Staging | `environments/stage` | `stage.tfstate` |
| Production | `environments/prod` | `prod.tfstate` |

All environments share a single storage container (`tfstate`) but use **distinct blob keys** to isolate state.

## Configuration

Backend configuration lives in `environments/<env>/backend.tf` with **placeholder values only**:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "<placeholder-resource-group>"
    storage_account_name = "<placeholder-storage-account>"
    container_name       = "tfstate"
    key                  = "dev.tfstate"   # unique per environment
  }
}
```

Real values will be supplied when the bootstrap storage account is provisioned, either by:

- Replacing placeholders in `backend.tf` (less preferred), or
- Passing `-backend-config` flags / a `backend.hcl` file in CI (preferred for secrets isolation)

## Why Separate State Files (Not Workspaces)

This repository deliberately avoids Terraform workspaces in favour of one state file per environment.

### 1. Blast radius isolation

A mistaken `terraform destroy` or state corruption in dev cannot affect stage or prod because each environment has an independent state blob with no shared namespace.

### 2. Access control

Azure Storage supports per-blob RBAC. Separate keys allow fine-grained permissions:

- Developers: read/write on `dev.tfstate`
- Release engineers: read/write on `stage.tfstate`
- Platform admins only: read/write on `prod.tfstate`

Workspaces share a single backend key prefix and are harder to permission independently.

### 3. CI/CD clarity

Each GitHub Actions workflow maps 1:1 to an environment directory and state file. There is no implicit workspace selection that could cause the wrong environment to be targeted.

### 4. Subscription boundary alignment

Environments may target different Azure subscriptions. Separate root modules with separate state files align naturally with subscription-scoped deployments.

### 5. Operational simplicity

Workspace switching (`terraform workspace select`) is an easy source of human error. Explicit directories (`cd environments/prod`) make the target environment unambiguous.

### 6. Auditability

State file names appear directly in storage logs and backup policies, simplifying audit trails and disaster recovery.

## Bootstrap Sequence (Future Phase)

The state storage account itself is a chicken-and-egg problem. The planned bootstrap sequence:

1. Provision state storage via a one-time bootstrap script or pipeline.
2. Update `backend.tf` placeholders (or supply `backend.hcl`).
3. Run `terraform init -migrate-state` if migrating from local state.
4. Enable soft delete and versioning on the storage account.

## Disaster Recovery

- Enable **blob versioning** and **soft delete** on the state storage account.
- Store state storage details in the platform runbook (see `docs/runbooks/`).
- Never store state files locally in production workflows.

## Related

- [ADR-0001: Separate state files per environment](../adr/adr-0001-separate-state-files-per-environment.md)
- [Provider Inheritance](provider-inheritance.md)
