# Rollback

Rollback strategy for failed or undesired infrastructure deployments.

## Rollback Philosophy

Terraform rollback is **forward recovery** — you apply a known-good configuration rather than reversing state manually. There is no native `terraform rollback` command.

| Principle | Description |
|-----------|-------------|
| **Plan before rollback** | Always generate a plan from the target commit |
| **Preserve state** | Never edit state by hand unless state recovery runbook applies |
| **Same backend** | Rollback uses the same remote state file |
| **Audit everything** | Log commit, plan, and apply for every rollback |

## Rollback Decision Tree

```
Deployment failed?
├── Apply never started ──▶ Fix code/config, re-plan, re-apply
├── Apply partial failure ──▶ terraform apply (retry) OR taint + apply
├── Wrong config deployed ──▶ Checkout previous commit, plan, apply
├── State corrupted ──▶ State recovery runbook
└── Azure resource broken ──▶ Targeted fix OR import + apply
```

## Rollback Strategies

### 1. Configuration rollback (preferred)

Revert to a known-good Git commit or release tag:

```bash
git checkout v1.2.2
./deployment/scripts/deploy/plan.sh prod
# Review plan — should show changes back to v1.2.2 state
./deployment/scripts/deploy/apply.sh prod
```

### 2. Plan artifact rollback

If the previous plan artifact is available:

```bash
# GitHub Actions: use use_plan_artifact from previous successful run
# Local: re-apply previous tfplan if still valid (same state, same providers)
./deployment/scripts/deploy/apply.sh dev --plan-file ./tfplan.previous
```

**Warning:** Plan files are invalid if state or provider versions changed.

### 3. Targeted resource rollback

For a single failed resource:

```bash
cd environments/dev
terraform taint 'module.container_app.azurerm_container_app.this'
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

### 4. State-level rollback

When state file was corrupted or incorrectly modified:

See [state/README.md](../state/README.md) and [State Recovery Runbook](../../docs/runbooks/terraform-state-recovery.md).

## Failed Deployment Recovery

### Apply interrupted mid-run

1. **Do not** run destroy
2. Check state lock — wait or break lock (see state management)
3. Run `terraform plan` — Terraform reconciles partial apply
4. Apply remaining changes

```bash
./deployment/scripts/deploy/plan.sh dev
./deployment/scripts/deploy/apply.sh dev
```

### Provider error during apply

1. Capture error output from apply log
2. Fix provider/config issue in code
3. Re-validate and re-plan
4. Apply

### Azure resource in failed state

1. Identify resource in Azure Portal or `terraform state show <address>`
2. Fix resource in Azure (if safe) or remove from state and re-import
3. Plan and apply

## Terraform State Recovery

| Scenario | Procedure |
|----------|-----------|
| State lock stuck | Break blob lease (see state/README.md) |
| State file corrupted | Restore from blob version / backup |
| Accidental state delete | Restore from soft delete (storage account) |
| Drift from manual changes | `terraform plan` → apply or refresh |

Full procedure: [terraform-state-recovery.md](../../docs/runbooks/terraform-state-recovery.md).

## State Locking During Rollback

The azurerm backend uses Azure blob leases for locking.

| Situation | Action |
|-----------|--------|
| Lock held by failed CI job | Wait for lease expiry (default ~20 min) or break lease |
| Lock held by operator | Coordinate — never force-unlock without confirmation |
| Concurrent rollback attempts | Blocked by lock — one operator at a time |

```bash
# Check lock info (Azure CLI)
az storage blob show --account-name <storage> --container-name tfstate \
  --name dev.tfstate --query 'properties.lease'
```

## Manual Rollback

When automated rollback is insufficient:

1. Document current state (`terraform state list > /tmp/state-before.txt`)
2. Platform admin reviews with on-call
3. Execute manual steps from state recovery runbook
4. Post-incident review within 24 hours

## Disaster Recovery

For catastrophic failure (subscription loss, region outage):

1. Activate DR runbook: [emergency-recovery.md](../../docs/runbooks/emergency-recovery.md)
2. Restore state from geo-redundant storage backup
3. Bootstrap replacement environment in DR region (future phase)
4. Apply from last known-good release tag

## Environment-Specific Rollback

| Environment | Risk | Rollback Approach |
|-------------|------|-----------------|
| dev | Low | Direct config rollback; destroy/recreate acceptable |
| stage | Medium | Config rollback; notify release engineer |
| prod | High | Tag-based rollback only; 2+ approvers; no destroy |

## Script

```bash
./deployment/scripts/rollback/rollback.sh dev v1.2.2
```

See script help for options.

## Related

- [State Management](../state/README.md)
- [Rollback Runbook](../../docs/runbooks/rollback.md)
- [Emergency Recovery](../../docs/runbooks/emergency-recovery.md)
