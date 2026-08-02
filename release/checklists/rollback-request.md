# Checklist: Rollback Request

Complete before executing a production rollback.

## Justification

- [ ] Rollback reason documented: ____________
- [ ] Incident ticket (if applicable): ____________
- [ ] Failed deployment run ID (if applicable): ____________
- [ ] Forward fix assessed (not viable because: ____________)

## Target

- [ ] Rollback target release tag: `v___________`
- [ ] Target tag was previously deployed successfully
- [ ] Target tag validation evidence available
- [ ] Current state backup taken

## Pre-Rollback

- [ ] `release-rollback.yml` inputs prepared
- [ ] Two approvers available (production)
- [ ] On-call engineer assigned
- [ ] Stakeholders notified
- [ ] Rollback plan artifact will be reviewed before apply

## Execution

- [ ] Rollback workflow triggered
- [ ] Confirmation phrase entered: `rollback-<environment>`
- [ ] Rollback plan reviewed
- [ ] Approval granted (2 reviewers for prod)
- [ ] Apply succeeded

## Post-Rollback

- [ ] Health checks passed
- [ ] Monitoring reviewed (15 min)
- [ ] Rollback audit record uploaded
- [ ] Incident updated
- [ ] Post-incident review scheduled
- [ ] Forward fix plan documented

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Release Engineer | | |
| Approver 1 | | |
| Approver 2 | | |
