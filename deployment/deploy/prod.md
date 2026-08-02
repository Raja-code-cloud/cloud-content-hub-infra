# Production Deployment

Deployment procedure for the **prod** environment.

## Profile

| Property | Value |
|----------|-------|
| Directory | `environments/prod` |
| State key | `prod.tfstate` |
| Approval gate | **Required** — 2+ reviewers |
| Destroy | **Permanently blocked** in CI |
| Purpose | Live platform infrastructure |

## When to Deploy

- Stage soak period complete
- Change advisory approved
- Release tag created (`v*.*.*`)
- Maintenance window scheduled (if breaking changes)

## Prerequisites

- [ ] Stage deployment validated
- [ ] Release tag pushed (`v1.2.3`)
- [ ] `release.yml` workflow passed (validate + security + plan)
- [ ] GitHub Environment `prod` configured with 2+ required reviewers
- [ ] Change ticket approved
- [ ] Rollback plan documented
- [ ] On-call engineer notified

## Deployment Steps

### 1. Create release tag

```bash
git tag -a v1.2.3 -m "Release v1.2.3 — description"
git push origin v1.2.3
```

The `release.yml` workflow validates, scans, and plans all environments.

### 2. Review release artifacts

Download from GitHub Release or workflow artifacts:

- Plan output for `prod`
- Security scan summary
- Release notes

### 3. Apply via GitHub Actions

1. Actions → **Terraform Apply**
2. environment: `prod`
3. confirmation: `prod`
4. use_plan_artifact: `<release workflow run ID>` (recommended)
5. **Two reviewers** approve via GitHub Environment gate
6. Apply executes

### 4. Post-deploy verification

```bash
# Read-only verification (no apply)
cd environments/prod
terraform output
```

Verify all critical outputs and application health.

## Production Safeguards

| Safeguard | Implementation |
|-----------|----------------|
| Destroy blocked | `terraform-destroy.yml` rejects `prod` |
| Dual approval | GitHub Environment `prod` — 2 reviewers |
| Tag-gated releases | `release.yml` on `v*.*.*` |
| Plan artifact reuse | Apply from release plan when possible |
| State locking | Azure blob lease prevents concurrent apply |
| Audit trail | GitHub Actions logs + state storage access logs |

## Production-Specific Configuration

When composing `environments/prod/main.tf` (during promotion):

| Setting | Production Recommendation |
|---------|------------------------|
| Key Vault | Purge protection **enabled** |
| PostgreSQL | General Purpose SKU, geo-redundant backup |
| Log Analytics | Higher retention, no daily cap reduction |
| Application Insights | Lower sampling or adaptive |
| Container App | Minimum replicas ≥ 1 for availability |
| Network | Private endpoints (when modules available) |

## Emergency Changes

For production incidents requiring immediate infrastructure change:

1. Create `hotfix/*` branch from `main`
2. Minimal fix only
3. Fast-track PR with expedited review
4. Plan + apply via break-glass procedure
5. Backport to `develop`

See [release/README.md](../release/README.md#hotfix-process).

## Related

- [Approval Gates](approval-gates.md)
- [Rollback](../rollback/README.md)
- [Emergency Recovery Runbook](../../docs/runbooks/emergency-recovery.md)
