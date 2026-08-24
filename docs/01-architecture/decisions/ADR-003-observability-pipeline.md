# ADR-003 — Observability pipeline

## Status

Accepted (2026-08)

## Context

Phase 7 requires metrics, alarms and dashboards. Floci implements the CloudWatch
API surface we probed (`put_metric_data`, `list_metrics`, `get_metric_statistics`,
`put_metric_alarm`/`describe_alarms` with a state machine), but it does **not**
emit service metrics itself: nothing inside the emulator publishes SQS depths or
Lambda error counts on its own, there is no Prometheus scrape endpoint, and
CloudWatch alarms therefore have nothing to evaluate unless something feeds them.

## Decision

1. **A single exporter is the source of truth for metrics.**
   `observability/exporter` polls the local AWS APIs (SQS queue attributes,
   DynamoDB item counts via `Scan Select=COUNT`, S3 object counts, Lambda log
   groups scanned for `[ERROR]`, API invoke URL health probe) and exposes them in
   Prometheus text format on `/metrics`.

2. **The exporter also pushes the same gauges to CloudWatch** under the
   `CloudForge/*` namespaces every poll interval. This makes CloudWatch alarms
   real end-to-end artifacts instead of dead configuration.

3. **Alarms are infrastructure as code** in a `cloudwatch` module:
   - DLQ depth > 0 → notify topic (a poison message must page someone)
   - API health < 1 → notify topic

4. **Prometheus and Grafana run as compose services**, provisioned from files in
   the repository (`observability/prometheus/prometheus.yml`,
   `observability/grafana/provisioning/`). Dashboards are versioned JSON, not
   hand-built UI state.

## Consequences

* Metric collection works regardless of emulator fidelity; if Floci later emits
  native CW metrics, the push path becomes redundant but harmless.
* The exporter discovers queues, tables and buckets dynamically instead of hard
  coding names, so renames do not silently drop series.
* Lambda error counts are windowed approximations from log scanning, not exact
  invocation counters; documented as such.
* Alarms evaluate pushed data only while the exporter runs; stopping the stack
  moves them to `INSUFFICIENT_DATA`, which is observable behavior, not a defect.
