# Runbook: Terraform State Recovery

Recover from Terraform state corruption, loss, or locking issues.

## Symptoms

| Symptom | Likely Cause |
|---------|--------------|
| `Error acquiring the state lock` | Concurrent operation or crashed process |
| `state snapshot was created by a newer version` | Terraform version mismatch |
| `Failed to load state` | Corrupted or deleted state blob |
| Resources exist in Azure but not in state | Manual creation or lost state |
| State has resources that don't exist in Azure | Manual deletion outside Terraform |

## Prerequisites

- Platform admin access
- Azure Storage RBAC on state storage account
- Terraform `1.13.0` installed
- State backup available (blob version or local pull)

## Procedure 1 — Stale State Lock

### 1. Confirm no active operation

Check GitHub Actions for running workflows. Contact last operator.

### 2. Check lease

```bash
az storage blob show \
  --account-name <storage-account> \
  --container-name tfstate \
  --name <env>.tfstate \
  --auth-mode login \
  --query 'properties.lease'
```

### 3. Break lock

```bash
# Preferred: use Lock ID from Terraform error
cd environments/<env>
terraform force-unlock <LOCK_ID>

# Alternative: Azure CLI
az storage blob lease break \
  --account-name <storage-account> \
  --container-name tfstate \
  --blob-name <env>.tfstate \
  --auth-mode login
```

### 4. Document

Record lock break in change ticket with justification.

## Procedure 2 — Restore State from Blob Version

### 1. Enable versioning (if not already)

Verify on state storage account: **Blob versioning = Enabled**.

### 2. List versions

```bash
az storage blob list \
  --account-name <storage-account> \
  --container-name tfstate \
  --prefix <env>.tfstate \
  --include versions \
  --auth-mode login \
  --output table
```

### 3. Identify good version

Select the version timestamp before corruption occurred.

### 4. Restore

```bash
# Download specific version for inspection
az storage blob download \
  --account-name <storage-account> \
  --container-name tfstate \
  --name <env>.tfstate \
  --version-id <version-id> \
  --file restored.tfstate \
  --auth-mode login

# Verify content
terraform state list -state=restored.tfstate

# Copy restored version over current blob (CAUTION)
az storage blob upload \
  --account-name <storage-account> \
  --container-name tfstate \
  --name <env>.tfstate \
  --file restored.tfstate \
  --overwrite \
  --auth-mode login
```

### 5. Verify

```bash
cd environments/<env>
terraform init -backend-config=backend.hcl
terraform state list
terraform plan -var-file=terraform.tfvars
# Expect zero or minimal changes
```

## Procedure 3 — Restore from Local Backup

If `terraform state pull` backup exists:

```bash
# Push backup to remote state
cd environments/<env>
terraform state push terraform.tfstate.backup.YYYYMMDDHHMMSS
terraform plan -var-file=terraform.tfvars
```

## Procedure 4 — Import Missing Resources

When resources exist in Azure but not in state:

```bash
# 1. Identify resource ID
az resource show --ids <resource-id>

# 2. Import
terraform import 'module.<name>.<resource_type>.this' <azure-resource-id>

# 3. Plan to reconcile configuration drift
terraform plan -var-file=terraform.tfvars
```

Import one resource at a time. Plan after each import.

## Procedure 5 — Remove Phantom State Entries

When state references resources deleted outside Terraform:

```bash
terraform state rm 'module.storage.azurerm_storage_account.this'
# Then either import replacement or apply to recreate
```

**Warning:** Only remove after confirming resource is truly gone in Azure.

## Prevention

| Control | Implementation |
|---------|----------------|
| Blob versioning | Enabled on state storage account |
| Soft delete | 30-day retention |
| Pre-apply backup | `terraform state pull` in CI |
| Pre-destroy backup | Destroy script automatic backup |
| Lock awareness | Never run concurrent applies |
| Version pinning | Terraform 1.13.0 in CI |

## Escalation

If state cannot be recovered:

1. Activate [emergency-recovery.md](emergency-recovery.md)
2. Engage platform architect
3. Consider full re-apply from last known-good tag (with `-refresh-only` assessment)
4. Last resort: destroy and recreate non-production environments only

## Related

- [State Management](../../deployment/state/README.md)
- [Backend Strategy](../terraform/backend-strategy.md)
