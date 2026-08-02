# Runbook: Rollback

Rollback infrastructure to a previous release.

## Prerequisites

- Rollback target release tag identified
- Two approvers available (production)
- Rollback checklist completed

## Checklist

[rollback-request.md](../checklists/rollback-request.md)

## Steps

### 1. Identify rollback target

```bash
# List recent tags
git tag --sort=-v:refname | head -10

# Verify tag was previously deployed
gh run list --workflow=release-promotion.yml --limit 10
```

### 2. Trigger rollback workflow

**Production:**

```bash
gh workflow run release-rollback.yml \
  -f environment=prod \
  -f release_tag=v1.2.2 \
  -f confirmation=rollback-prod \
  -f reason="Revert v1.2.3 — reason"
```

**Stage:**

```bash
gh workflow run release-rollback.yml \
  -f environment=stage \
  -f release_tag=v1.2.2 \
  -f confirmation=rollback-stage \
  -f reason="Revert v1.2.3 — reason"
```

### 3. Review rollback plan

- Download plan artifact from workflow
- Verify changes revert expected resources
- Confirm no unintended destroys

### 4. Approve and apply

- Approve GitHub Environment gate (2 reviewers for prod)
- Monitor apply progress
- Verify health checks

### 5. Post-rollback

- Upload/update incident ticket
- Review monitoring (15–30 min)
- Schedule post-incident review
- Document forward fix plan

## Local Alternative

```bash
./release/scripts/rollback-release.sh prod v1.2.2
```

## State Rollback

If state is corrupted but resources are intact, see [terraform state recovery](../../docs/runbooks/terraform-state-recovery.md).

## Related

- [Rollback Strategy](../docs/rollback.md)
- [Failed Deployment](failed-deployment.md)
