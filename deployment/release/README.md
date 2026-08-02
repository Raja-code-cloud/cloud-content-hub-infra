# Release Strategy

Environment promotion, release tagging, hotfix, and rollback strategy.

## Release Pipeline

```
feature/* ──PR──▶ develop ──▶ dev deploy
                    │
                    ▼ PR
                  main ──▶ stage deploy ──▶ soak ──▶ tag v*.*.* ──▶ prod deploy
                    ▲
              hotfix/* (emergency)
```

## Environment Promotion

### Development

| Trigger | Action |
|---------|--------|
| PR merged to `develop` | CI validates; optional dev deploy |
| Manual | Actions → Terraform Apply → `dev` |

Dev runs the latest `develop` commit. No tag required.

### Staging

| Trigger | Action |
|---------|--------|
| PR merged to `main` | CI validates; stage deploy with approval |
| Release candidate | Tag `v1.2.3-rc.1` for pre-prod testing |

Stage must reflect what will go to production.

### Production

| Trigger | Action |
|---------|--------|
| Tag `v*.*.*` pushed | `release.yml` validates and plans |
| Manual apply | Actions → Terraform Apply → `prod` with 2+ approvers |

Production deploys **only** from release tags.

## Promotion Checklist

### dev → stage

- [ ] All PR CI checks pass on `develop`
- [ ] Dev environment validated (outputs, health checks)
- [ ] PR from `develop` → `main` approved
- [ ] Stage plan reviewed

### stage → prod

- [ ] Stage soak period complete (minimum 24 hours recommended)
- [ ] Stage validation checklist passed
- [ ] Release tag created (`v*.*.*`)
- [ ] `release.yml` workflow succeeded
- [ ] Change advisory approved
- [ ] Rollback plan documented
- [ ] Prod plan reviewed by 2+ reviewers

## Release Tagging

```bash
# 1. Ensure main is stable
git checkout main && git pull

# 2. Create annotated tag
git tag -a v1.2.3 -m "Release v1.2.3 — description of changes"

# 3. Push tag
git push origin v1.2.3
```

### Release artifacts

The `release.yml` workflow produces:

- GitHub Release with auto-generated notes
- Plan artifacts for dev, stage, prod
- Security scan summary
- 90-day artifact retention

## Hotfix Process

For urgent production fixes:

```
1. Branch hotfix/<description> from main
2. Minimal fix — no unrelated changes
3. PR to main with expedited review
4. Merge → plan stage → apply stage (quick validation)
5. Tag v1.2.4-hotfix.1
6. Apply prod from release plan
7. Backport hotfix to develop
```

### Hotfix rules

| Rule | Description |
|------|-------------|
| Minimal scope | Fix only the incident |
| Same module interfaces | No breaking variable changes |
| Tag required | Even for hotfix, tag before prod apply |
| Backport mandatory | Merge to `develop` within 24 hours |
| Post-incident review | Within 48 hours |

## Rollback

See [rollback/README.md](../rollback/README.md).

| Environment | Rollback Method | Approval |
|-------------|-----------------|----------|
| dev | Config rollback or destroy/recreate | Operator |
| stage | Tag-based rollback | 1 reviewer |
| prod | Tag-based rollback to previous release | 2 reviewers |

```bash
./deployment/scripts/rollback/rollback.sh prod v1.2.2
```

## Release Calendar (Recommended)

| Activity | Frequency |
|----------|-----------|
| Dev deploy | Continuous (on merge to develop) |
| Stage deploy | Weekly or per release |
| Prod release | Bi-weekly or monthly |
| Provider upgrade | Quarterly |
| Terraform upgrade | Quarterly |
| Security scan review | Weekly |

## Branch → Environment Mapping

| Branch | CI Trigger | Deploy Target | Tag Required |
|--------|-----------|---------------|--------------|
| `feature/*` | PR checks only | None | No |
| `develop` | Push + PR | dev | No |
| `main` | Push + PR | stage | No |
| `v*.*.*` | Tag push | prod | Yes |
| `hotfix/*` | PR to main | stage → prod | Yes |

## Related

- [Versioning](../versioning/README.md)
- [Production Deployment](../deploy/prod.md)
- [Approval Gates](../deploy/approval-gates.md)
- [CI/CD Architecture](../../docs/cicd/README.md)
