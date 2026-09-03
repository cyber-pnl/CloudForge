# Roadmap

Backlog items are tracked here (see `rules/00-project.md`). Each task should have an identifier, objective, acceptance criteria, dependencies and validation requirements.

## Phase 1 — Foundation

* [x] Repository setup
* [x] Docker Compose
* [x] Floci integration
* [x] OpenTofu project
* [x] AWS provider configuration
* [x] Basic S3 infrastructure

## Phase 2 — Core Infrastructure

* [x] DynamoDB
* [x] Lambda
* [x] API Gateway
* [x] IAM
* [x] SQS
* [x] SNS

## Phase 3 — Event-driven Architecture

* [x] DynamoDB Streams
* [x] EventBridge
* [x] Worker Lambda
* [x] Dead Letter Queue
* [x] Retry strategy

## Phase 4 — Application

* [x] Users API
* [x] Projects API
* [x] Authentication model
* [x] Project lifecycle
* [x] S3 artifact storage

## Phase 5 — CI

* [x] GitHub Actions
* [x] Unit tests
* [x] OpenTofu formatting
* [x] OpenTofu validation
* [x] OpenTofu plan
* [x] Floci integration tests

## Phase 6 — DevSecOps

* [x] Trivy filesystem scan
* [x] IaC misconfiguration scan
* [x] Secret detection
* [x] Dependency scanning
* [x] Security gates

## Phase 7 — Observability

* [x] CloudWatch logs
* [x] Metrics
* [x] Alarms
* [x] SQS monitoring
* [x] Lambda monitoring
* [x] Grafana / Prometheus

## Phase 8 — Reliability

* [x] Failure injection
* [x] Incident scenarios
* [x] Runbooks
* [x] Recovery procedures
* [x] Post-mortems

## Phase 9 — Production Simulation

* [x] Staging environment
* [x] Production environment
* [x] Deployment strategy
* [x] Rollback strategy
* [x] Disaster recovery scenario

## Phase 10 — Multi-Cloud (Azure via Floci-AZ)

* [x] Floci-AZ emulator probes (capabilities, routes, provider apply)
* [x] Multi-cloud topology decision (ADR-005)
* [x] Floci-AZ service in the local environment
* [x] Azure warm-standby stack provisioned with OpenTofu
* [x] Multi-cloud CI validation (single workflow constraint kept)
* [x] Documentation (emulator quirks, Azure extension)
* [x] Unified cloud gateway (nginx on :4600, X-Region header or random split)

## Phase 11 — Azure Replication

> Replicate the CloudForge application on Azure using managed-service
> equivalents instead of IaaS primitives. Each phase maps one layer of the
> existing AWS stack to its Azure counterpart via Floci-AZ and the azurerm
> provider.

### Phase 11.1 — Foundations

* [x] Floci-AZ compose environment and `dev-az` configuration
* [x] azurerm provider setup in OpenTofu
* [x] Cosmos DB for DynamoDB-equivalent persistence
* [x] Blob Storage for S3-equivalent object storage
* [x] Key Vault for secrets management

### Phase 11.2 — Compute & API

* [ ] Azure Functions for Lambda-equivalent compute
* [ ] API Management for API Gateway-equivalent routing

### Phase 11.3 — Messaging

* [ ] Queue Storage for SQS-equivalent queues
* [ ] Event Grid for EventBridge-equivalent event routing

### Phase 11.4 — Observability & Security

* [ ] Azure Monitor and Log Analytics for CloudWatch-equivalent observability
* [ ] Entra ID for IAM-equivalent access control

### Phase 11.5 — Gateway

* [ ] Unified cloud gateway serving 50/50 AWS/Azure traffic split

### Phase 11.6 — CI/CD

* [ ] CI pipeline extended with Azure environment validation

### Phase 11.7 — Documentation & Cleanup

* [ ] ADR-006: Azure managed-service replication strategy
