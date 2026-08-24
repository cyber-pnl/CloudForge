# INC-002 — Emulator outage detected by the health probe

* **Date:** 2026-08-24
* **Severity:** minor (controlled injection, no user impact)
* **Scenario:** `make inject-outage` (`scripts/failure-injection.sh emulator-outage`)

## 1. Detection

* `docker stop cloudforge-floci` makes every AWS call fail.
* The exporter's API health probe flips `cloudforge_api_up` from 1 to 0 within
  one poll cycle (health is probed first and fails fast on connection refusal).
* Prometheus alert **ApiDown** goes pending immediately and fires after its
  `for: 2m` window if the outage persists.

## 2. Impact

The whole control and data plane is unavailable: API requests fail, no jobs are
processed, metrics collection degrades to stale sections. In this lab there are
no real users; in production this maps to a regional outage.

## 3. Investigation

```bash
curl -s localhost:9877/metrics | grep api_up
docker ps --filter name=cloudforge-floci
curl -s localhost:4566/_localstack/health
```

## 4. Root cause

Deliberate container stop. The exercise exposed a real observability defect:
the original exporter polled AWS resources first and updated all metric lines
once at the end of the cycle, with unbounded boto3 retries. Against a dead
endpoint a poll blocked for minutes, freezing `cloudforge_api_up = 1` — exactly
the signal needed during an outage was stale.

## 5. Remediation

Exporter hardening (shipped with this incident):

* bounded botocore config (`connect_timeout=3`, `read_timeout=5`,
  two attempts max) so calls against an unreachable endpoint fail in seconds;
* incremental section publishing — each collector updates its own metric
  section under a lock as soon as it finishes;
* the health probe runs first in every poll cycle.

## 6. Recovery

`docker start cloudforge-floci`; services report running again, the exporter
flips `cloudforge_api_up` back to 1 on the next poll, and ApiDown resolves.
Queue messages survive the outage because the emulator persists state while
the container exists (stop/start, not down/up).

## 7. Prevention

* The exporter now degrades per-section instead of globally freezing.
* Integration tests cover the exporter, Prometheus query path and Grafana
  health so a silently broken pipeline cannot persist.
* Runbook RB-02 documents full stack restart order for real incidents.

## 8. Post-mortem

Monitoring failed precisely when it mattered and the failure was invisible
because the dashboard kept showing healthy values. The fix treats freshness as
a first-class property of every metric section rather than of the scrape output
as a whole. Alert thresholds were left unchanged: a sub-two-minute flap stays
pending, which matches how transient restarts should be treated.
