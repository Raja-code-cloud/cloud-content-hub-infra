# Checklist: Stage → Production Promotion

Complete before promoting from Stage to Production.

## Pre-Promotion

- [ ] Stage soak period complete (minimum 24 hours)
- [ ] Stage environment validated and stable
- [ ] No active incidents affecting stage
- [ ] Release tag created (`v*.*.*`)
- [ ] `release.yml` workflow succeeded for tag
- [ ] Rollback target identified (previous release tag)

## Stage Validation

- [ ] Stage promotion workflow succeeded
- [ ] Stage plan showed expected changes only
- [ ] Integration tests passed on stage
- [ ] No drift detected (or drift remediated)
- [ ] Performance baseline acceptable

## Production Readiness

- [ ] Production plan reviewed by 2 reviewers
- [ ] Cost review completed (FinOps sign-off if significant)
- [ ] Change advisory documented
- [ ] Rollback plan documented and tested on stage
- [ ] Maintenance window scheduled (if required)
- [ ] On-call engineer assigned

## Security and Compliance

- [ ] No HIGH/CRITICAL security findings
- [ ] Policy compliance verified
- [ ] No hardcoded secrets in release
- [ ] RBAC changes reviewed

## Production Promotion

- [ ] `release-promotion.yml` triggered with:
  - `promotion_target=prod`
  - `git_ref=v*.*.*`
  - `release_tag=v*.*.*`
- [ ] Quality gates passed
- [ ] Production plan artifact reviewed
- [ ] Two-person approval granted
- [ ] Plan artifact not stale (< 4 hours)

## Post-Promotion

- [ ] Production apply succeeded
- [ ] Production outputs verified
- [ ] Health checks passed
- [ ] Promotion audit record uploaded
- [ ] GitHub Release notes updated
- [ ] Stakeholders notified
- [ ] Monitoring dashboards reviewed (15 min)

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Release Engineer | | |
| Approver 1 | | |
| Approver 2 | | |
| FinOps (if required) | | |
