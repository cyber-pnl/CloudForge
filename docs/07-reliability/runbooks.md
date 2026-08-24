# Runbooks

Operational procedures for the local CloudForge environment. Every procedure
assumes the compose stack is up (`docker compose up -d`) unless stated
otherwise.

## RB-01 — Drain or purge the dead-letter queue

**When:** `DeadLetterQueueNotEmpty` fires, DLQ depth > 0.

1. Inspect the offending messages:

   ```bash
   aws sqs receive-message --queue-url http://localhost:4566/000000000000/cloudforge-dev-jobs-dlq \
       --max-number-of-messages 5 --visibility-timeout 0
   ```

2. Decide per message: replay (fix the root cause, then send the same body back
   to the jobs queue) or purge (test noise).
3. Purge when the content is test data:

   ```bash
   aws sqs purge-queue --queue-url http://localhost:4566/000000000000/cloudforge-dev-jobs-dlq
   ```

4. Confirm `cloudforge_sqs_messages{kind="dlq"}` returns to 0 and the alert
   resolves within two scrape intervals.

## RB-02 — Restart the observability stack

**When:** exporter, Prometheus or Grafana unhealthy (`/health`, `/api/health`,
`/-/healthy` respectively).

```bash
docker compose up -d --force-recreate exporter prometheus grafana
```

Order matters only on first start: Floci must be reachable before the exporter
polls. Metrics older than one poll cycle are stale but harmless; Prometheus
keeps history across restarts of individual components.

## RB-03 — Full environment recovery from scratch

**When:** state corrupted, or reproducing a cold start (CI does exactly this).

```bash
docker compose down          # destroys emulator state
docker compose up -d         # floci + observability stack
make apply AUTO_APPROVE=true # rebuilds and redeploys infrastructure
make test-integration        # 17 checks must pass
```

Known consequence: stream event source mappings are recreated fresh, so no
history replay occurs; the DLQ starts empty and any prior incident evidence is
gone by design.

## RB-04 — Verify pipeline health after an incident

1. `make test-integration` — end-to-end API, storage and event flow.
2. `curl localhost:9877/metrics | grep api_up` — health probe reports 1.
3. `curl -s localhost:9090/api/v1/alerts` — no unexpected firing alerts.
4. `docker logs cloudforge-floci | tail` — no error storms.

## RB-05 — Replay a dead-letter message manually

1. Receive the message from the DLQ with a long visibility timeout and copy its
   body.
2. Fix the underlying condition that made it fail (code fix, missing resource).
3. Send the copied body to the jobs queue:

   ```bash
   PYTHONPATH=lambdas/dispatcher/build python3 -c "
import boto3, json
boto3.client('sqs', region_name='us-east-1', endpoint_url='http://localhost:4566') \
     .send_message(QueueUrl='http://localhost:4566/000000000000/cloudforge-dev-jobs',
                   MessageBody=json.dumps(json.loads(open('message.json').read())))
"
   ```

4. Watch the artifact appear and the queue drain to zero.
