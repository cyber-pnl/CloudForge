# Deployment Strategy

How changes travel from a commit to the running environments, and how to get
back out of a bad deployment. The topology is defined in
[ADR-004](../01-architecture/decisions/ADR-004-environment-topology.md).

## Environments

| Environment | Directory | Cloud | Lifetime | Deployed by |
| ----------- | --------- | ----- | -------- | ----------- |
| dev | `infrastructure/environments/dev` | AWS (Floci) | ephemeral | CI on every push/PR; `make apply` locally |
| staging | `infrastructure/environments/staging` | AWS (Floci) | long-lived | CI manual dispatch (promotion) or local apply |
| prod | `infrastructure/environments/prod` | AWS (Floci) | long-lived | explicit local apply only |
| scw-dr | `infrastructure/environments/scw-dr` | Scaleway (Feint) | ephemeral | CI on every push/PR; `make apply` locally |

The AWS environments all wrap the same platform module, so behavior
differences come from inputs only — never from drifted code.

The Scaleway environment models a warm-standby / burst-compute site on a
second cloud provider (ADR-005). It provisions VPC, private network, a
standby instance and a block volume through the real `scaleway/scaleway`
provider against the Feint emulator.

## Deployment flow

```text
commit → ci pipeline (dev)
             │ pytest, fmt, validate, trivy gates
             │ plan → apply → 17 e2e checks
             ▼
        green build ──(manual dispatch: deploy_staging)──► staging
                                                              │ apply + e2e checks
                                                             ▼
                                                       prod: local apply
```

* Dev is destroyed and rebuilt every run — the pipeline itself is the DR drill.
* Staging promotion reuses the exact packages validated in dev.
* Prod is never touched by automation; applying it is a deliberate operator act.

## Rollback strategy

OpenTofu state only moves forward, so rollback means **redeploying an earlier
build**, not reversing state:

1. Identify the last known-good git revision (`git log --oneline`).
2. Check it out and rebuild packages:

   ```bash
   git checkout <good-rev>
   make package
   ```

3. Redeploy the target environment:

   ```bash
   tofu -chdir=infrastructure/environments/<env> apply -auto-approve
   ```

Infrastructure-only regressions can alternatively be rolled back with a plan
against the previous configuration directory state (`tofu apply` of the older
code), which is the same mechanism: old code, fresh apply.

## Disaster recovery scenario

Scenario: the environment is corrupted or lost (bad apply, emulator state loss,
host reboot with storage wipe).

Procedure (runbook RB-03):

```bash
docker compose down && docker compose up -d   # fresh emulator + observability stack
make apply AUTO_APPROVE=true                  # rebuild infrastructure from code
make test-integration                         # prove the platform end to end
```

Expected recovery time: under ten minutes for one environment (CI completes the
same path unattended). Expected data loss: everything created after the last
apply — accepted for the lab, documented here because the same decision must be
explicit in production.

## Known constraints

* Floci multi-account isolation is control-plane only; environments therefore
  share the default account and rely on name prefixes.
* Stream event source mappings are recreated fresh on cold rebuilds, so no
  stream history replays into a new environment.
