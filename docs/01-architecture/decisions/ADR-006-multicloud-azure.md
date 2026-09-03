# ADR-006 — Multi-cloud topology: Azure replica via Floci-AZ

## Status

Accepted

## Context

CloudForge previously modeled a warm-standby disaster-recovery site on a third cloud (Scaleway) using the Feint emulator. The Scaleway site was IaaS-only and did not replicate the serverless application platform.

The project's goal is to demonstrate how the same serverless platform can be provisioned, tested, secured and operated on more than one public cloud, entirely locally. A second implementation of the AWS serverless platform is required over an Azure-flavoured stack with a unified entry point that spans both clouds.

## Decision

Replace the Scaleway warm-standby DR site with an Azure replica of the AWS application platform, emulated locally with **Floci-AZ** on `localhost:4577` and provisioned with the **azurerm** OpenTofu provider.

The AWS and Azure platforms keep feature parity where the emulator allows:

| AWS (Floci)      | Azure (Floci-AZ)  |
| ---------------- | ----------------- |
| API Gateway      | API Management    |
| Lambda           | Azure Functions   |
| DynamoDB         | Cosmos DB (NoSQL) |
| S3               | Blob Storage      |
| SQS / SNS        | Queue Storage     |
| EventBridge      | Event Grid        |
| CloudWatch       | Azure Monitor     |
| KMS / Secrets Mgr| Key Vault         |
| IAM              | Entra ID          |

A single nginx gateway on `:4600` fronts both clouds, routing traffic 50/50 by default and allowing pinning via the `X-Cloud` header (`aws` / `azure`).

## Consequences

* The two clouds can be exercised through one public endpoint, enabling cross-cloud routing, failover and comparison.
* Two OpenTofu provider configurations (AWS + Azure) and their environments must be maintained.
* Emulator gaps on either side must be documented in `docs/02-infrastructure/local-environment.md`.
* The previous Scaleway DR environment (`scw-dr/`), the Feint skill and ADR-005 are removed.

## Alternatives Considered

* **Scaleway warm-standby (previous)**: IaaS-only, did not replicate the serverless platform; kept as a DR site but not equivalent to the primary.
* **Single cloud only**: simpler, but lost the multi-cloud demonstration the project aims for.
* **Real Azure/AWS accounts**: not available or appropriate for a local, offline lab; local emulators keep the lab reproducible.
