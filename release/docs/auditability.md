# Auditability

Audit trail requirements for infrastructure promotions and rollbacks.

## Audit Principles

| Principle | Implementation |
|-----------|----------------|
| **Complete** | Record every promotion and rollback |
| **Immutable** | Artifacts stored in GitHub with retention |
| **Attributable** | GitHub username for every approval |
| **Traceable** | Link git commit → plan → apply |
| **Reproducible** | Pin terraform, providers, and git ref |

## Required Audit Fields

Every promotion or rollback must record:

| Field | Source |
|-------|--------|
| Who approved | GitHub Environment deployment reviewers |
| When promoted | Workflow run timestamp (UTC) |
| Artifact version | Plan artifact name and checksum |
| Terraform version | `TF_VERSION` env var |
| Provider versions | `.terraform.lock.hcl` at git ref |
| Git commit | Checked-out SHA |
| Release tag | Tag name (prod only) |
| Release notes | Generated notes or manual summary |
| Promotion target | dev / stage / prod |
| Change type | standard / emergency / rollback / hotfix |

## Audit Artifacts

| Artifact | Produced By | Retention |
|----------|-------------|-----------|
| `promotion-record.json` | `release-promotion.yml` | 90 days |
| `rollback-record.json` | `release-rollback.yml` | 90 days |
| `quality-gates-summary.md` | Quality gates job | 30 days |
| `plan.txt` | Plan job | 30–90 days |
| `tfplan` (binary) | Plan job | 30–90 days |
| GitHub Release | `release.yml` | Permanent |
| Environment deployment log | GitHub Environments | Permanent |

### Promotion record template

[../templates/promotion-record.json.tpl](../templates/promotion-record.json.tpl)

### Rollback record template

[../templates/rollback-record.json.tpl](../templates/rollback-record.json.tpl)

## Generating Audit Records

### CI (automatic)

Audit records are generated automatically by promotion and rollback workflows.

### Local (manual promotion)

```bash
./release/scripts/record-audit.sh \
  --type promotion \
  --target stage \
  --git-ref main \
  --plan-artifact tfplan-stage-local \
  --approver "operator-name"
```

## GitHub Environment Deployment History

Configure environment protection to require deployment records:

1. Settings → Environments → `prod`
2. Enable deployment branches (tags only)
3. Required reviewers: 2
4. Review deployment history regularly

## Compliance Mapping

| Requirement | Control |
|-------------|---------|
| Change authorization | GitHub Environment approval |
| Separation of duties | Two-person prod approval |
| Change record | `promotion-record.json` |
| Evidence retention | 90-day artifact retention |
| Emergency traceability | Emergency ticket ID in record |
| Rollback evidence | `rollback-record.json` |

## Audit Review Cadence

| Review | Frequency | Reviewer |
|--------|-----------|----------|
| Promotion records | Weekly | Platform lead |
| Emergency changes | Within 24h of event | Platform lead + security |
| Failed deployments | Per event | Release engineer |
| Drift reports | Weekly | Platform engineer |

## Related

- [Artifact Strategy](artifact-strategy.md)
- [Approval Process](approval-process.md)
- [Operational Responsibilities](operational-responsibilities.md)
