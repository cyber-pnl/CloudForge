# Cloud Services

CloudForge intentionally uses services from two clouds to demonstrate different cloud patterns: **AWS** (serverless primary) and **Azure** (replicated serverless platform).

The AWS environment is the primary platform. The Azure environment replicates the same serverless application platform so the gateway can route traffic 50/50 across both clouds.

## AWS Services (Primary — Floci)

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

## Azure Services (Replica — Floci-AZ)

| AWS Service       | Azure Service      | Purpose (Azure)                                  |
| ----------------- | ------------------ | ------------------------------------------------ |
| API Gateway       | API Management     | Public HTTP API                                  |
| Lambda            | Azure Functions    | Serverless application logic                     |
| DynamoDB          | Cosmos DB (NoSQL)  | Application data                                 |
| S3                | Blob Storage       | Object storage                                   |
| SQS / SNS         | Queue Storage      | Asynchronous processing & notifications          |
| EventBridge       | Event Grid         | Event routing                                    |
| CloudWatch        | Azure Monitor      | Logs and metrics                                 |
| KMS / Secrets Mgr | Key Vault          | Application secrets                              |
| IAM               | Entra ID           | Access control                                   |

The Azure environment (`infrastructure/environments/dev-az/`) replicates the AWS platform using the `azurerm` provider against the Floci-AZ emulator, keeping the two clouds at feature parity where the emulators allow it.

## Local execution

Both clouds run locally through their respective emulators:

| Emulator | Port | Cloud |
| -------- | ---- | ----- |
| Floci    | :4566 | AWS  |
| Floci-AZ | :4577 | Azure |

A unified nginx gateway on `:4600` routes requests to either backend — 50/50 split, or pinned by the `X-Cloud` header (see [Unified Cloud Gateway](../02-infrastructure/local-environment.md#unified-cloud-gateway)).

See [Local Environment](../02-infrastructure/local-environment.md) for usage details and emulator-specific behavior.

## Adding a service

Before adding a new cloud service, follow the justification checklist in `rules/01-architecture.md` and the procedure in `skills/architecture/SKILL.md`. Update the appropriate table when a service is added.
