# Release Lifecycle

End-to-end lifecycle for infrastructure changes in **cloud-content-hub-infra**.

## Lifecycle Overview

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Design    │──▶│  Implement  │──▶│   Validate  │──▶│   Promote   │──▶│   Operate   │
│  ADR/Design │   │  PR/Module  │   │  CI Gates   │   │  Dev→Stg→Pr │   │  Monitor    │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
                                           │                  │
                                           ▼                  ▼
                                    ┌─────────────┐   ┌─────────────┐
                                    │   Reject    │   │  Rollback   │
                                    │  Fix & PR   │   │  if needed  │
                                    └─────────────┘   └─────────────┘
```

## Phase 1: Design

| Activity | Owner | Output |
|----------|-------|--------|
| Architecture review | Platform architect | ADR (if significant) |
| Impact assessment | Release engineer | Change scope document |
| Cost estimate | FinOps | Cost review notes |

## Phase 2: Implement

| Branch | Purpose | Deploy Target |
|--------|---------|---------------|
| `feature/*` | Infrastructure change | None (PR checks only) |
| `develop` | Integration branch | Development |
| `main` | Release candidate | Stage |
| `hotfix/*` | Emergency fix | Stage → Prod |
| `v*.*.*` tag | Immutable release | Production |

### Pull request requirements

- All CI checks pass (`terraform-pr.yml`)
- Plan output reviewed on PR
- No secrets in diff
- Module interface changes documented

## Phase 3: Validate

Automated gates run on every PR and before every promotion:

1. `terraform fmt -check`
2. `terraform validate` (all environments)
3. TFLint
4. terraform-docs
5. Security scans (Checkov, tfsec, Trivy)
6. `terraform plan` (target environment)
7. Module tests (where applicable)

See [quality-gates.md](quality-gates.md).

## Phase 4: Promote

### Development (automatic)

| Trigger | Workflow | Approval |
|---------|----------|----------|
| Merge to `develop` | `release-promotion.yml` (dev) | None |
| Manual dispatch | `release-promotion.yml` (dev) | None |

### Stage (manual approval)

| Trigger | Workflow | Approval |
|---------|----------|----------|
| Merge to `main` | `release-promotion.yml` (stage) | 1 reviewer |
| Manual dispatch | `release-promotion.yml` (stage) | 1 reviewer |

**Soak period:** Minimum 24 hours recommended before production promotion.

### Production (two-person approval)

| Trigger | Workflow | Approval |
|---------|----------|----------|
| Release tag + promotion | `release-promotion.yml` (prod) | 2 reviewers |

**Direct production deployment is prohibited.** The `terraform-apply.yml` workflow blocks `prod` targets.

## Phase 5: Operate

Post-promotion activities:

| Activity | Frequency | Tool |
|----------|-----------|------|
| Drift detection | Daily (scheduled) | `terraform-drift.yml` |
| Cost review | Weekly | Azure Cost Management |
| State backup verification | Per apply | Blob versioning |
| Audit log review | Per promotion | GitHub Actions artifacts |

## Release Cadence (Recommended)

| Activity | Frequency |
|----------|-----------|
| Dev promotion | Continuous (on merge to develop) |
| Stage promotion | Weekly or per release |
| Production release | Bi-weekly or monthly |
| Hotfix | As needed (emergency workflow) |
| Drift scan | Daily |
| Provider upgrade | Quarterly |

## Lifecycle States

| State | Description | Next Action |
|-------|-------------|-------------|
| `draft` | Feature branch, PR open | Complete CI checks |
| `validated` | PR merged, CI passed | Promote to dev |
| `dev-deployed` | Dev environment updated | Merge to main |
| `stage-candidate` | On main, awaiting stage promotion | Run stage promotion |
| `stage-deployed` | Stage environment updated | Soak + checklist |
| `release-tagged` | Tag created, release validated | Promote to prod |
| `prod-deployed` | Production updated | Monitor + audit |
| `rolled-back` | Previous release restored | Post-incident review |

## Related

- [Promotion Flow](promotion-flow.md)
- [Change Management](change-management.md)
- [Normal Promotion Runbook](../runbooks/normal-promotion.md)
