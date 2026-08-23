# ADR-001 — DynamoDB Streams to EventBridge through per-table dispatcher functions

## Status

Accepted

## Context

The target architecture routes every domain change (users, projects) into the custom EventBridge bus so that downstream consumers (jobs queue, notifications topic) can react independently. AWS offers no native DynamoDB Streams → EventBridge integration; two options exist:

1. **EventBridge Pipes**: a managed pipe with the stream as source and the bus as target.
2. **Dispatcher Lambda**: an event source mapping (ESM) invokes a small function that publishes domain events with `PutEvents`.

Floci implements both primitives on paper. However, Pipes are harder to observe when they misbehave (no execution logs of their own), and the `aws_pipes_pipe` resource is young and poorly exercised against emulators.

During the first end-to-end test we also discovered that Floci's ESM payloads omit `eventSourceARN`, so a shared dispatcher cannot infer which table a record came from.

## Decision

* Use a **dispatcher Lambda per table** (`users-dispatcher`, `projects-dispatcher`), each bound to its table's stream through its own ESM and configured explicitly with `TABLE_NAME` and `EVENT_BUS_NAME` environment variables. No ARN parsing, no payload-shape assumptions.
* Do not use EventBridge Pipes for now.

## Consequences

* Two tiny functions instead of one pipe; both share one IAM role scoped to both streams plus `events:PutEvents`.
* Explicit configuration beats inference: even on real AWS, where the ARN is present, explicit per-source config keeps the handler trivial and testable.
* Revisit Pipes if the number of streamed tables grows and per-table functions become operationally noisy (not expected before many entities exist).
