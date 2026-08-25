# Local Environment (Floci + Feint)

Floci provides the local AWS environment: AWS-compatible APIs without a real AWS account. Feint provides the local Scaleway environment alongside it.

## Endpoint

```text
http://localhost:4566
```

## Usage

Start the environment:

```bash
docker compose up -d
```

Verify:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Stop the environment:

```bash
docker compose down
```

## Compose configuration

The committed `docker-compose.yml` pins the image (`floci/floci:1.7.0`) for reproducible environments and sets:

* `FLOCI_STORAGE_MODE=hybrid` — in-memory performance with periodic flushing; state survives container restarts.
* Docker socket mounted with `user: root` — required because Floci runs Lambda (and other container-backed services) as real Docker containers.
* `FLOCI_DEFAULT_REGION=us-east-1`.

Local credentials are dummy values (`test` / `test`, configured once in `~/.aws/credentials`). They never leave the emulator.

## How OpenTofu uses Floci

```text
OpenTofu
    │
    │ AWS API
    ▼
Floci :4566
    │
    ├── S3
    ├── Lambda
    ├── DynamoDB
    ├── SQS
    ├── SNS
    ├── EventBridge
    └── API Gateway

Observability stack (docker compose)
    exporter :9877   polls Floci APIs, serves /metrics, pushes CloudForge/* metrics
    prometheus :9090 scrapes exporter, evaluates alert rules
    grafana :3000    dashboards (provisioned, anonymous viewer access)
```

## Emulator-specific behavior

Do not assume every AWS service behaves exactly like real AWS.

Known divergences and workarounds are documented here as they are discovered. Rules:

1. Check Floci support before implementing an AWS feature.
2. Isolate workarounds in a single place.
3. Do not spread emulator-specific assumptions throughout the application.
4. Document any emulator-specific behavior in this file.

### Endpoint overrides are mandatory per service

The AWS provider routes each service to its real AWS endpoint unless explicitly overridden. During Phase 1, a KMS `CreateKey` call silently reached real AWS and failed there because only the S3 endpoint was overridden.

Rule: every AWS service used in an environment must have its endpoint set to the Floci endpoint in the provider `endpoints` block. When adding a service, extend the block and verify in Floci logs that requests reach the emulator (`docker logs cloudforge-floci`).

### Known unsupported operations (verified by probes)

* `logs:AssociateKmsKey` — reported `UnsupportedOperation`.
* API Gateway stage access log settings — silently ignored on `UpdateStage`.
* DynamoDB server-side encryption with customer managed keys — `SSEDescription` stays absent.
* X-Ray — no service emulation at all.

### Event-driven behavior quirks (verified in Phase 3)

* Lambda event source mapping payloads for DynamoDB streams **omit `eventSourceARN`** — consumers must receive the table identity through configuration, not payload inspection (see ADR-001).
* Recreating a stream ESM or its function **replays historical stream records**; treat idempotent workers and DLQ contents with this in mind when re-deploying.
* The redrive policy works end to end (`maxReceiveCount=3`, messages land in the dead letter queue), but `ApproximateReceiveCount` may exceed the configured maximum.
* AWS CLI v2.31.x on Python 3.14 crashes with `badly formed help string` on some SQS commands (`send-message`, `receive-message`). Workaround: call the API through the vendored boto3 shipped with the lambda builds:

  ```bash
  PYTHONPATH=lambdas/dispatcher/build python3 -c "import boto3; ..."
  ```

### Cognito and authorizers (verified in Phase 4)

* Cognito CRUD operations work, and `COGNITO_USER_POOLS` authorizers can be created on the API — but **authorizers are not enforced at invocation time** (a protected method answers `200` without any token). Authentication is therefore implemented at application level; see ADR-002.
* `apigateway:DeleteAuthorizer` fails with an unrelated S3 `NoSuchBucket` error; probed authorizers cannot be removed and stay orphaned (inert once no method references them).

### OPTIONS preflights never reach Lambda (verified in Phase 10)

The emulator intercepts `OPTIONS` on any route and answers itself with a bare
`200` and an `Allow` header — the request does not invoke the backend, so the
response carries no custom headers (no CORS headers, regardless of what the
Lambda would return; the handlers' `preflight()` path only executes on real
AWS). Browser consoles therefore call the API through the same-origin nginx
proxy in the webapp service instead of relying on preflight behavior.

### State drift on read-back (verified in Phase 7)

Floci does not persist or read back some attributes that the provider writes. Every refresh then reports drift that would force replacements:

* Lambda event source mappings: `starting_position` and `maximum_batching_window_in_seconds` are never returned. The platform module ignores changes on both; without it every plan replaces the ESMs and replays stream history.
* API Gateway integrations: `timeout_milliseconds` reads back as `0`. The api-gateway module pins it explicitly and ignores changes.
* CloudWatch alarms: `datapoints_to_alarm` is not persisted; the cloudwatch module ignores changes on it.

