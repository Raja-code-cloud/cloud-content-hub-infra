# Runbook: Emergency Promotion

Expedited production deployment for active incidents.

## When to Use

- Active production incident requiring infrastructure fix
- Critical security vulnerability
- Standard promotion path too slow for incident SLA

**Do not use** for convenience or to skip quality gates.

## Prerequisites

- Active incident ticket (INC-XXXX)
- Incident commander assigned
- Two approvers available
- Hotfix branch ready and merged to `main`

## Checklist

[emergency-change.md](../checklists/emergency-change.md)

## Steps

### 1. Prepare hotfix

```bash
git checkout main && git pull
git checkout -b hotfix/incident-description
# minimal fix only
git push -u origin hotfix/incident-description
# PR to main — expedited review
```

### 2. Quick stage validation

```bash
gh workflow run release-promotion.yml \
  -f promotion_target=stage \
  -f git_ref=main
```

Review stage plan. Apply if acceptable. If stage unavailable, document risk acceptance.

### 3. Create hotfix tag

```bash
git tag -a v1.2.4-hotfix.1 -m "Hotfix: INC-1234 description"
git push origin v1.2.4-hotfix.1
```

### 4. Emergency production promotion

```bash
gh workflow run release-emergency.yml \
  -f release_tag=v1.2.4-hotfix.1 \
  -f git_ref=v1.2.4-hotfix.1 \
  -f emergency_ticket=INC-1234 \
  -f confirmation=emergency-prod \
  -f reason="Description of incident and fix"
```

### 5. Approve and monitor

- Two reviewers approve GitHub Environment gate
- Monitor health for 30 minutes post-apply
- Update incident ticket

### 6. Post-incident

- [ ] Backport hotfix to `develop` within 24 hours
- [ ] Post-incident review within 24 hours
- [ ] Update audit record
- [ ] Document in release notes

## Constraints

| Constraint | Detail |
|------------|--------|
| Security gates | Never bypassed |
| Scope | Minimal fix only |
| Approval | Two-person required |
| Audit | Emergency ticket ID mandatory |

## Related

- [Change Management](../docs/change-management.md)
- [Failed Deployment](failed-deployment.md)
