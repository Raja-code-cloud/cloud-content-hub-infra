# Quality Gates

Pre-promotion quality requirements for infrastructure releases.

## Gate Summary

All gates must pass before promotion to stage or production. Development promotion requires all automated gates.

| # | Gate | Tool | Dev | Stage | Prod |
|---|------|------|:---:|:-----:|:----:|
| 1 | Format | `terraform fmt -check` | ✓ | ✓ | ✓ |
| 2 | Validate | `terraform validate` | ✓ | ✓ | ✓ |
| 3 | Lint | TFLint | ✓ | ✓ | ✓ |
| 4 | Documentation | terraform-docs | ✓ | ✓ | ✓ |
| 5 | Security scan | Checkov | ✓ | ✓ | ✓ |
| 6 | Security scan | tfsec | ✓ | ✓ | ✓ |
| 7 | Security scan | Trivy | ✓ | ✓ | ✓ |
| 8 | Compliance | Policy module validation | ✓ | ✓ | ✓ |
| 9 | Plan | `terraform plan` | ✓ | ✓ | ✓ |
| 10 | Module tests | Module validate matrix | ✓ | ✓ | ✓ |
| 11 | Integration tests | Environment outputs check | — | ✓ | ✓ |
| 12 | Cost review | Manual FinOps checklist | — | ✓ | ✓ |
| 13 | Checklist | Promotion checklist | — | ✓ | ✓ |

## Automated Gate Details

### Format

```bash
terraform fmt -check -recursive
```

Workflow: `terraform-format.yml`

### Validate

```bash
terraform init -backend=false
terraform validate
```

Workflow: `terraform-validate.yml` (all environments + module matrix)

### Lint

```bash
tflint --init
tflint --recursive
```

Workflow: `terraform-lint.yml`

### Security

```bash
checkov -d . --framework terraform
tfsec .
trivy config .
```

Workflow: `terraform-security.yml`

**Blocking severities:** HIGH, CRITICAL

### Plan

```bash
terraform plan -out=tfplan
```

Exit code 0 (no changes) or 2 (changes present) are acceptable. Exit code 1 is a failure.

## Manual Gate Details

### Integration tests

Verify after stage deployment:

- [ ] Resource group exists and tagged
- [ ] Key Vault accessible
- [ ] Container App Environment healthy
- [ ] PostgreSQL connectivity (if applicable)
- [ ] Application Insights receiving telemetry
- [ ] No unexpected plan changes on re-run

### Cost review

Before stage → prod promotion:

- [ ] Estimated monthly cost within budget
- [ ] No unexpected SKU upgrades
- [ ] Budget alerts configured
- [ ] FinOps sign-off (for significant changes)

### Promotion checklists

- [dev-to-stage](../checklists/dev-to-stage.md)
- [stage-to-prod](../checklists/stage-to-prod.md)

## Running Gates Locally

```bash
# All gates for an environment
./release/scripts/quality-gates.sh stage

# Individual deployment validation
./deployment/scripts/validate/run-all.sh stage
```

## Gate Bypass

| Gate | Bypass Allowed |
|------|----------------|
| Format, Validate, Lint | Never |
| Security (HIGH/CRITICAL) | Never |
| Security (LOW/MEDIUM) | Exception with ticket (stage only) |
| Cost review | Never for prod |
| Checklist | Never for prod |

Emergency workflow may expedite but **never bypasses** security gates.

## CI Integration

Gates are orchestrated by:

| Context | Workflow |
|---------|----------|
| Pull request | `terraform-pr.yml` |
| Promotion | `release-promotion.yml` (quality-gates job) |
| Release tag | `release.yml` |
| Pre-rollback | `release-rollback.yml` (validate job) |

## Related

- [Deployment Validation](../../deployment/validate/README.md)
- [Approval Process](approval-process.md)
