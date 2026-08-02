# Checklist: Development → Stage Promotion

Complete before promoting from Development to Stage.

## Pre-Promotion

- [ ] All feature PRs merged to `develop`
- [ ] `develop` branch CI passing (`terraform-pr.yml`)
- [ ] Development environment promoted and validated
- [ ] No open HIGH/CRITICAL security findings
- [ ] Release engineer assigned

## Development Validation

- [ ] Dev promotion workflow succeeded
- [ ] Dev plan showed expected changes only
- [ ] Key outputs verified (resource group, KV, CAE, etc.)
- [ ] No unexpected drift in dev (or drift documented)
- [ ] Integration smoke tests passed

## Code Readiness

- [ ] PR from `develop` → `main` created and approved
- [ ] No secrets in diff
- [ ] terraform-docs up to date
- [ ] Breaking changes documented in PR description
- [ ] Module interface changes noted in release notes draft

## Stage Promotion

- [ ] `release-promotion.yml` triggered with `promotion_target=stage`, `git_ref=main`
- [ ] Quality gates passed
- [ ] Stage plan artifact reviewed
- [ ] Cost impact assessed (if significant changes)
- [ ] Manual approval granted (1 reviewer)

## Post-Promotion

- [ ] Stage apply succeeded
- [ ] Stage outputs verified
- [ ] Promotion audit record uploaded
- [ ] Soak period started (minimum 24 hours recommended)
- [ ] Stakeholders notified (if maintenance window)

## Sign-Off

| Role | Name | Date |
|------|------|------|
| Release Engineer | | |
| Approver | | |
