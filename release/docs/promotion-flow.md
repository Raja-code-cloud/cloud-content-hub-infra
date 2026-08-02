# Promotion Flow

Infrastructure **must** flow through environments in order. Skipping environments or deploying directly to production is prohibited.

## Canonical Flow

```
Feature Branch
      │
      ▼ PR + CI
  Development          ← automatic promotion
      │
      ▼ merge to main + approval
    Stage              ← manual approval (1 reviewer)
      │
      ▼ tag + 2-person approval
  Production           ← release promotion only
```

## Forbidden Paths

| Path | Status | Reason |
|------|--------|--------|
| Feature → Stage | **Blocked** | Must validate in dev first |
| Feature → Production | **Blocked** | Must validate in dev and stage |
| Main → Production (no tag) | **Blocked** | Production requires release tag |
| Direct `terraform-apply` → prod | **Blocked** | Use `release-promotion.yml` |
| Skip stage soak | **Blocked** | Checklist required |

## Branch and Ref Mapping

| Git Ref | Valid Promotion Target | Tag Required |
|---------|------------------------|--------------|
| `feature/*` | None (PR only) | No |
| `develop` | dev | No |
| `main` | stage | No |
| `v*.*.*` | prod | Yes |
| `v*.*.*-hotfix.*` | prod (emergency) | Yes |
| `v*.*.*-rc.*` | stage (RC testing) | Yes |

## Promotion Workflow Inputs

### Development

```yaml
promotion_target: dev
git_ref: develop
```

### Stage

```yaml
promotion_target: stage
git_ref: main
release_tag: ""  # optional RC tag for pre-prod testing
```

### Production

```yaml
promotion_target: prod
git_ref: v1.2.3
release_tag: v1.2.3
```

## Workflow Execution Model

Each promotion executes as a **single workflow run**:

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Quality    │───▶│     Plan     │───▶│   Approve    │───▶│    Apply     │
│    Gates     │    │  (artifact)  │    │  (env gate)  │    │ (same plan)  │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

The plan artifact from step 2 is the **only** plan applied in step 4. No re-planning occurs after approval.

## GitHub Environment Protection

Configure in **Settings → Environments**:

| Environment | Required Reviewers | Wait Timer | Deployment Branches | Allowed Workflows |
|-------------|-------------------|------------|---------------------|-------------------|
| `dev` | 0 | None | `develop`, `main` | `release-promotion.yml` |
| `stage` | 1+ | 5 min (optional) | `main`, `release/*` | `release-promotion.yml` |
| `prod` | 2+ | 15 min (recommended) | Tags only | `release-promotion.yml`, `release-emergency.yml` |

**Do not** grant `terraform-apply.yml` access to the `prod` environment.

## Promotion Checklists

| Transition | Checklist |
|------------|-----------|
| dev → stage | [checklists/dev-to-stage.md](../checklists/dev-to-stage.md) |
| stage → prod | [checklists/stage-to-prod.md](../checklists/stage-to-prod.md) |

## Rollback at Every Stage

| Stage | Rollback Method |
|-------|-----------------|
| Development | Re-promote previous `develop` commit or config rollback |
| Stage | Re-promote previous `main` commit or release tag |
| Production | `release-rollback.yml` to previous release tag |

See [rollback.md](rollback.md).

## Related

- [Approval Process](approval-process.md)
- [Artifact Strategy](artifact-strategy.md)
- [Normal Promotion Runbook](../runbooks/normal-promotion.md)
