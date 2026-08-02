# Runbook: Rollback

Recover from a failed or undesired infrastructure deployment.

## When to Use

- Apply introduced breaking changes
- Wrong release deployed to environment
- Partial apply failure leaving inconsistent state
- Configuration regression detected post-deploy

## Severity Classification

| Severity | Environment | Response Time |
|----------|-------------|---------------|
| S3 | dev | Best effort |
| S2 | stage | 1 hour |
| S1 | prod | 15 minutes |

## Procedure

### 1. Assess

```bash
cd environments/<env>
terraform state list
terraform plan -var-file=terraform.tfvars 2>&1 | tail -50
```

Determine:

- Is state locked?
- Is the failure in one resource or widespread?
- Is a previous release tag available?

### 2. Choose strategy

| Scenario | Strategy |
|----------|----------|
| Wrong config deployed | Git ref rollback (preferred) |
| Single resource failed | `terraform taint` + re-apply |
| Partial apply | Re-run apply (Terraform reconciles) |
| State corrupted | [terraform-state-recovery.md](terraform-state-recovery.md) |

### 3. Execute rollback (config rollback)

```bash
# Identify last known-good tag
git tag --sort=-v:refname | head -5

# Rollback
./deployment/scripts/rollback/rollback.sh <env> v1.2.2
```

For production:

- Requires 2+ approver acknowledgment
- Use GitHub Actions apply when possible
- Document in incident ticket

### 4. Verify

```bash
cd environments/<env>
terraform output
# Application health checks
```

### 5. Post-rollback

- [ ] Incident ticket updated
- [ ] Root cause documented
- [ ] Fix forward planned on appropriate branch
- [ ] Post-incident review scheduled (prod S1/S2)

## State Lock During Rollback

If lock error occurs:

```bash
# See error message for Lock ID
terraform force-unlock <LOCK_ID>
```

Only after confirming no active apply is running. See [terraform-state-recovery.md](terraform-state-recovery.md).

## Production Rollback Constraints

- **Never** run destroy on production
- **Always** rollback via known-good tag
- **Always** generate plan before apply
- **Always** retain 2+ approvers

## Related

- [Rollback Strategy](../../deployment/rollback/README.md)
- [Emergency Recovery](emergency-recovery.md)
