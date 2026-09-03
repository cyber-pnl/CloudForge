# Architecture Overview

CloudForge is a multi-cloud DevOps laboratory that reproduces a realistic AWS production environment locally, alongside an Azure replica — no real AWS or Azure account required.

## Project Goals

CloudForge is designed around six main objectives:

* Build a realistic **multi-cloud architecture** (AWS + Azure, replicated serverless platform)
* Manage infrastructure entirely with **OpenTofu** across both clouds
* Implement a complete **CI pipeline** (single workflow, five jobs)
* Integrate **DevSecOps practices with Trivy**
* Test AWS infrastructure locally using **Floci** and Azure using **Floci-AZ**
* Provide a **unified cloud gateway** routing traffic (currently AWS-only; see
  `02-infrastructure/multicloud-journal.md`)

The goal is not simply to deploy an application.

The goal is to reproduce the **engineering workflow surrounding a production cloud platform**.

## Event-Driven Architecture

```mermaid
flowchart TD
    Dev[Developer]
    GW[API Gateway]
    UL[Lambda Users]
    PL[Lambda Projects]
    DB[(DynamoDB)]
    EB[EventBridge]
    SQ[SQS + DLQ]
    SN[SNS Notifications]
    WK[Worker Lambda]
    S3[(S3)]

    Dev --> GW
    GW --> UL
    GW --> PL
    UL --> DB
    PL --> DB
    DB -->|Stream| EB
    EB --> SQ
    EB --> SN
    SQ --> WK
    WK --> S3
```

## Multi-Cloud Architecture

```mermaid
flowchart TD
    Dev[Developer]
    GW["Unified Gateway :4600<br/>(AWS-only)"]
    WC[Web Console :8080]
    AMZ["Floci :4566<br/>(AWS)"]
    AZZ["Floci-AZ :4577<br/>(Azure)"]
    AWS[<b>AWS Cloud</b> — Serverless<br/>API Gateway · Lambda · DynamoDB<br/>S3 · SQS/SNS · EventBridge<br/>CloudWatch · KMS / IAM]
    AZU[<b>Azure Cloud</b> — Serverless<br/>API Management · Functions<br/>Cosmos DB · Blob Storage<br/>Queue Storage · Event Grid<br/>Azure Monitor · Key Vault/Entra]
    OBS[Observability<br/>Prometheus · Grafana]

    Dev --> GW
    Dev --> WC
    GW --> AMZ
    GW --> AZZ
    AMZ --> AWS
    AZZ --> AZU
    AWS --> OBS
    AZU --> OBS
```

## Why CloudForge?

CloudForge is intentionally more than an AWS demo project.

It is a **DevOps laboratory** designed to demonstrate how a cloud platform can be:

* provisioned across multiple clouds
* tested
* secured
* deployed
* monitored
* operated
* and recovered from failures

The project uses Floci to reproduce AWS locally, Floci-AZ to reproduce Azure locally, OpenTofu to manage infrastructure declaratively across both, a unified nginx gateway to route traffic (currently all to Floci/AWS), and Trivy to introduce security directly into the development lifecycle. The gateway's 50/50 multi-cloud routing is deferred pending Floci-AZ Function App support (see `02-infrastructure/multicloud-journal.md`).

The architecture is designed to evolve from a local development environment toward a realistic production deployment model.
