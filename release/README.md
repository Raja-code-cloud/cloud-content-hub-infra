# Release and Promotion Framework

Enterprise release engineering for **cloud-content-hub-infra**.

This framework defines **how infrastructure is promoted** across environments. It does not modify Terraform modules or environment compositions — it orchestrates quality gates, approvals, immutable plan artifacts, audit records, and rollback procedures.

## Philosophy

| Principle | Description |
|-----------|-------------|
| **Linear promotion** | Changes flow Dev → Stage → Prod; never skip environments |
| **No direct production** | Production deploys only via the release promotion pipeline |
| **Plan once, apply once** | Approved production plans are immutable; never re-plan after approval |
| **Fail closed** | Quality gates block promotion; emergency changes use a separate workflow |
| **Full auditability** | Every promotion records who, when, what, and which artifacts |
| **CI/CD parity** | Local scripts mirror GitHub Actions workflows |

## Promotion Model

```
feature/* ──PR──▶ develop ──auto──▶ Development
                    │
                    ▼ merge
                  main ──approve──▶ Stage
                    │
                    ▼ tag v*.*.* + 2-person approve
               Production
```

Direct deployment to Production is **blocked**. See [docs/promotion-flow.md](docs/promotion-flow.md).

## Directory Structure

```
release/
├── README.md                 # This file
├── docs/                     # Framework documentation
├── runbooks/                 # Operational procedures
├── scripts/                  # Promotion, drift, rollback scripts
├── checklists/               # Pre-promotion checklists
└── templates/                # Release notes, audit records, change requests
```

## Quick Reference

| Activity | Workflow / Script | Approval |
|----------|-------------------|----------|
| PR validation | `terraform-pr.yml` | Automated |
| Promote to dev | `release-promotion.yml` (target: dev) | Automatic |
| Promote to stage | `release-promotion.yml` (target: stage) | 1 reviewer |
| Promote to prod | `release-promotion.yml` (target: prod) | 2 reviewers |
| Emergency prod | `release-emergency.yml` | 2 reviewers + ticket |
| Rollback | `release-rollback.yml` | Per environment |
| Drift detection | `terraform-drift.yml` | Scheduled + manual |
| Release tag | `release.yml` (on tag push) | Validates only |

## Quality Gates (Pre-Promotion)

All gates must pass before promotion proceeds:

| Gate | Tool | Blocking |
|------|------|----------|
| Format | `terraform fmt -check` | Yes |
| Validate | `terraform validate` | Yes |
| Lint | TFLint | Yes |
| Security | Checkov, tfsec, Trivy | Yes (HIGH/CRITICAL) |
| Compliance | Policy module tests | Yes |
| Plan | `terraform plan` | Yes |
| Cost review | Manual checklist (stage/prod) | Yes (stage/prod) |
| Integration tests | Environment validation | Yes (stage/prod) |

See [docs/quality-gates.md](docs/quality-gates.md).

## Approval Gates

| Environment | Approval | Workflow |
|-------------|----------|----------|
| Development | Automatic | `release-promotion.yml` |
| Stage | Manual (1 reviewer) | `release-promotion.yml` |
| Production | Two-person approval | `release-promotion.yml` |
| Emergency | Two-person + ticket | `release-emergency.yml` |

See [docs/approval-process.md](docs/approval-process.md).

## Artifact Strategy

1. **Plan** — Generate `tfplan` at a pinned git ref for the target environment
2. **Review** — Human reviewers inspect plan output and cost impact
3. **Approve** — GitHub Environment protection gate
4. **Apply** — Apply the **same** plan artifact from the same workflow run

Production plans are never regenerated after approval. See [docs/artifact-strategy.md](docs/artifact-strategy.md).

## Getting Started

### Normal promotion (stage)

```bash
# 1. Merge feature to develop, validate dev
# 2. Merge develop to main
# 3. Trigger promotion via GitHub Actions
gh workflow run release-promotion.yml \
  -f promotion_target=stage \
  -f git_ref=main

# Or locally:
./release/scripts/promote.sh stage main
```

### Production release

```bash
# 1. Complete stage soak and checklist
# 2. Create release tag
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 3. Promote to production (plan → approve → apply in one workflow)
gh workflow run release-promotion.yml \
  -f promotion_target=prod \
  -f git_ref=v1.2.3 \
  -f release_tag=v1.2.3
```

### Rollback

```bash
gh workflow run release-rollback.yml \
  -f environment=prod \
  -f release_tag=v1.2.2 \
  -f confirmation=rollback-prod
```

## Relationship to Deployment Framework

| Framework | Purpose |
|-----------|---------|
| `deployment/` | Bootstrap, plan/apply scripts, state management, destroy |
| `release/` | Promotion pipeline, approvals, artifacts, audit, change management |

Local operators use `deployment/scripts/` for day-to-day operations and `release/scripts/` for governed promotions.

## Documentation Index

| Document | Description |
|----------|-------------|
| [Lifecycle](docs/lifecycle.md) | End-to-end release lifecycle |
| [Promotion Flow](docs/promotion-flow.md) | Environment promotion paths |
| [Approval Process](docs/approval-process.md) | Manual and automated gates |
| [Artifact Strategy](docs/artifact-strategy.md) | Immutable plan promotion |
| [Drift Detection](docs/drift-detection.md) | Scheduled and manual drift |
| [Versioning](docs/versioning.md) | Semantic versioning and compatibility |
| [Rollback](docs/rollback.md) | Rollback and recovery strategy |
| [Change Management](docs/change-management.md) | Standard, emergency, hotfix |
| [Quality Gates](docs/quality-gates.md) | Pre-promotion requirements |
| [Auditability](docs/auditability.md) | Audit trail requirements |
| [Operational Responsibilities](docs/operational-responsibilities.md) | RACI matrix |

## Runbooks

| Runbook | Path |
|---------|------|
| Normal promotion | [runbooks/normal-promotion.md](runbooks/normal-promotion.md) |
| Emergency promotion | [runbooks/emergency-promotion.md](runbooks/emergency-promotion.md) |
| Rollback | [runbooks/rollback.md](runbooks/rollback.md) |
| Failed deployment | [runbooks/failed-deployment.md](runbooks/failed-deployment.md) |
| Drift recovery | [runbooks/drift-recovery.md](runbooks/drift-recovery.md) |

## Related

- [Deployment Framework](../deployment/README.md)
- [CI/CD Architecture](../docs/cicd/README.md)
- [Deployment Runbooks](../docs/runbooks/README.md)
