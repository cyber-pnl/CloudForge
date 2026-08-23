# AWS Services

CloudForge intentionally uses several AWS services to demonstrate different cloud patterns.

| Service             | Purpose                      |
| ------------------- | ---------------------------- |
| API Gateway         | Public HTTP API              |
| Lambda              | Serverless application logic |
| DynamoDB            | Application data             |
| DynamoDB Streams    | Event generation             |
| EventBridge         | Event routing                |
| SQS                 | Asynchronous processing      |
| SQS DLQ             | Failed message handling      |
| SNS                 | Notifications                |
| S3                  | Object storage               |
| IAM                 | Access control               |
| CloudWatch          | Logs and metrics             |
| Secrets Manager     | Application secrets          |
| SSM Parameter Store | Configuration                |

## Local execution

The infrastructure is executed locally through **Floci**, which provides AWS-compatible APIs on `localhost:4566`.

See [Local Environment](../02-infrastructure/local-environment.md) for usage details and emulator-specific behavior.

## Adding a service

Before adding a new AWS service, follow the justification checklist in `rules/01-architecture.md` and the procedure in `skills/architecture/SKILL.md`. Update this table when a service is added.
