# Runbook: Emergency Recovery

Catastrophic failure recovery for Cloud Content Hub infrastructure.

## Activation Criteria

Activate this runbook when:

- Production environment is down due to infrastructure failure
- State storage account is inaccessible or corrupted
- Azure subscription or region is impaired
- Security incident requires immediate infrastructure isolation

## Incident Commander

Platform admin acts as incident commander. All actions are logged in the incident ticket.

## Phase 1 — Stabilize (0–15 minutes)

### 1.1 Declare incident

- Create S1 incident ticket
- Notify #platform-engineering and on-call
- Assign incident commander

### 1.2 Stop ongoing operations

- Cancel running GitHub Actions workflows
- Verify no active Terraform locks
- Do **not** run destroy on any environment

### 1.3 Assess scope

| Check | Command / Action |
|-------|------------------|
| State accessible? | `terraform state list` in affected env |
| Azure resources exist? | Azure Portal / `az resource list` |
| Application impact? | Monitor Application Insights / health endpoints |
| Lock held? | Azure blob lease check |

## Phase 2 — Diagnose (15–30 minutes)

### State corruption

→ Follow [terraform-state-recovery.md](terraform-state-recovery.md)

### Resource failure (single component)

```bash
cd environments/<env>
terraform state show 'module.container_app.azurerm_container_app.this'
terraform taint 'module.container_app.azurerm_container_app.this'
./deployment/scripts/deploy/plan.sh <env>
./deployment/scripts/deploy/apply.sh <env>
```

### Wrong deployment

→ Follow [rollback.md](rollback.md)

### Subscription / region outage

- Check Azure Status: https://status.azure.com
- Activate DR plan (future phase — document RTO/RPO when DR region is provisioned)
- Communicate ETA to stakeholders

## Phase 3 — Recover (30–60 minutes)

### Option A: Forward fix

1. Create `hotfix/*` branch
2. Minimal fix
3. Fast-track validate + plan
4. Apply to stage (quick validation)
5. Tag hotfix release
6. Apply to prod with 2+ approvers

### Option B: Rollback to last known-good

```bash
./deployment/scripts/rollback/rollback.sh prod v<last-good-tag>
```

### Option C: State restore + re-apply

1. Restore state from blob version (see state recovery runbook)
2. Plan — expect minimal changes
3. Apply

## Phase 4 — Verify (60–90 minutes)

- [ ] All `terraform output` values correct
- [ ] Container App health endpoint responds
- [ ] Database connectivity confirmed
- [ ] Application Insights receiving data
- [ ] No active state locks
- [ ] Stakeholders notified of resolution

## Phase 5 — Post-Incident (within 48 hours)

- [ ] Post-incident review (PIR) scheduled
- [ ] Timeline documented
- [ ] Root cause identified
- [ ] Preventive actions tracked
- [ ] Runbooks updated if gaps found

## Communication Template

```
INCIDENT: [S1/S2] Cloud Content Hub Infrastructure
STATUS: Investigating / Mitigating / Resolved
IMPACT: [description]
ACTION: [current step]
ETA: [estimate]
IC: [name]
```

## Related

- [Rollback Runbook](rollback.md)
- [State Recovery](terraform-state-recovery.md)
- [Production Deployment](../../deployment/deploy/prod.md)
