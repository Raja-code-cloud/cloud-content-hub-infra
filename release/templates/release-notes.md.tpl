## Release {{RELEASE_TAG}}

**Date:** {{RELEASE_DATE}}
**Git Commit:** {{GIT_COMMIT}}
**Terraform Version:** {{TF_VERSION}}
**Promotion Target:** {{PROMOTION_TARGET}}

### Summary

{{SUMMARY}}

### Changes

{{CHANGELOG}}

### Quality Gates

| Gate | Result |
|------|--------|
| Format | {{GATE_FORMAT}} |
| Validate | {{GATE_VALIDATE}} |
| Lint | {{GATE_LINT}} |
| Security | {{GATE_SECURITY}} |
| Plan | {{GATE_PLAN}} |

### Module Compatibility

| Component | Version |
|-----------|---------|
| Terraform | {{TF_VERSION}} |
| azurerm | {{PROVIDER_AZURERM}} |

### Rollback

Previous release: {{PREVIOUS_TAG}}

```bash
gh workflow run release-rollback.yml \
  -f environment={{PROMOTION_TARGET}} \
  -f release_tag={{PREVIOUS_TAG}} \
  -f confirmation=rollback-{{PROMOTION_TARGET}}
```

### Approvers

{{APPROVERS}}
