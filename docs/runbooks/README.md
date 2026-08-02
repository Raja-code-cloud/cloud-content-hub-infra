# Runbooks

Operational runbooks for Cloud Content Hub infrastructure.

## Index

| Runbook | Description | Severity |
|---------|-------------|----------|
| [New Environment](new-environment.md) | Bootstrap and first deploy for a new environment | Standard |
| [Deploy](deploy.md) | Standard deployment procedure (dev/stage/prod) | Standard |
| [Rollback](rollback.md) | Recover from failed or undesired deployment | S2–S3 |
| [Emergency Recovery](emergency-recovery.md) | Catastrophic failure response | S1 |
| [Terraform State Recovery](terraform-state-recovery.md) | State corruption, locks, and restore | S1–S2 |
| [Provider Upgrade](provider-upgrade.md) | Safe provider version upgrades | Standard |

## Deployment Framework

All runbooks reference the enterprise deployment framework:

```
deployment/
├── bootstrap/    — Init and backend setup
├── deploy/       — Plan and apply
├── rollback/     — Rollback strategy
├── destroy/      — Safe teardown
├── validate/     — Quality gates
├── state/        — State management
├── versioning/   — Version policy
├── release/      — Promotion strategy
└── scripts/      — Orchestration scripts
```

Start here: [deployment/README.md](../../deployment/README.md)

## Quick Reference

| I need to... | Runbook / Script |
|--------------|------------------|
| Set up a new environment | [new-environment.md](new-environment.md) |
| Deploy infrastructure | [deploy.md](deploy.md) → `deployment/scripts/deploy/` |
| Roll back a deployment | [rollback.md](rollback.md) → `deployment/scripts/rollback/rollback.sh` |
| Fix a stuck state lock | [terraform-state-recovery.md](terraform-state-recovery.md) |
| Respond to production outage | [emergency-recovery.md](emergency-recovery.md) |
| Upgrade azurerm provider | [provider-upgrade.md](provider-upgrade.md) |
| Destroy dev environment | [destroy/README.md](../../deployment/destroy/README.md) |

## On-Call Escalation

| Severity | Response Time | Runbook |
|----------|---------------|---------|
| S1 — Production down | 15 minutes | [emergency-recovery.md](emergency-recovery.md) |
| S2 — Stage/degraded prod | 1 hour | [rollback.md](rollback.md) |
| S3 — Dev issue | Best effort | [deploy.md](deploy.md) |

## Related

- [CI/CD Architecture](../cicd/README.md)
- [Backend Strategy](../terraform/backend-strategy.md)
- [Deployment Framework](../../deployment/README.md)
