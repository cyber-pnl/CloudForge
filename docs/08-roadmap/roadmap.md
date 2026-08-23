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

* [ ] DynamoDB Streams
* [ ] EventBridge
* [ ] Worker Lambda
* [ ] Dead Letter Queue
* [ ] Retry strategy

## Phase 4 — Application

* [ ] Users API
* [ ] Projects API
* [ ] Authentication model
* [ ] Project lifecycle
* [ ] S3 artifact storage

## Phase 5 — CI

* [ ] GitHub Actions
* [ ] Unit tests
* [ ] OpenTofu formatting
* [ ] OpenTofu validation
* [ ] OpenTofu plan
* [ ] Floci integration tests

## Phase 6 — DevSecOps

* [ ] Trivy filesystem scan
* [ ] IaC misconfiguration scan
* [ ] Secret detection
* [ ] Dependency scanning
* [ ] Security gates

## Phase 7 — Observability

* [ ] CloudWatch logs
* [ ] Metrics
* [ ] Alarms
* [ ] SQS monitoring
* [ ] Lambda monitoring
* [ ] Grafana / Prometheus

## Phase 8 — Reliability

* [ ] Failure injection
* [ ] Incident scenarios
* [ ] Runbooks
* [ ] Recovery procedures
* [ ] Post-mortems

## Phase 9 — Production Simulation

* [ ] Staging environment
* [ ] Production environment
* [ ] Deployment strategy
* [ ] Rollback strategy
* [ ] Disaster recovery scenario
