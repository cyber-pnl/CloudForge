# Architecture Overview

CloudForge is a multi-cloud DevOps laboratory that reproduces a realistic AWS production environment locally, alongside an Azure replica — no real AWS or Azure account required.

## Project Goals

CloudForge is designed around six main objectives:

* Build a realistic **multi-cloud architecture** (AWS + Azure, replicated serverless platform)
* Manage infrastructure entirely with **OpenTofu** across both clouds
* Implement a complete **CI pipeline** (single workflow, six jobs)
* Integrate **DevSecOps practices with Trivy**
* Test AWS infrastructure locally using **Floci** and Azure using **Floci-AZ**
* Provide a **unified cloud gateway** routing 50/50 between the two clouds

The goal is not simply to deploy an application.

The goal is to reproduce the **engineering workflow surrounding a production cloud platform**.

## Event-Driven Architecture

```text
                              ┌──────────────────┐
                              │    Developer     │
                              └────────┬─────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │   API Gateway    │
                              └────────┬─────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │                           │
                         ▼                           ▼
                 ┌───────────────┐         ┌────────────────┐
                 │ Lambda Users  │         │Lambda Projects │
                 └──────┬────────┘         └───────┬────────┘
                        │                          │
                        └───────────┬──────────────┘
                                    │
                                    ▼
                             ┌──────────────┐
                             │   DynamoDB   │
                             └──────┬───────┘
                                    │
                                 Stream
                                    │
                                    ▼
                             ┌──────────────┐
                             │  EventBridge │
                             └──────┬───────┘
                                    │
                        ┌───────────┴───────────┐
                        │                       │
                        ▼                       ▼
                ┌──────────────┐       ┌───────────────┐
                │ SQS + DLQ    │       │ SNS           │
                │              │       │ Notifications │
                └──────┬───────┘       └───────────────┘
                       │
                       ▼
                ┌──────────────┐
                │ Worker Lambda│
                └──────┬───────┘
                       │
                       ▼
                ┌──────────────┐
                │      S3      │
                └──────────────┘
```

## Multi-Cloud Architecture

```text
                    ┌──────────────────┐
                    │    Developer     │
                    └────────┬─────────┘
                             │
                 ┌───────────┴───────────┐
                 ▼                       ▼
        ┌────────────────┐     ┌────────────────┐
        │ Unified Gateway│     │  Web Console   │
        │   :4600        │     │   :8080        │
        │ (50/50 split)  │     └────────────────┘
        └───────┬────────┘
                │
        ┌───────┴───────┐
        ▼               ▼
┌──────────────┐ ┌───────────────┐
│ Floci :4566  │ │ Floci-AZ :4577│
│ (AWS)        │ │ (Azure)       │
└──────┬───────┘ └───────┬───────┘
       │                  │
       ▼                  ▼
┌──────────────┐ ┌───────────────┐
│  AWS Cloud   │ │  Azure Cloud  │
│  Serverless  │ │  Serverless   │
│              │ │               │
│  API Gateway │ │ API Management│
│  Lambda      │ │ Functions     │
│  DynamoDB    │ │ Cosmos DB     │
│  S3          │ │ Blob Storage  │
│  SQS / SNS   │ │ Queue Storage │
│  EventBridge │ │ Event Grid    │
│  CloudWatch  │ │ Azure Monitor │
│  KMS / IAM   │ │ Key Vault/Entra│
└──────┬───────┘ └───────────────┘
       │
       ▼
┌──────────────┐
│ Observability│
│ Prometheus   │
│ Grafana      │
└──────────────┘
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

The project uses Floci to reproduce AWS locally, Floci-AZ to reproduce Azure locally, OpenTofu to manage infrastructure declaratively across both, a unified nginx gateway to route 50/50 between them, and Trivy to introduce security directly into the development lifecycle.

The architecture is designed to evolve from a local development environment toward a realistic production deployment model.
