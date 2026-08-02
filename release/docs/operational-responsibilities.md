# Operational Responsibilities

RACI matrix and operational responsibilities for infrastructure release management.

## Roles

| Role | Description |
|------|-------------|
| **Developer** | Implements infrastructure changes via PR |
| **Release Engineer** | Orchestrates promotions and releases |
| **Platform Engineer** | Maintains modules, environments, CI/CD |
| **Platform Lead** | Approves production changes; owns framework |
| **FinOps Analyst** | Reviews cost impact of changes |
| **Security Engineer** | Reviews security scan results |
| **On-Call Engineer** | Handles incidents and emergency changes |

## RACI Matrix

| Activity | Developer | Release Engineer | Platform Engineer | Platform Lead | FinOps | Security |
|----------|:---------:|:----------------:|:-----------------:|:-------------:|:------:|:--------:|
| Feature PR | R | C | C | I | I | C |
| Dev promotion | C | R | A | I | — | — |
| Stage promotion | I | R | A | C | C | C |
| Prod promotion | I | R | C | A | C | C |
| Release tagging | I | R | C | A | I | I |
| Emergency change | C | R | A | A | I | C |
| Rollback | I | R | A | A | I | I |
| Drift remediation | C | R | A | I | — | C |
| Provider upgrade | C | R | A | A | I | C |
| Quality gate failure | R | A | A | I | — | C |

**R** = Responsible, **A** = Accountable, **C** = Consulted, **I** = Informed

## Environment Ownership

| Environment | Primary Owner | Backup | Approval |
|-------------|---------------|--------|----------|
| Development | Platform Engineer | Release Engineer | Automatic |
| Stage | Release Engineer | Platform Engineer | 1 reviewer |
| Production | Platform Lead | Release Engineer | 2 reviewers |

## On-Call Responsibilities

| Scenario | Action | Escalation |
|----------|--------|------------|
| Failed promotion | Follow failed deployment runbook | Platform Lead |
| Drift detected (prod) | Assess within 4 hours | Platform Lead |
| Emergency incident | Trigger emergency workflow | Incident Commander |
| State lock | Verify no active run; force-unlock if stale | Platform Engineer |
| Security gate failure | Do not bypass; fix and re-run | Security Engineer |

## Shift Handoff

On-call handoff must include:

- [ ] Pending promotions in progress
- [ ] Recent failed workflow runs
- [ ] Open drift reports
- [ ] Active emergency changes
- [ ] Scheduled maintenance windows

## Training Requirements

| Role | Required Training |
|------|-------------------|
| Release Engineer | Promotion runbooks, quality gates, rollback |
| Platform Engineer | Full deployment framework, state management |
| Platform Lead | Approval criteria, emergency procedures |
| On-Call | Failed deployment, drift recovery, rollback |

## Related

- [Lifecycle](lifecycle.md)
- [Approval Process](approval-process.md)
- [Runbooks](../runbooks/)
