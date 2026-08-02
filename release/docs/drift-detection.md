# Drift Detection

Repository standards for detecting, reporting, and remediating infrastructure drift.

## Definition

**Drift** occurs when live Azure resources differ from Terraform state — caused by manual portal changes, failed applies, or external automation.

## Detection Methods

| Method | Trigger | Workflow / Script |
|--------|---------|-------------------|
| Scheduled | Daily 06:00 UTC | `terraform-drift.yml` |
| Manual | On demand | `terraform-drift.yml` (dispatch) |
| Pre-promotion | Before stage/prod | `release-promotion.yml` (plan job detects drift) |
| Local | Operator initiated | `release/scripts/detect-drift.sh` |

## Scheduled Drift Detection

```yaml
# terraform-drift.yml
schedule:
  - cron: '0 6 * * *'  # Daily 06:00 UTC
```

Runs `terraform plan -detailed-exitcode` for each environment:

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | No changes | Log success |
| 1 | Error | Alert platform team |
| 2 | Drift detected | Create drift report, notify |

## Drift Report Artifact

Each drift run produces:

```
drift-report-<environment>-<date>/
├── plan.txt           # Human-readable drift plan
├── plan.log           # Full output
├── drift-summary.md   # Summary with resource counts
└── drift-metadata.json
```

### Drift metadata

```json
{
  "environment": "prod",
  "detected_at": "2026-08-02T06:00:00Z",
  "git_ref": "v1.2.3",
  "drift_detected": true,
  "add_count": 0,
  "change_count": 2,
  "destroy_count": 0,
  "workflow_run_id": "<id>"
}
```

## Notification

When drift is detected (exit code 2):

1. Upload drift report artifact
2. Post summary to workflow run
3. Notify via configured action group (when OIDC enabled)
4. Create tracking issue (manual or automated)

## Remediation Workflow

```
Drift Detected
      │
      ▼
┌─────────────┐     Yes    ┌─────────────┐
│  Intentional│───────────▶│  Update TF  │──▶ PR ──▶ Promote
│   change?   │            │    code     │
└─────────────┘            └─────────────┘
      │ No
      ▼
┌─────────────┐            ┌─────────────┐
│  Revert in  │───────────▶│  terraform  │
│   portal    │            │    apply    │
└─────────────┘            └─────────────┘
      │ Can't revert
      ▼
┌─────────────┐
│  Import or  │
│  taint/     │
│  replace    │
└─────────────┘
```

See [drift recovery runbook](../runbooks/drift-recovery.md).

## Environment Priority

| Environment | Drift Response SLA |
|-------------|-------------------|
| Production | 4 hours |
| Stage | 24 hours |
| Development | Best effort |

## Drift Prevention

| Practice | Description |
|----------|-------------|
| RBAC least privilege | Limit portal write access to production |
| Azure Policy | Deny non-compliant resource changes |
| Resource locks | Prevent accidental deletion |
| PR-only changes | All TF changes via pull request |
| Regular scans | Daily scheduled drift detection |

## Manual Drift Detection

```bash
# Single environment
./release/scripts/detect-drift.sh prod

# All environments
./release/scripts/detect-drift.sh all

# GitHub Actions
gh workflow run terraform-drift.yml -f environment=prod
```

## Related

- [State Management](../../deployment/state/README.md)
- [Drift Recovery Runbook](../runbooks/drift-recovery.md)
