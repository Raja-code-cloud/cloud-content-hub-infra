# Rollback Strategy

Rollback procedures for infrastructure releases at every environment.

## Rollback Principles

| Principle | Description |
|-----------|-------------|
| **Tag-based** | Production rollback targets a previous release tag |
| **Plan before apply** | Rollback generates and reviews a plan before apply |
| **Same pipeline** | Rollback uses `release-rollback.yml`, not ad-hoc commands |
| **State safety** | State backup before every rollback apply |
| **Audit everything** | Rollback records include reason and approvers |

## Rollback Methods by Environment

| Environment | Method | Approval | Workflow |
|-------------|--------|----------|----------|
| Development | Re-promote previous commit | Operator | `release-promotion.yml` |
| Stage | Re-promote previous commit or tag | 1 reviewer | `release-promotion.yml` or `release-rollback.yml` |
| Production | Rollback to previous release tag | 2 reviewers | `release-rollback.yml` |

## Production Rollback

### When to rollback

- Failed apply mid-deployment
- Post-deployment validation failure
- Critical incident caused by infrastructure change
- Security vulnerability introduced by change

### Production rollback steps

```bash
# 1. Identify last known-good release tag
git tag --sort=-v:refname | head -5

# 2. Trigger rollback workflow
gh workflow run release-rollback.yml \
  -f environment=prod \
  -f release_tag=v1.2.2 \
  -f confirmation=rollback-prod \
  -f reason="Incident INC-1234: revert CAE config change"

# 3. Review rollback plan (two-person approval)
# 4. Monitor post-rollback health
```

Or locally:

```bash
./release/scripts/rollback-release.sh prod v1.2.2
```

## State Rollback

If apply corrupted state but Azure resources are intact:

```bash
# 1. Pull current state backup
cd environments/prod
terraform state pull > state-backup-$(date +%Y%m%d).json

# 2. Restore from blob versioning (Azure Portal or CLI)
az storage blob download \
  --account-name <storage> \
  --container-name tfstate \
  --name prod.tfstate \
  --version-id <version> \
  --file prod.tfstate.restored

# 3. Push restored state (with extreme caution)
terraform state push prod.tfstate.restored
```

See [terraform state recovery runbook](../../docs/runbooks/terraform-state-recovery.md).

## Failed Deployment Recovery

| Failure Point | Recovery |
|---------------|----------|
| Plan failed | Fix code; re-run promotion |
| Apply failed mid-run | Rollback to previous tag; investigate partial resources |
| State lock | `terraform force-unlock` (with confirmation) |
| State corruption | Blob version restore |
| Wrong environment | Stop immediately; assess impact; rollback |

See [failed deployment runbook](../runbooks/failed-deployment.md).

## Emergency Rollback

For active incidents:

1. Declare incident and assign incident commander
2. Trigger `release-rollback.yml` with `priority=emergency`
3. Two-person approval (expedited)
4. Apply rollback plan
5. Validate service health
6. Post-incident review within 24 hours

## Rollback Limitations

| Scenario | Rollback Viable | Alternative |
|----------|-----------------|-------------|
| Destructive change applied | Partial | Restore from backup; manual intervention |
| State migration applied | Difficult | State surgery; ADR required |
| Data loss (PostgreSQL) | No | Point-in-time restore (separate runbook) |
| Provider major upgrade | Complex | Forward fix preferred |

## Rollback Record

Every rollback produces `rollback-record.json`:

Template: [templates/rollback-record.json.tpl](../templates/rollback-record.json.tpl)

## Related

- [Deployment Rollback](../../deployment/rollback/README.md)
- [Rollback Runbook](../runbooks/rollback.md)
- [Failed Deployment Runbook](../runbooks/failed-deployment.md)
