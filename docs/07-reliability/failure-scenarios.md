# Reliability — Failure Scenarios

CloudForge is also designed as an SRE/DevOps laboratory.

The project includes controlled failure scenarios to demonstrate operational maturity, not only deployment skills.

## Example scenario

```text
Worker Lambda
     │
     X
   FAILURE
     │
     ▼
     SQS
     │
     ▼
    DLQ
     │
     ▼
CloudWatch Alarm
     │
     ▼
  Incident
```

Example incident: **INC-001 — Worker Lambda unavailable**

## Incident documentation

Each documented incident should contain:

1. Detection
2. Impact
3. Investigation
4. Root cause
5. Remediation
6. Recovery
7. Prevention
8. Post-mortem

See `skills/incident-response/SKILL.md` for the full procedure and `observability.md` for the detection signals.
