# Runbook: Drift Recovery

Remediate infrastructure drift detected by scheduled or manual scans.

## Prerequisites

- Drift report artifact from `terraform-drift.yml` or `detect-drift.sh`
- Platform engineer access
- Understanding of whether drift is intentional

## Steps

### 1. Review drift report

```bash
# Download latest drift artifact from GitHub Actions
# Or run locally:
./release/scripts/detect-drift.sh prod
```

Review `drift-summary.md` and `plan.txt` for:
- Resources changed outside Terraform
- Additions, modifications, deletions

### 2. Classify drift

| Type | Example | Action |
|------|---------|--------|
| **Unauthorized** | Manual portal SKU change | Revert or import |
| **Authorized** | Emergency portal fix during incident | Update Terraform code |
| **Benign** | Tag added by policy | Update TF or ignore via lifecycle |
| **Critical** | Security rule removed | Immediate remediation |

### 3. Remediation paths

#### Path A: Revert manual change

1. Revert change in Azure Portal or CLI
2. Re-run drift scan to confirm clean
3. Document in change ticket

#### Path B: Update Terraform code

1. Create PR updating TF to match intended state
2. Pass all CI gates
3. Promote through normal pipeline

#### Path C: Import resource

```bash
cd environments/<env>
terraform import <resource_address> <azure_resource_id>
```

4. Verify with plan (should show no changes)

#### Path D: Remove from state (dev only)

```bash
terraform state rm <resource_address>
```

**Never** use state rm in production without ADR approval.

### 4. Verify

```bash
./release/scripts/detect-drift.sh <env>
# Exit code 0 = no drift
```

### 5. Document

- Update drift tracking issue
- Record remediation in audit log
- Update runbook if new drift pattern identified

## SLA

| Environment | Response |
|-------------|----------|
| Production | 4 hours |
| Stage | 24 hours |
| Development | Best effort |

## Prevention

- Restrict production portal write access
- Enforce Azure Policy deny rules
- Daily scheduled drift scans
- PR-only infrastructure changes

## Related

- [Drift Detection](../docs/drift-detection.md)
- [State Management](../../deployment/state/README.md)
