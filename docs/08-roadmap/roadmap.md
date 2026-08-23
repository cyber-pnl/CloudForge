# Roadmap

Backlog items are tracked here (see `rules/00-project.md`). Each task should have an identifier, objective, acceptance criteria, dependencies and validation requirements.

## Phase 1 — Foundation

* [ ] Repository setup
* [ ] Docker Compose
* [ ] Floci integration
* [ ] OpenTofu project
* [ ] AWS provider configuration
* [ ] Basic S3 infrastructure

## Phase 2 — Core Infrastructure

* [ ] DynamoDB
* [ ] Lambda
* [ ] API Gateway
* [ ] IAM
* [ ] SQS
* [ ] SNS

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
