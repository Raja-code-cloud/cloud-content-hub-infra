# Artifact Strategy

Immutable Terraform plan artifact promotion for governed infrastructure releases.

## Principle: Plan Once, Review, Promote, Apply

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  PLAN   │────▶│ REVIEW  │────▶│ APPROVE │────▶│  APPLY  │
│ (once)  │     │ (human) │     │ (gate)  │     │ (same)  │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
     │                                                    │
     └──────────── immutable tfplan artifact ─────────────┘
```

**Never regenerate a production plan after approval.** If infrastructure or code changes after approval, cancel the workflow and start a new promotion.

## Artifact Types

| Artifact | Contents | Retention |
|----------|----------|-----------|
| `tfplan-<env>-<run_id>` | Binary plan file | 90 days (prod), 30 days (dev/stage) |
| `plan.txt` | Human-readable plan | Same as tfplan |
| `plan.log` | Full plan output log | Same as tfplan |
| `promotion-record.json` | Audit metadata | 90 days |
| `quality-gates-summary.md` | Gate results | 30 days |
| `drift-report-<env>-<date>` | Drift detection output | 30 days |

## Per-Environment Plans

Each environment has **separate Terraform state**. Plan artifacts are environment-specific:

| Environment | Plan Scope | Git Ref |
|-------------|------------|---------|
| dev | `environments/dev` state | `develop` commit |
| stage | `environments/stage` state | `main` commit |
| prod | `environments/prod` state | Release tag (`v*.*.*`) |

A stage plan **cannot** be applied to production. Production promotion generates its own plan at the release tag.

## Promotion Workflow Artifact Flow

Within a single `release-promotion.yml` run:

```yaml
jobs:
  quality-gates:
    # Validates at pinned git ref

  plan:
    needs: quality-gates
    outputs:
      artifact_name: tfplan-${{ target }}-${{ github.run_id }}
    steps:
      - checkout at git_ref
      - terraform plan -out=tfplan
      - upload artifact

  apply:
    needs: plan
    environment: ${{ promotion_target }}  # approval gate here
    steps:
      - download artifact from SAME run
      - terraform apply tfplan  # no re-plan
```

## Artifact Metadata

Each promotion record includes:

```json
{
  "promotion_id": "<workflow_run_id>",
  "promotion_target": "prod",
  "git_ref": "v1.2.3",
  "git_commit": "<sha>",
  "release_tag": "v1.2.3",
  "terraform_version": "1.13.0",
  "provider_versions": { "azurerm": "5.0.1" },
  "plan_artifact": "tfplan-prod-<run_id>",
  "plan_checksum": "<sha256>",
  "approved_by": ["reviewer1", "reviewer2"],
  "approved_at": "<iso8601>",
  "promoted_at": "<iso8601>"
}
```

Template: [templates/promotion-record.json.tpl](../templates/promotion-record.json.tpl)

## Artifact Integrity

| Control | Implementation |
|---------|----------------|
| Immutability | GitHub artifact from single workflow run |
| Checksum | SHA-256 of `tfplan` recorded in audit log |
| Pinning | Checkout at exact git ref / tag |
| Provider lock | `.terraform.lock.hcl` from pinned commit |
| No re-plan | Apply job fails if artifact missing |

## Stale Plan Detection

A plan is considered stale if:

- More than 4 hours elapsed since plan generation (prod)
- State changed (another apply completed)
- Provider lock file changed
- Git ref moved (new commits on tag — should not happen with annotated tags)

If stale, **cancel and re-run promotion** from the beginning.

## Release Tag Artifacts

The `release.yml` workflow (on tag push) produces:

- Validation evidence (fmt, validate, security)
- Plan artifacts for all environments (reference only)
- GitHub Release with notes

Tag validation plans are **informational**. Production apply uses the plan from `release-promotion.yml`, not `release.yml`.

## Local Parity

```bash
# Plan and save artifact locally
./deployment/scripts/deploy/plan.sh prod

# Apply saved plan (after review)
./deployment/scripts/deploy/apply.sh prod
```

For governed promotion, use:

```bash
./release/scripts/promote.sh prod v1.2.3
```

## Related

- [Auditability](auditability.md)
- [Promotion Flow](promotion-flow.md)
