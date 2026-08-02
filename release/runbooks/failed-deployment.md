# Runbook: Failed Deployment

Recover from a failed infrastructure deployment.

## Failure Classification

| Failure | Symptoms | Severity |
|---------|----------|----------|
| Plan failure | Exit code 1 during plan | Low — no changes applied |
| Apply failure | Error mid-apply | High — partial state |
| State lock | Lock timeout error | Medium — blocking |
| State corruption | Inconsistent state | Critical |
| Wrong environment | Applied to wrong env | Critical |

## Plan Failure

**Impact:** No infrastructure changes.

### Steps

1. Review plan error in workflow log
2. Fix code or configuration issue
3. Re-run promotion from beginning

```bash
gh workflow run release-promotion.yml \
  -f promotion_target=<env> \
  -f git_ref=<ref>
```

## Apply Failure (Partial Apply)

**Impact:** Some resources created/modified; state may be inconsistent.

### Steps

1. **Stop** — Do not re-run apply immediately
2. Capture state backup:
   ```bash
   cd environments/<env>
   terraform state pull > state-backup-$(date +%Y%m%d%H%M%S).json
   ```
3. Review apply log for last successful resource
4. Assess partial resources in Azure Portal
5. Choose recovery path:

| Option | When |
|--------|------|
| **Re-apply** | Transient error; state consistent |
| **Rollback** | Release was bad; revert to previous tag |
| **State surgery** | Orphaned resources; manual import/taint |
| **Destroy + recreate** | Dev only; non-production |

### Rollback

```bash
gh workflow run release-rollback.yml \
  -f environment=<env> \
  -f release_tag=<previous-tag> \
  -f confirmation=rollback-<env> \
  -f reason="Apply failure run <run_id>"
```

## State Lock

### Steps

1. Verify no active workflow run on same environment
2. Note lock ID from error message
3. Force unlock (with confirmation):
   ```bash
   cd environments/<env>
   terraform force-unlock <LOCK_ID>
   ```
4. Document in change ticket
5. Re-run promotion

## State Corruption

See [terraform state recovery](../../docs/runbooks/terraform-state-recovery.md).

## Wrong Environment

1. **Stop all operations immediately**
2. Notify platform lead and incident commander
3. Assess impact on wrong environment
4. Do not destroy without explicit approval
5. Rollback or forward fix based on assessment

## Escalation

| Condition | Escalate To |
|-----------|-------------|
| Production partial apply | Platform Lead + On-Call |
| State corruption | Platform Lead |
| Wrong environment | Incident Commander |
| Data impact (PostgreSQL) | DBA + Platform Lead |

## Related

- [Rollback Runbook](rollback.md)
- [Deployment Rollback](../../deployment/rollback/README.md)
- [Emergency Recovery](../../docs/runbooks/emergency-recovery.md)
