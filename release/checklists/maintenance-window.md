# Checklist: Maintenance Window

Complete before scheduled infrastructure maintenance.

## Planning

- [ ] Maintenance window scheduled: ____________ (UTC)
- [ ] Duration estimated: ____________ hours
- [ ] Environment: [ ] stage  [ ] prod
- [ ] Stakeholders notified 48 hours in advance
- [ ] Change request documented

## Preparation

- [ ] Release tag or git ref identified
- [ ] Promotion checklist completed (dev→stage or stage→prod)
- [ ] Rollback plan ready
- [ ] On-call engineer assigned
- [ ] Communication channel established (#platform-ops)

## Pre-Window

- [ ] No active incidents
- [ ] Current environment stable
- [ ] State backup verified
- [ ] Drift scan clean (or drift documented)
- [ ] All approvers confirmed availability

## Execution

- [ ] Promotion workflow triggered at window start
- [ ] Quality gates passed
- [ ] Plan reviewed and approved
- [ ] Apply completed within window
- [ ] Post-apply validation passed

## Post-Window

- [ ] Stakeholders notified of completion
- [ ] Monitoring reviewed (30 min)
- [ ] Audit record uploaded
- [ ] Window closed in change management system

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Release Engineer | | |
| On-Call Engineer | | |
| Approver(s) | | |
