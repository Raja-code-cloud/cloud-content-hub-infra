# Destroy

Safe infrastructure destruction procedures.

## Policy

| Environment | Destroy Allowed | Method |
|-------------|-----------------|--------|
| dev | Yes | Script or GitHub Actions with confirmation |
| stage | Yes | Script or GitHub Actions with confirmation |
| prod | **No** | Blocked in CI; manual DR only with executive approval |

Production destroy is **permanently blocked** in `terraform-destroy.yml`. Any production teardown requires a formal decommission project outside standard workflows.

## Pre-Destroy Checklist

- [ ] Change ticket approved (stage/prod)
- [ ] Dependent applications decommissioned
- [ ] Data backed up (PostgreSQL, Key Vault secrets, storage)
- [ ] State file backed up (`terraform state pull > backup.tfstate`)
- [ ] Team notified
- [ ] Confirmation phrase prepared

## Destruction Procedure

### GitHub Actions (preferred)

```
Actions → Terraform Destroy
  environment: dev
  confirmation: destroy-dev
```

Workflow guards:

1. Rejects `prod` environment
2. Requires exact confirmation phrase `destroy-<environment>`
3. Runs pre-destroy validation
4. GitHub Environment approval gate

### Local script

```bash
./deployment/scripts/destroy/destroy.sh dev
```

The script requires typing `destroy-dev` (or `destroy-stage`) to confirm.

## Destroy Order

Terraform destroys resources in reverse dependency order automatically. Expected destruction sequence for this platform:

```
container_app → key_vault_secrets → role_assignment → container_app_environment
→ postgresql → storage → key_vault → acr → managed_identity
→ application_insights → log_analytics → resource_group
```

## Post-Destroy

1. Verify state is empty: `terraform state list` (should return nothing)
2. Archive state backup for audit retention
3. Optionally delete state blob (only after verification)
4. Remove GitHub Environment secrets if environment is permanently decommissioned

## Production Decommission (Exception Process)

Production infrastructure teardown is **not** automated. Required steps:

1. Executive and platform architect approval
2. Full data export and verification
3. Change advisory board sign-off
4. Manual `terraform destroy` by two platform admins with recorded session
5. State blob archived, not deleted, for 7 years (compliance)
6. Post-decommission audit

## Safeguards

| Safeguard | Implementation |
|-----------|----------------|
| Prod block | Workflow guard rejects `prod` |
| Confirmation phrase | Must type `destroy-<env>` |
| Approval gate | GitHub Environment reviewers |
| State backup | Script creates pre-destroy backup |
| Audit log | GitHub Actions artifact retained 30 days |

## Script

```bash
# Dry run (plan destroy)
./deployment/scripts/destroy/destroy.sh dev --plan-only

# Execute destroy
./deployment/scripts/destroy/destroy.sh dev
```

## Related

- [Destroy Script](../scripts/destroy/destroy.sh)
- [State Management](../state/README.md)
