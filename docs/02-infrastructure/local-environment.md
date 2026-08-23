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

See `skills/floci/SKILL.md` for the working procedure.
