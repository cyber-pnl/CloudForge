# Local AWS Environment (Floci)

Floci provides the local AWS environment: AWS-compatible APIs without a real AWS account.

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
