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
