# State Management

Remote state management, locking, recovery, migration, import, and drift detection.

## Overview

| Property | Value |
|----------|-------|
| Backend | `azurerm` (Azure Storage) |
| Granularity | One state file per environment |
| Locking | Azure blob lease (native) |
| Workspaces | Not used |

See [Backend Strategy](../../docs/terraform/backend-strategy.md) and [ADR-0001](../../docs/adr/adr-0001-separate-state-files-per-environment.md).

## State File Mapping

| Environment | Blob Key | Directory |
|-------------|----------|-----------|
| dev | `dev.tfstate` | `environments/dev` |
| stage | `stage.tfstate` | `environments/stage` |
| prod | `prod.tfstate` | `environments/prod` |

## State Locking

### How it works

The azurerm backend acquires an exclusive lease on the state blob during plan/apply operations. Concurrent operations on the same environment are blocked.

### Lock duration

Default Azure blob lease: **15–60 seconds**, renewed during operation. Stale locks from crashed processes expire automatically.

### Check lock status

```bash
az storage blob show \
  --account-name <storage-account> \
  --container-name tfstate \
  --name dev.tfstate \
  --auth-mode login \
  --query 'properties.lease'
```

### Break a stale lock

**Only when confirmed no operation is running:**

```bash
# Option 1: Terraform force-unlock (requires lock ID from error message)
cd environments/dev
terraform force-unlock <LOCK_ID>

# Option 2: Azure CLI break lease
az storage blob lease break \
  --account-name <storage-account> \
  --container-name tfstate \
  --blob-name dev.tfstate \
  --auth-mode login
```

Document every force-unlock in the change ticket.

## State Recovery

### Backup strategy

| Method | Frequency | Retention |
|--------|-----------|-----------|
| Blob versioning | Continuous (enable on storage account) | 90 days |
| Soft delete | Continuous (enable on storage account) | 30 days |
| Pre-apply pull | Every apply/destroy | Operator workstation / CI artifact |
| Pre-destroy pull | Every destroy | CI artifact (30 days) |

### Pull state backup

```bash
cd environments/dev
terraform state pull > "terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)"
```

### Restore from blob version

```bash
# List versions
az storage blob list \
  --account-name <storage-account> \
  --container-name tfstate \
  --prefix dev.tfstate \
  --include versions \
  --auth-mode login

# Restore specific version
az storage blob copy start \
  --account-name <storage-account> \
  --destination-container tfstate \
  --destination-blob dev.tfstate \
  --source-uri "<version-url>" \
  --auth-mode login
```

Full procedure: [terraform-state-recovery.md](../../docs/runbooks/terraform-state-recovery.md).

## State Migration

### Local to remote

```bash
./deployment/scripts/bootstrap/migrate-state.sh dev
```

### Between storage accounts

1. Backup current state: `terraform state pull > backup.tfstate`
2. Update `backend.hcl` with new storage account
3. Run `terraform init -migrate-state -backend-config=backend.hcl`
4. Verify: `terraform state list`

### Between environments

**Never** copy state files between environments. Each environment has independent state.

## Import Strategy

When adopting existing Azure resources into Terraform management:

### 1. Prepare

- Identify resource Azure Resource ID
- Ensure module composition matches existing resource configuration
- Backup state before import

### 2. Import

```bash
cd environments/dev
terraform import 'module.resource_group.azurerm_resource_group.this' \
  /subscriptions/<sub>/resourceGroups/<rg-name>
```

### 3. Reconcile

```bash
terraform plan
# Expect minimal or zero changes if configuration matches
```

### Import rules

| Rule | Description |
|------|-------------|
| One at a time | Import resources individually |
| Plan after each | Verify no unexpected changes |
| Module address | Use full module resource address |
| Document | Record imports in change ticket |
| No prod without stage | Test import in dev/stage first |

## Drift Detection

### Manual drift check

```bash
./deployment/scripts/deploy/plan.sh dev
# Any changes in plan.txt without code changes indicate drift
```

### Refresh state

```bash
cd environments/dev
terraform refresh -var-file=terraform.tfvars
```

### Drift response

| Drift Type | Response |
|------------|----------|
| Manual Azure Portal change | Revert in Portal OR update Terraform to match |
| Auto-scaling change | Add lifecycle `ignore_changes` in module (if intentional) |
| Azure service update | Plan and apply to reconcile |
| Unauthorized change | Incident response — revert and investigate |

### Scheduled drift detection (future)

Plan a scheduled GitHub Actions workflow:

```
cron: weekly → terraform plan → alert on changes
```

## State Security

| Control | Implementation |
|---------|----------------|
| Encryption at rest | Azure Storage SSE (default) |
| Access control | RBAC per state blob |
| No local state in CI | Remote backend only for apply |
| Audit logging | Storage account diagnostic logs |
| Secret exclusion | Never store secrets in state (use Key Vault references) |

## Related

- [Bootstrap — State Migration](../bootstrap/README.md#state-migration)
- [Rollback](../rollback/README.md)
- [State Recovery Runbook](../../docs/runbooks/terraform-state-recovery.md)
