# Architecture Overview

CloudForge is a multi-cloud DevOps laboratory that reproduces a realistic AWS production environment locally, with a warm-standby disaster-recovery site on Scaleway — no real AWS account required.

## Project Goals

CloudForge is designed around six main objectives:

* Build a realistic **multi-cloud architecture** (primary AWS + secondary Scaleway)
* Manage infrastructure entirely with **OpenTofu** across both clouds
* Implement a complete **CI pipeline** (single workflow, six jobs)
* Integrate **DevSecOps practices with Trivy**
* Test AWS infrastructure locally using **Floci** and Scaleway using **Feint**
* Provide a **unified cloud endpoint** routing to either backend

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
        │  Unified Proxy │     │  Web Console   │
        │   :4600        │     │   :8080        │
        └───────┬────────┘     └───────┬────────┘
                │                      │
         ┌──────┴──────┐               │
         ▼             ▼               │
┌────────────────┐ ┌────────────────┐  │
│   Floci :4566  │ │  Feint :4599   │  │
│   (AWS)        │ │  (Scaleway)    │  │
└───────┬────────┘ └───────┬────────┘  │
        │                  │           │
        ▼                  ▼           │
┌────────────────┐ ┌────────────────┐  │
│  Primary Cloud │ │  DR Site       │  │
│  Serverless    │ │  IaaS          │  │
│                │ │                │  │
│  API Gateway   │ │  VPC           │  │
│  Lambda        │ │  Instance      │  │
│  DynamoDB      │ │  Block Vol.    │  │
│  S3            │ │  IAM           │  │
│  SQS / SNS     │ │                │  │
│  EventBridge   │ │                │  │
│  CloudWatch    │ │                │  │
└───────┬────────┘ └────────────────┘  │
        │                              │
        ▼                              │
┌────────────────┐                     │
│ Observability  │                     │
│ Prometheus     │                     │
│ Grafana        │                     │
└────────────────┘                     │
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

The project uses Floci to reproduce AWS locally, Feint to reproduce Scaleway locally, OpenTofu to manage infrastructure declaratively across both, and Trivy to introduce security directly into the development lifecycle.

The architecture is designed to evolve from a local development environment toward a realistic production deployment model.
