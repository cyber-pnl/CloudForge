# Reliability — Failure Scenarios

CloudForge is also designed as an SRE/DevOps laboratory.

The project includes controlled failure scenarios to demonstrate operational maturity, not only deployment skills. Both scenarios below are reproducible with one command against the live environment.

## Scenario 1 — poison job → retries → DLQ → alert

```text
Poison job (simulate_failure in the canonical envelope)
     │
     ▼
Worker fails 3 deliveries (maxReceiveCount)
     │
     ▼
SQS redrive moves it to the DLQ
     │
     ▼
Exporter metric cloudforge_sqs_messages{kind="dlq"} increases
     │
     ▼
Prometheus alert DeadLetterQueueNotEmpty fires
```

Reproduce: `make inject-poison`. Full lifecycle documented in
[INC-001](incidents/INC-001-poison-job-to-dlq.md).

## Scenario 2 — emulator outage → health probe → alert

```text
Emulator container stops
     │
     ▼
cloudforge_api_up drops to 0 within one poll cycle
     │
     ▼
Prometheus alert ApiDown pending, firing after 2m
```

Reproduce: `make inject-outage` (stops the emulator for ~150 s and restarts it).
Full lifecycle documented in [INC-002](incidents/INC-002-emulator-outage.md).

## Scenario 3 — Azure failover (Floci down → Azure site active)

```text
Floci container stops (primary cloud lost)
     │
     ▼
Application unreachable on AWS endpoints
     │
     ▼
Azure stack (docker-compose.az.yml) already running
     │
     ▼
Traffic redirected to reverse proxy (:8081)
     │
     ▼
Azure stack serves application from Floci-AZ infrastructure
```

This scenario validates the warm-standby disaster-recovery topology defined
in ADR-005. The Azure site runs a containerized version of the application with
local PostgreSQL, Redis and filesystem-backed storage. See
[deployment-strategy.md](../04-devops/deployment-strategy.md) Path B for the
full procedure.

## Incident documentation

Each incident report follows the same eight-part lifecycle:

1. Detection
2. Impact
3. Investigation
4. Root cause
5. Remediation
6. Recovery
7. Prevention
8. Post-mortem

See `skills/incident-response/SKILL.md` for the procedure,
[runbooks](runbooks.md) for operations, and [observability](observability.md)
for detection signals.
