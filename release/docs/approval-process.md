# Approval Process

Manual and automated approval gates for infrastructure promotion.

## Gate Types

### Automated Gates (CI)

Run before any human approval. All must pass.

| Gate | Workflow | Failure Action |
|------|----------|----------------|
| Format | `terraform-format.yml` | Block promotion |
| Validate | `terraform-validate.yml` | Block promotion |
| Lint | `terraform-lint.yml` | Block promotion |
| Documentation | `terraform-docs.yml` | Block promotion |
| Security | `terraform-security.yml` | Block promotion |
| Plan | `release-promotion.yml` (plan job) | Block apply |
| Release validation | `release-validate.yml` | Block prod promotion |

Orchestrated by `release/scripts/quality-gates.sh` locally.

### Human Approval Gates

Configured via **GitHub Environment protection rules**.

## Approval Matrix

| Environment | Approval Type | Reviewers | Wait Timer | Notes |
|-------------|---------------|-----------|------------|-------|
| **Development** | Automatic | 0 | None | CI gates only |
| **Stage** | Manual | 1+ | Optional 5 min | Release engineer or platform team |
| **Production** | Two-person | 2+ | Recommended 15 min | Must include platform lead |
| **Emergency** | Two-person + ticket | 2+ | Waived | Separate workflow; post-incident review required |

## Development — Automatic

- Triggered on merge to `develop` or manual dispatch
- No human approval required
- All automated CI gates must pass
- Plan artifact generated and applied in same workflow run

## Stage — Manual Approval

### Approver requirements

- Platform engineer or release engineer
- Must not be the sole author of the change (four-eyes recommended)
- Must review plan artifact before approving

### Approval steps

1. Review GitHub Actions workflow summary
2. Inspect plan output artifact (`plan.txt`)
3. Verify dev environment validation completed
4. Complete [dev-to-stage checklist](../checklists/dev-to-stage.md)
5. Approve GitHub Environment deployment gate

## Production — Two-Person Approval

### Approver requirements

- Two distinct reviewers from platform team
- At least one must be a platform lead or designated release approver
- Neither approver should be the sole change author

### Approval steps

1. Verify release tag exists (`v*.*.*`)
2. Confirm `release.yml` validation succeeded for tag
3. Review production plan artifact
4. Complete [stage-to-prod checklist](../checklists/stage-to-prod.md)
5. Confirm cost review completed
6. Confirm rollback plan documented
7. Both reviewers approve GitHub Environment gate

### Production plan immutability

After the first approver begins review, the plan artifact is locked. Approvers must apply the **exact plan** generated in the workflow run. If the plan is stale, cancel the workflow and start a new promotion.

## Emergency Change — Separate Workflow

Emergency production changes use `release-emergency.yml`:

| Requirement | Detail |
|-------------|--------|
| Workflow | `release-emergency.yml` only |
| Ticket | Valid emergency change ticket ID required |
| Approval | 2 reviewers (can be expedited) |
| Scope | Minimal fix only |
| Post-incident | Review within 24 hours |
| Backport | Mandatory to `develop` within 24 hours |

See [change-management.md](change-management.md) and [emergency promotion runbook](../runbooks/emergency-promotion.md).

## Confirmation Inputs

Workflows require typed confirmation to prevent mis-clicks:

| Workflow | Input | Required Value |
|----------|-------|----------------|
| Rollback | `confirmation` | `rollback-<environment>` |
| Emergency | `confirmation` | `emergency-prod` |
| Destroy | `confirmation` | `destroy-<environment>` |

## Gate Bypass Policy

| Environment | Bypass Allowed |
|-------------|----------------|
| Development | Never for security gates |
| Stage | Never for security gates |
| Production | **Never** |
| Emergency | Security gates may be expedited with ticket; never fully bypassed |

All bypass events require post-incident review.

## Audit Trail

Every approval is recorded in:

- GitHub Environment deployment history
- Promotion audit artifact (`promotion-record.json`)
- Workflow run summary

See [auditability.md](auditability.md).

## Related

- [Promotion Flow](promotion-flow.md)
- [Deployment Approval Gates](../../deployment/deploy/approval-gates.md)
