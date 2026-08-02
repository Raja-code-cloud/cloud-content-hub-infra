# Runbook: Normal Promotion

Promote infrastructure changes through Development → Stage → Production.

## Prerequisites

- Platform engineer or release engineer access
- GitHub Actions workflow dispatch permission
- Environment approval permissions (stage: 1, prod: 2)

## Promotion Paths

### 1. Development (automatic)

**When:** After merge to `develop`

```bash
gh workflow run release-promotion.yml \
  -f promotion_target=dev \
  -f git_ref=develop
```

**Approval:** None (automated gates only)

**Verify:**
- Workflow succeeds
- Dev outputs correct
- No unexpected drift

### 2. Stage (manual approval)

**When:** After merge to `main`, dev validated

**Checklist:** [dev-to-stage.md](../checklists/dev-to-stage.md)

```bash
gh workflow run release-promotion.yml \
  -f promotion_target=stage \
  -f git_ref=main
```

**Approval:** 1 reviewer via GitHub Environment `stage`

**Verify:**
- Plan artifact reviewed before approval
- Apply succeeds
- Stage integration tests pass
- Start soak period (24h minimum recommended)

### 3. Production (two-person approval)

**When:** After stage soak, release tag created

**Checklist:** [stage-to-prod.md](../checklists/stage-to-prod.md)

```bash
# Create tag first
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# Wait for release.yml validation

# Promote
gh workflow run release-promotion.yml \
  -f promotion_target=prod \
  -f git_ref=v1.2.3 \
  -f release_tag=v1.2.3
```

**Approval:** 2 reviewers via GitHub Environment `prod`

**Verify:**
- Plan artifact reviewed by both approvers
- Apply succeeds
- Health checks pass
- Audit record uploaded

## Workflow Steps (Internal)

1. **validate-inputs** — Enforce promotion path rules
2. **quality-gates** — fmt, validate, lint, security
3. **plan** — Generate immutable tfplan at git ref
4. **apply** — Environment approval gate → apply same plan
5. **audit** — Upload promotion-record.json

## Troubleshooting

| Issue | Action |
|-------|--------|
| Quality gate failure | Fix issue; re-run from step 1 |
| Plan shows unexpected changes | Stop; investigate drift or code issue |
| Approval timeout | Re-run promotion (plan may be stale) |
| Apply failure | See [failed-deployment.md](failed-deployment.md) |

## Local Alternative

```bash
./release/scripts/promote.sh stage main
./release/scripts/promote.sh prod v1.2.3
```

## Related

- [Promotion Flow](../docs/promotion-flow.md)
- [Artifact Strategy](../docs/artifact-strategy.md)
