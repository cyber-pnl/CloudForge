# Reliability — Failure Scenarios

CloudForge is also designed as an SRE/DevOps laboratory.

The project includes controlled failure scenarios to demonstrate operational maturity, not only deployment skills. Both scenarios below are reproducible with one command against the live environment.

## Scenario 1 — poison job → retries → DLQ → alert

```mermaid
flowchart TD
    P["Poison job<br/>(simulate_failure in the canonical envelope)"]
    W["Worker fails 3 deliveries<br/>(maxReceiveCount)"]
    D[SQS redrive moves it to the DLQ]
    M["Exporter metric<br/>cloudforge_sqs_messages{kind=dlq} increases"]
    A["Prometheus alert<br/>DeadLetterQueueNotEmpty fires"]

    P --> W --> D --> M --> A
```

Reproduce: `make inject-poison`. Full lifecycle documented in
[INC-001](incidents/INC-001-poison-job-to-dlq.md).

## Scenario 2 — emulator outage → health probe → alert

```mermaid
flowchart TD
    E[Emulator container stops]
    H[cloudforge_api_up drops to 0<br/>within one poll cycle]
    P[Prometheus alert ApiDown<br/>pending, firing after 2m]

    E --> H --> P
```

Reproduce: `make inject-outage` (stops the emulator for ~150 s and restarts it).
Full lifecycle documented in [INC-002](incidents/INC-002-emulator-outage.md).

## Scenario 3 — Azure failover (Floci down → Azure site active)

> **Status: blocked — not currently exercisable.** Azure Functions cannot be
> provisioned (Floci-AZ lacks `Microsoft.Web/serverfarms`), so there is no
> running Azure workload to fail over to. See
> [multicloud-journal.md](../02-infrastructure/multicloud-journal.md). The
> gateway routes all traffic to Floci (AWS), so when Floci is down the
> application is unreachable.

```mermaid
flowchart TD
    F["Floci container stops<br/>(primary cloud lost)"]
    U["Application unreachable<br/>(all gateway traffic is AWS-only)"]

    F --> U
```

This warm-standby scenario depends on the Azure replica becoming deployable,
which is blocked pending Floci-AZ Function App support. When resolved, restore
the two-backend gateway (50/50 or `X-Cloud` pinning) and re-provision the
Azure stack before re-enabling this scenario.

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
