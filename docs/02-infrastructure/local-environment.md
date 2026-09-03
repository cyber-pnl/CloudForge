# Local Environment (Floci + Floci-AZ)

Floci provides the local AWS environment: AWS-compatible APIs without a real AWS account. Floci-AZ provides the local Azure environment alongside it.

## Endpoint

| Service | Endpoint |
|---------|----------|
| Floci (AWS) | `http://localhost:4566` |
| Floci-AZ (Azure) | `http://localhost:4577` |
| Unified gateway | `http://localhost:4600` |

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

## Unified Cloud Gateway

A lightweight nginx gateway sits in front of both Floci and Floci-AZ and provides
a **single entry point** on `http://localhost:4600`:

| Mode | Behavior |
|------|----------|
| `X-Region: aws` | All requests → Floci (AWS) |
| `X-Region: azure` | All requests → Floci-AZ (Azure) |
| No header | Random 50/50 split between the two backends |

The split is deterministic per request (`split_clients` hashing `$request_id`)
so the same request always lands on the same backend within a burst, but the
overall distribution converges to 50/50.

```bash
# Explicit routing
curl -H "X-Region: aws" http://localhost:4600/_localstack/health
curl -H "X-Region: azure" http://localhost:4600/_floci/health

# Random routing
curl http://localhost:4600/_localstack/health
```

OpenTofu providers point directly to their respective backends (`:4566` /
`:4577`) for deterministic IaC operations. The gateway is for ad-hoc testing,
demonstrations and external consumers that need one URL for both clouds.

## Floci-AZ (Azure emulator)

Floci-AZ provides the local Azure environment alongside Floci. It serves the
Azure API on port `4577`, started by the same `docker compose up` command
as Floci.

### Endpoint

```text
http://localhost:4577
```

### Health check

```bash
curl -s localhost:4577/_floci/health | python3 -m json.tool
```

### How OpenTofu uses Floci-AZ

```text
OpenTofu (azurerm provider)
    │
    │ Azure API (HTTPS)
    ▼
Floci-AZ :4577
    │
    ├── Azure Functions (compute)
    ├── API Management (routing)
    ├── Cosmos DB (data)
    ├── Blob Storage (objects)
    ├── Queue Storage (messaging)
    ├── Event Grid (events)
    ├── Azure Monitor (observability)
    ├── Key Vault (secrets & keys)
    └── Entra ID (identity)
```

### TLS is mandatory for the azurerm provider

The `azurerm` provider discovers Azure over HTTPS (`GET https://{host}/metadata/endpoints`).
Floci-AZ serves plain HTTP by default — the provider fails before any resource request.

`FLOCI_AZ_TLS_ENABLED=true` is set in `docker-compose.yml`. Floci-AZ serves HTTP and
HTTPS on the same port (`4577`) via a protocol-sniffing proxy. A self-signed certificate
is generated at startup.

Trust the certificate before running `tofu` against Floci-AZ:

```bash
curl -sf http://localhost:4577/_floci/tls-cert -o floci-az.crt
# Linux (requires sudo):
sudo cp floci-az.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates
# OR without sudo (set SSL_CERT_FILE):
export SSL_CERT_FILE="$PWD/floci-az.crt"
```

### azurerm provider block (Floci-AZ)

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  use_cli                    = false

  environment   = "stack"
  metadata_host = "localhost:4577"

  subscription_id = "00000000-0000-0000-0000-000000000001"
  tenant_id       = "00000000-0000-0000-0000-000000000002"
  client_id       = "00000000-0000-0000-0000-000000000003"
  client_secret   = "fake-secret"
}
```

`environment = "stack"` tells the provider to use metadata discovery.
Credentials are never validated by Floci-AZ in dev mode.

### Emulator-specific behavior

Floci-AZ-specific divergences and workarounds are documented here as they are
discovered. The same rules as Floci apply:

1. Check Floci-AZ support before implementing an Azure feature.
2. Isolate workarounds in a single place.
3. Do not spread emulator-specific assumptions throughout the application.
4. Document any emulator-specific behavior in this file.

### Multi-account isolation — Floci-AZ-specific

Floci-AZ mirrors Floci's account isolation model for Azure resource groups and
subscriptions. Environments share the default account and rely on name prefixes.

### Event Grid — Floci-AZ-specific

Floci-AZ implements Event Grid in-process over the ARM path
(`Microsoft.EventGrid`) with custom topics, access keys, and webhook event
subscriptions. Publishing is HTTP-only (data plane at `/{topic}-eventgrid/api/events`)
in Event Grid or CloudEvents 1.0 schemas; delivery is async with retry and the
`SubscriptionValidationEvent` handshake.

Verified limitations (do not rely on these working):

1. **Webhook destinations only.** Storage Queue, Azure Function, Service Bus,
   and Event Hub event subscription destinations are not supported.
2. **No dead-lettering.** Events that exhaust `maxDeliveryAttempts` are dropped,
   not written to a dead-letter blob container.
3. **No Namespace surface.** Domains, partner/system topics, and the MQTT/pull
   namespace are out of scope.
4. **Advanced filters are accepted but not evaluated**; `CustomEventSchema` is
   treated as the Event Grid schema.
5. Authentication is permissive: the `aeg-sas-key` header is accepted but not
   validated (dev mode).

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
