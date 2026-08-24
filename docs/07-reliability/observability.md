# Observability

## Signals

The platform exposes, per poll cycle of the exporter:

* SQS queue depth (visible messages) for every queue, labelled `kind=main|dlq`
* DynamoDB item counts per table
* S3 object counts per bucket
* recent Lambda `ERROR` log entries per function (windowed approximation)
* API health probe (`cloudforge_api_up`)

## Live architecture

```text
Floci :4566 (AWS APIs)
     │
     ▼
exporter :9877 ── /metrics (Prometheus text format)
     │      │
     │      └── push CloudForge/* gauges to CloudWatch
     ▼                │
Prometheus :9090 ◄────┘ (alarms reference pushed metrics)
     │
     ├── rules: DeadLetterQueueNotEmpty (evaluated), ApiDown (evaluated)
     ▼
Grafana :3000 — "CloudForge Overview" dashboard (provisioned JSON)
```

## Detection paths

| Signal | Where | Latency |
| ------ | ----- | ------- |
| DLQ depth > 0 | Prometheus rule + exporter metric | ≤ 2 scrape intervals |
| Emulator/API down | `cloudforge_api_up`, Prometheus rule ApiDown | ≤ 1 poll cycle |
| Lambda errors | `cloudforge_lambda_recent_errors` + CloudWatch Logs | windowed (~4 polls) |
| Queue backlog | `cloudforge_sqs_messages{kind="main"}` | ≤ 1 poll cycle |

## Known limits

* The emulator stores CloudWatch alarms but never evaluates them; Prometheus
  rules are the authoritative evaluation path (see ADR-003 and the local
  environment guide).
* Lambda error counts come from log scanning over a bounded window — they are a
  trend signal, not an invocation counter.
* Metric sections go stale independently when the emulator is unreachable; the
  health probe stays fresh because it runs first in every cycle.
