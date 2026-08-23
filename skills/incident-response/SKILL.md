# Skill — Incident Response

## When to use

Use this skill when documenting a failure scenario, writing an incident report, or performing post-incident analysis.

## Incident convention

Incidents are identified as:

```text
INC-XXX — Short title
```

Example: `INC-001 — Worker Lambda unavailable`.

## Incident lifecycle

CloudForge includes controlled failure scenarios (e.g. Worker Lambda failure → SQS → DLQ → CloudWatch alarm). Each documented incident must cover, in order:

1. Detection
2. Impact
3. Investigation
4. Root cause
5. Remediation
6. Recovery
7. Prevention
8. Post-mortem

## Procedure

1. Reproduce the scenario against the local Floci environment.
2. Capture the detection path (alarm, metric, log).
3. Document the incident following the lifecycle above in `docs/07-reliability/`.
4. If the incident reveals an architectural weakness, create or update an ADR (see `rules/01-architecture.md`).
5. Add prevention measures (tests, alarms, runbook updates).

## References

* Rules: `rules/01-architecture.md`
* Docs: `docs/07-reliability/failure-scenarios.md`, `docs/07-reliability/observability.md`
