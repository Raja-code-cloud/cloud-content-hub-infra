# Change Management

Change types, workflows, and requirements for infrastructure releases.

## Change Types

| Type | Workflow | Approval | Lead Time |
|------|----------|----------|-----------|
| **Standard** | `release-promotion.yml` | Per environment matrix | 24h soak for prod |
| **Emergency** | `release-emergency.yml` | 2 reviewers + ticket | Immediate |
| **Hotfix** | `release-promotion.yml` or emergency | 2 reviewers for prod | Expedited |
| **Rollback** | `release-rollback.yml` | Per environment | Immediate |
| **Maintenance** | `release-promotion.yml` | Per environment | Scheduled window |

## Standard Changes

Normal infrastructure updates following the promotion pipeline.

### Requirements

- Pull request with passing CI
- Dev validation complete
- Stage soak (minimum 24 hours recommended)
- Release tag for production
- Change documented in release notes
- Rollback plan identified

### Process

```
PR → develop → dev → main → stage → tag → prod
```

Template: [templates/change-request.md.tpl](../templates/change-request.md.tpl)

## Emergency Changes

Urgent changes to restore service or fix critical security issues.

### Requirements

- Active incident or critical vulnerability
- Emergency change ticket ID
- Minimal scope (fix only the incident)
- Two-person approval via `release-emergency.yml`
- Post-incident review within 24 hours
- Backport to `develop` within 24 hours

### Process

```
hotfix/* → main → stage (quick) → prod (emergency workflow) → backport develop
```

Checklist: [checklists/emergency-change.md](../checklists/emergency-change.md)

### Emergency workflow inputs

```yaml
release_tag: v1.2.4-hotfix.1
git_ref: v1.2.4-hotfix.1
emergency_ticket: INC-1234
confirmation: emergency-prod
reason: "Critical security patch for Key Vault access policy"
```

## Hotfixes

Focused fixes branched from `main` for production issues.

### Hotfix rules

| Rule | Description |
|------|-------------|
| Branch from `main` | `hotfix/<description>` |
| Minimal scope | Only incident-related changes |
| Tag required | `v*.*.*-hotfix.*` before prod |
| Stage validation | Quick stage apply before prod |
| Backport mandatory | Merge to `develop` within 24 hours |
| Post-incident review | Within 48 hours |

## Rollback Requests

Formal rollback of a deployed release.

### Requirements

- Reason documented
- Target release tag identified (last known-good)
- Two-person approval for production
- Post-rollback validation

Checklist: [checklists/rollback-request.md](../checklists/rollback-request.md)

## Maintenance Windows

Scheduled infrastructure maintenance with advance notification.

### Requirements

- Scheduled window documented
- Stakeholders notified 48 hours in advance
- Checklist completed: [checklists/maintenance-window.md](../checklists/maintenance-window.md)
- Rollback plan ready
- On-call engineer assigned

### Recommended windows

| Environment | Window (UTC) | Frequency |
|-------------|--------------|-----------|
| Stage | Tue 02:00–06:00 | Weekly |
| Production | Sun 02:00–06:00 | Bi-weekly |

## Change Advisory Board (Recommended)

For production changes, a lightweight CAB review:

| Participant | Role |
|-------------|------|
| Platform lead | Approve/reject |
| Release engineer | Present change |
| FinOps representative | Cost impact (if significant) |
| Security representative | Security impact (if significant) |

CAB is recommended but not blocking for standard changes with passing checklists.

## Related

- [Approval Process](approval-process.md)
- [Emergency Promotion Runbook](../runbooks/emergency-promotion.md)
- [Lifecycle](lifecycle.md)