### CloudWatch metrics and alarms (verified in Phase 7)

* `PutMetricData`, `ListMetrics`, `GetMetricStatistics`, `PutMetricAlarm`, `DescribeAlarms`, `DeleteAlarms` all work.
* Alarms are **stored but never evaluated**: state stays `INSUFFICIENT_DATA` with reason `Unchecked` forever. `SetAlarmState` exists for manual transitions. Real alert evaluation therefore lives in Prometheus rules (`observability/prometheus/rules.yml`) which fire correctly against exporter data; CloudWatch alarms remain declarative IaC artifacts documenting intent.
* The provider block must route `cloudwatch` to Floci via `endpoints {}` like every other service — otherwise calls hit real AWS and fail with `InvalidClientTokenId`.
* `TagResource` on an alarm returns HTTP 200 with an empty body; AWS SDK Go clients fail deserializing the response even though the operation succeeds server-side (verified in Phase 9).

## Unified Cloud Proxy

A lightweight nginx proxy sits in front of both Floci and Feint and provides
a **single entry point** on `http://localhost:4600`:

| Mode | Behavior |
|------|----------|
| `X-Region: aws` | All requests → Floci (AWS) |
| `X-Region: scaleway` | All requests → Feint (Scaleway) |
| No header | Random 50/50 split between the two backends |

The split is deterministic per request (`split_clients` hashing `$request_id`)
so the same request always lands on the same backend within a burst, but the
overall distribution converges to 50/50.

```bash
# Explicit routing
curl -H "X-Region: aws" http://localhost:4600/_localstack/health
curl -H "X-Region: scaleway" http://localhost:4600/_feint/health

# Random routing
curl http://localhost:4600/_localstack/health
```

OpenTofu providers point directly to their respective backends (`:4566` /
`:4599`) for deterministic IaC operations. The proxy is for ad-hoc testing,
demonstrations and external consumers that need one URL for both clouds.

## Feint (Scaleway emulator)

[Feint](https://github.com/stephrobert/feint) provides the local Scaleway
environment alongside Floci. It is a single-binary emulator serving the
Scaleway API on port `4599`, started by the same `docker compose up` command
as Floci.

### Endpoint

```text
http://localhost:4599
```

### Health check

```bash
curl -s localhost:4599/_feint/health | python3 -m json.tool
```

### How OpenTofu uses Feint

```text
OpenTofu (scaleway/scaleway provider)
    │
    │ Scaleway API  (api_url override)
    ▼
Feint :4599
    │
    ├── Instance (compute)
    ├── VPC / VPCgw (networking)
    ├── Block (block storage)
    └── IAM (access control)
```

### Emulator-specific behavior

1. **Control-plane only.** Created servers report API state but never boot
   (`capabilities.machines: false` unless Incus/OVN is configured). The lab
   proves reproducible provisioning, not workload execution on Scaleway.
2. **No Object Storage.** The Scaleway S3-compatible API is not emulated.
   CloudForge's artifact pipeline therefore stays on AWS/Floci (S3).
3. **Credentials are never validated.** Feint accepts any signing credentials
   (`SCWXXXXXXXXXXXXXXXXX` / `11111111-1111-1111-1111-111111111111`) as
   long as the client can sign requests. They are present only to satisfy
   client-side signing requirements.
4. **Volume attachment drift.** The Scaleway provider re-applies the
   `additional_volume_ids` attribute on every plan when the volume was
   created in the same apply — the emulator does not persist the attachment
   state back. This is harmless (idempotent in-place update) and does not
   affect the destroy path.

### Multi-account isolation (verified in Phase 9)

The access key selects the account (`000000000001` gets its own resources), but only for **control-plane** APIs. The REST API execute plane resolves APIs exclusively in the default account, so an API deployed under another account cannot be invoked over HTTP. Environments therefore share the default account and rely on name prefixes (see ADR-004). `scripts/purge_floci_account.py` removes prefixed resources from a non-default account.

### Provider version pinning

The project pins `hashicorp/aws` to `~> 5.0`, matching the provider constraint of Floci's own OpenTofu compatibility suite. Provider 6.45+ regresses on API Gateway v1 (`GetRestApi`/`PutRestApi` response fields, upstream issues floci-io/floci#855 and #999): under 6.x the `aws_api_gateway_rest_api` waiter fails with `unexpected state ''`. Revisit when Floci ships fixes for these issues.

### Lambda execution model

Functions run as real Docker containers using `public.ecr.aws/lambda/python:<version>` runtime images. The image is pulled by Floci at first invocation; pre-pulling it avoids slow cold starts:

```bash
docker pull public.ecr.aws/lambda/python:3.13
```

The local execute-plane URL for REST APIs differs from real AWS:

```text
http://localhost:4566/restapis/{api_id}/{stage}/_user_request_/{path}
```

See `skills/floci/SKILL.md` for the working procedure.
