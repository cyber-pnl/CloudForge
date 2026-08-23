# Architecture Overview

CloudForge is a cloud-native platform designed to reproduce a realistic AWS production environment locally, without requiring a real AWS account.

## Project Goals

CloudForge is designed around five main objectives:

* Build a realistic AWS architecture
* Manage infrastructure entirely with **OpenTofu**
* Implement a complete **CI pipeline**
* Integrate **DevSecOps practices with Trivy**
* Test AWS infrastructure locally using **Floci**

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

## Why CloudForge?

CloudForge is intentionally more than an AWS demo project.

It is a **DevOps laboratory** designed to demonstrate how a cloud platform can be:

* provisioned
* tested
* secured
* deployed
* monitored
* operated
* and recovered from failures

The project uses Floci to reproduce AWS locally, OpenTofu to manage infrastructure declaratively, and Trivy to introduce security directly into the development lifecycle.

The architecture is designed to evolve from a local development environment toward a realistic production deployment model.
