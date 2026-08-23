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

See `skills/floci/SKILL.md` for the working procedure.
