# Checklist: Emergency Change

Complete for every emergency production change.

## Incident

- [ ] Active incident declared (INC ticket: ____________)
- [ ] Incident commander assigned
- [ ] Impact and urgency documented
- [ ] Standard promotion path assessed (not viable because: ____________)

## Change Scope

- [ ] Change is minimal — fixes incident only
- [ ] No unrelated modifications included
- [ ] Hotfix branch from `main`: `hotfix/___________`
- [ ] PR reviewed (expedited)

## Pre-Deploy

- [ ] Stage quick-validation completed (or risk accepted and documented)
- [ ] Release tag created: `v____-hotfix.___`
- [ ] Rollback target identified: `v___________`
- [ ] Two approvers identified and available

## Emergency Workflow

- [ ] `release-emergency.yml` triggered
- [ ] Emergency ticket ID provided
- [ ] Confirmation phrase entered
- [ ] Quality gates passed (security gates NOT bypassed)
- [ ] Plan reviewed by both approvers
- [ ] Two-person approval granted

## Post-Deploy

- [ ] Production apply succeeded
- [ ] Incident resolved or mitigated
- [ ] Health checks passed
- [ ] Audit record uploaded with emergency ticket ID
- [ ] Backport to `develop` scheduled within 24 hours
- [ ] Post-incident review scheduled within 24 hours

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Incident Commander | | |
| Approver 1 | | |
| Approver 2 | | |
