# Cloud Services

CloudForge intentionally uses services from two clouds to demonstrate different cloud patterns: **AWS** (serverless primary) and **Scaleway** (IaaS warm-standby).

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

## Scaleway Services (DR Site — Feint)

| Service         | Purpose                                    |
| --------------- | ------------------------------------------ |
| VPC             | Isolated network overlay                   |
| VPC Gateway     | Network routing                            |
| Instance        | Standby compute (DEV1-S, control-plane)    |
| Block Storage   | Persistent restore volume (10 GB)          |
| IAM             | Access control                             |
| IPAM            | IP address management                      |
| Load Balancer   | Traffic distribution (emulated, not used)  |

The Scaleway environment (`infrastructure/environments/scw-dr/`) models a warm-standby disaster-recovery site: if the primary AWS cloud is lost, workloads can be re-hosted on Scaleway infrastructure provisioned by the real `scaleway/scaleway` provider against the Feint emulator.

## Local execution

Both clouds run locally through their respective emulators:

| Emulator | Port | Cloud |
| -------- | ---- | ----- |
| Floci    | :4566 | AWS  |
| Feint    | :4599 | Scaleway |

A unified nginx proxy on `:4600` routes requests to either backend (see [Unified Cloud Proxy](../02-infrastructure/local-environment.md#unified-cloud-proxy)).

See [Local Environment](../02-infrastructure/local-environment.md) for usage details and emulator-specific behavior.

## Adding a service

Before adding a new cloud service, follow the justification checklist in `rules/01-architecture.md` and the procedure in `skills/architecture/SKILL.md`. Update the appropriate table when a service is added.
