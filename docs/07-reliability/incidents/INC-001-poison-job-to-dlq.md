# INC-001 — Poison job reaches the dead-letter queue

* **Date:** 2026-08-24
* **Severity:** minor (controlled injection, no user impact)
* **Scenario:** `make inject-poison` (`scripts/failure-injection.sh poison-job`)

## 1. Detection

* Worker Lambda logs three consecutive `RuntimeError: Simulated failure` entries
  (one per delivery attempt, visible via CloudWatch Logs and Floci logs).
* The exporter metric `cloudforge_sqs_messages{kind="dlq"}` increases by one.
* Prometheus alert **DeadLetterQueueNotEmpty** fires (`for: 1m`).
* The declarative CloudWatch alarm `cloudforge-dev-dlq-not-empty` references the
  same pushed metric; the emulator registers but never evaluates alarms, so the
  authoritative signal is the Prometheus rule.

## 2. Impact

One job is never processed and its artifact is not written. No data loss: the
original message body is preserved in the DLQ for inspection or replay.

## 3. Investigation

```bash
aws sqs get-queue-attributes --queue-url $ENDPOINT/000000000000/cloudforge-dev-jobs-dlq \
    --attribute-names ApproximateNumberOfMessages
docker logs cloudforge-floci | grep "Simulated failure"
```

The worker raised on every attempt with the same message id; after exactly
`maxReceiveCount = 3` deliveries SQS moved the message to the DLQ (redrive
policy verified present in queue attributes).

## 4. Root cause

The job payload contained `"simulate_failure": true` inside the canonical event
envelope (`detail.new_image`) — the field the worker reads from stream-derived
images. Two earlier probe attempts placed the flag at the top level of the
message body instead: the worker treated those as valid jobs, stored artifacts,
and deleted them. Nothing was broken; the injection contract is simply strict.

## 5. Remediation

None required for the platform — retry + redrive behaved as designed. The
injection script now sends the canonical envelope so the scenario exercises the
failure path it claims to exercise.

## 6. Recovery

Inspect then drain the DLQ (see runbook RB-01). For this lab the messages are
test noise and are purged.

## 7. Prevention

* Keep the DLQ depth at zero during normal operation; any growth pages.
* Validate job envelopes against the documented contract if third-party
  producers ever exist (noted as a hardening backlog item).
* Integration tests already assert that valid jobs drain the queue, guarding
  against false-positive failures.

## 8. Post-mortem

Retry semantics worked end to end: three attempts, then redrive, then an alert.
The valuable lesson came from the malformed probes — a failure-injection tool
must speak the exact production contract, otherwise it silently validates the
happy path while believing it exercises failure handling.
