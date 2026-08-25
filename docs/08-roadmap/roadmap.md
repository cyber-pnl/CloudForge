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

## Phase 10 — Multi-Cloud (Scaleway via Feint)

* [x] Feint emulator probes (capabilities, routes, provider apply)
* [x] Multi-cloud topology decision (ADR-005)
* [x] Feint service in the local environment
* [x] Scaleway warm-standby stack provisioned with OpenTofu
* [x] Multi-cloud CI validation (single workflow constraint kept)
* [x] Documentation (emulator quirks, DR extension)
* [x] Unified cloud proxy (nginx on :4600, X-Region header or random split)

## Phase 11 — DR Workload Containerization

> If Floci goes down, the Scaleway DR site must be able to run the actual
> application — not just provision empty infrastructure. This phase bridges
> the gap between "IaaS primitives available in Feint" and "managed services
> used by CloudForge on AWS".

### Service mapping (AWS managed → Scaleway IaaS)

| AWS Service | Scaleway equivalent | Implementation |
|---|---|---|
| API Gateway | nginx reverse proxy | Container on instance |
| Lambda (3 functions) | Docker containers | Python images on instance |
| DynamoDB | PostgreSQL container | Data on block volume |
| DynamoDB Streams | Redis pub/sub | Container on instance |
| S3 | Block volume filesystem | Mount at /data |
| SQS | Redis lists | Container on instance |
| SNS | Redis pub/sub | Container on instance |
| EventBridge | Cron worker | Container on instance |
| CloudWatch | journald + local logs | Instance filesystem |
| KMS / Secrets Manager | Vault container | Container on instance |
| SSM Parameter Store | Config files | On block volume |

* [ ] Dockerfiles for Lambda functions (users, projects, worker)
* [ ] Docker Compose DR stack (nginx + app + PostgreSQL + Redis + Vault)
* [ ] Block volume mount and data persistence layout
* [ ] DR environment OpenTofu config (instance user_data with docker-compose)
* [ ] nginx configuration for API Gateway replacement

## Phase 12 — DR Validation and Failover

> Prove that the DR site actually works end-to-end when Floci is down.

* [ ] Data migration script (DynamoDB → PostgreSQL)
* [ ] E2E test suite against Scaleway DR stack
* [ ] DR failover runbook (step-by-step procedure)
* [ ] DR drill in CI (optional: start Floci down, run against Scaleway)
* [ ] Documentation (DR architecture, service mapping, failover procedure)
