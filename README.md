Oui. Je partirais sur un README **orienté projet professionnel / portfolio DevOps**, pas un README qui ressemble à un simple TP AWS.

J'ai aussi adapté le projet à **OpenTofu + Trivy + Floci**, avec **un seul workflow `ci.yml`**. OpenTofu fournit notamment `fmt`, `validate`, `plan` et `apply`, et `tofu validate` est explicitement adapté à une utilisation dans une CI. ([OpenTofu][1]) Trivy peut scanner le filesystem pour les vulnérabilités, mauvaises configurations et secrets. ([Trivy][2]) Floci expose quant à lui un endpoint AWS local sur `localhost:4566` et documente la compatibilité OpenTofu. ([GitHub][3])

# ☁️ CloudForge

> **Production-grade DevOps laboratory built on a local AWS environment with Floci, OpenTofu and Docker.**

CloudForge is a cloud-native platform designed to reproduce a realistic AWS production environment locally.

The project combines **Infrastructure as Code, CI/CD, security scanning, containerization, event-driven architecture and observability** in order to demonstrate modern DevOps practices without requiring a real AWS account.

The entire infrastructure can be provisioned locally using **Floci + OpenTofu**, while the CI pipeline validates infrastructure, scans the repository and executes automated tests.

---

## 🎯 Project Goals

CloudForge is designed around five main objectives:

* 🏗️ Build a realistic AWS architecture
* ⚙️ Manage infrastructure entirely with **OpenTofu**
* 🔄 Implement a complete **CI pipeline**
* 🔐 Integrate **DevSecOps practices with Trivy**
* 🧪 Test AWS infrastructure locally using **Floci**

The goal is not simply to deploy an application.

The goal is to reproduce the **engineering workflow surrounding a production cloud platform**.

---

# 🏛️ Architecture

The application follows an event-driven AWS architecture.

```text
                              ┌──────────────────┐
                              │    Developer     │
                              └────────┬─────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │     API Gateway  │
                              └────────┬─────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │                           │
                         ▼                           ▼
                 ┌──────────────┐           ┌──────────────┐
                 │ Lambda Users │           │Lambda Projects│
                 └──────┬───────┘           └──────┬───────┘
                        │                           │
                        └────────────┬──────────────┘
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
                              │ EventBridge  │
                              └──────┬───────┘
                                     │
                         ┌───────────┴───────────┐
                         │                       │
                         ▼                       ▼
                  ┌─────────────┐         ┌─────────────┐
                  │     SQS     │         │     SNS     │
                  │     + DLQ   │         │ Notifications│
                  └──────┬──────┘         └─────────────┘
                         │
                         ▼
                  ┌─────────────┐
                  │Worker Lambda│
                  └──────┬──────┘
                         │
                         ▼
                  ┌─────────────┐
                  │     S3      │
                  └─────────────┘
```

---

# ☁️ AWS Services

CloudForge intentionally uses several AWS services to demonstrate different cloud patterns.

| Service             | Purpose                      |
| ------------------- | ---------------------------- |
| API Gateway         | Public HTTP API              |
| Lambda              | Serverless application logic |
| DynamoDB            | Application data             |
| DynamoDB Streams    | Event generation             |
| EventBridge         | Event routing                |
| SQS                 | Asynchronous processing      |
| SQS DLQ             | Failed message handling      |
| SNS                 | Notifications                |
| S3                  | Object storage               |
| IAM                 | Access control               |
| CloudWatch          | Logs and metrics             |
| Secrets Manager     | Application secrets          |
| SSM Parameter Store | Configuration                |

The infrastructure is executed locally through **Floci**, which provides AWS-compatible APIs on `localhost:4566`. ([GitHub][3])

---

# 🧰 Technology Stack

## Infrastructure

* [Floci](https://github.com/floci-io/floci)
* [OpenTofu](https://opentofu.org/)
* AWS Provider
* Docker
* Docker Compose

## Application

* Python
* AWS SDK / boto3
* REST API
* Lambda

## DevOps

* Git
* GitHub
* GitHub Actions
* OpenTofu
* Docker

## Security

* Trivy
* Dependency scanning
* Filesystem scanning
* IaC misconfiguration scanning
* Secret detection

## Testing

* Pytest
* OpenTofu validation
* OpenTofu plan
* Integration tests
* End-to-end tests

---

# 📁 Repository Structure

```text
cloudforge/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│   ├── users/
│   │   ├── handler.py
│   │   └── service.py
│   │
│   ├── projects/
│   │   ├── handler.py
│   │   └── service.py
│   │
│   └── shared/
│
├── lambdas/
│   ├── users/
│   ├── projects/
│   └── worker/
│
├── infrastructure/
│   ├── modules/
│   │   ├── api-gateway/
│   │   ├── dynamodb/
│   │   ├── eventbridge/
│   │   ├── iam/
│   │   ├── lambda/
│   │   ├── s3/
│   │   ├── sns/
│   │   └── sqs/
│   │
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── prod/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── docker/
│   └── ...
│
├── docs/
│   ├── architecture/
│   ├── deployment/
│   ├── runbooks/
│   └── incidents/
│
├── scripts/
│
├── docker-compose.yml
├── Makefile
├── README.md
└── .gitignore
```

---

# 🏗️ Infrastructure as Code

CloudForge uses **OpenTofu** as its Infrastructure as Code engine.

The infrastructure is divided into reusable modules.

```text
infrastructure/
│
├── modules/
│   ├── lambda/
│   ├── dynamodb/
│   ├── s3/
│   ├── sqs/
│   ├── sns/
│   └── api-gateway/
│
└── environments/
    ├── dev/
    ├── staging/
    └── prod/
```

Each environment consumes the same reusable modules with environment-specific configuration.

```text
                    ┌───────────────┐
                    │   Modules     │
                    └───────┬───────┘
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
           DEV           STAGING          PROD
```

OpenTofu provides the standard workflow used by the project:

```bash
tofu fmt
tofu init
tofu validate
tofu plan
tofu apply
```

`tofu fmt` enforces canonical OpenTofu formatting, while `tofu validate` checks the configuration for syntactic and internal consistency. ([OpenTofu][4])

---

# 🐳 Local AWS Environment

Floci provides the local AWS environment.

Start the environment with:

```bash
docker compose up -d
```

The AWS endpoint is:

```text
http://localhost:4566
```

Example:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

The same principle is used by OpenTofu:

```text
OpenTofu
    │
    │ AWS API
    ▼
Floci :4566
    │
    ├── S3
    ├── Lambda
    ├── DynamoDB
    ├── SQS
    ├── SNS
    ├── EventBridge
    └── API Gateway
```

Floci's compatibility suite includes dedicated OpenTofu workflows and validates `init → validate → plan → apply → destroy` against the emulator. ([GitHub][5])

---

# 🔄 CI Pipeline

CloudForge intentionally uses **one GitHub Actions workflow**:

```text
.github/
└── workflows/
    └── ci.yml
```

The workflow is responsible for validating the complete project.

```text
                    Pull Request / Push
                            │
                            ▼
                    ┌───────────────┐
                    │   Checkout    │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │   Lint / Test │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │ OpenTofu fmt  │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │ OpenTofu      │
                    │ validate      │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │    Trivy      │
                    │ Security Scan │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │     Floci     │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │ OpenTofu Plan │
                    └───────┬───────┘
                            ▼
                    ┌───────────────┐
                    │ Integration   │
                    │ Tests         │
                    └───────────────┘
```

The pipeline follows the principle:

> **Fail fast, validate early, never deploy untested infrastructure.**

---

# 🔐 DevSecOps

Security is integrated directly into the CI pipeline.

Trivy is used to scan the repository for:

* vulnerabilities
* infrastructure misconfigurations
* secrets
* dependency issues

Example:

```bash
trivy fs .
```

Trivy's filesystem scanner supports vulnerability, misconfiguration, secret and license scanning. ([Trivy][2])

The objective is to prevent insecure infrastructure from reaching the deployment stage.

```text
Developer
    │
    ▼
Pull Request
    │
    ▼
Trivy
    │
    ├── Vulnerabilities
    ├── Secrets
    ├── IaC Misconfiguration
    └── Dependencies
    │
    ▼
OpenTofu Validation
    │
    ▼
Integration Tests
```

---

# 🧪 Testing Strategy

CloudForge follows multiple testing levels.

## Unit Tests

Application logic is tested independently.

```bash
pytest tests/unit
```

## Infrastructure Validation

```bash
tofu fmt -check
tofu validate
```

## Infrastructure Plan

```bash
tofu plan
```

## Integration Tests

Integration tests run against the local Floci environment.

```text
Test
 │
 ▼
API Gateway
 │
 ▼
Lambda
 │
 ▼
DynamoDB
 │
 ▼
EventBridge
 │
 ▼
SQS
 │
 ▼
Worker Lambda
```

## End-to-End Tests

The complete business workflow is tested from the API entry point to the final storage/event processing.

---

# 🌍 Environments

CloudForge uses three logical environments.

### Development

Used for local development and automated validation.

```text
Developer → Floci → OpenTofu
```

### Staging

Used to validate the complete platform before production.

```text
GitHub → CI → Floci → OpenTofu
```

### Production

Represents the desired production architecture.

The project is initially executed entirely locally. The infrastructure is intentionally structured so that a future migration to real AWS can be explored without redesigning the entire architecture.

---

# 🚨 Reliability & Failure Scenarios

CloudForge is also designed as an SRE/DevOps laboratory.

The project includes controlled failure scenarios.

Example:

```text
Worker Lambda
     │
     X
   FAILURE
     │
     ▼
     SQS
     │
     ▼
    DLQ
     │
     ▼
CloudWatch Alarm
     │
     ▼
 Incident
```

Example incident:

> **INC-001 — Worker Lambda unavailable**

The incident documentation should contain:

1. Detection
2. Impact
3. Investigation
4. Root cause
5. Remediation
6. Recovery
7. Prevention
8. Post-mortem

This allows the project to demonstrate not only deployment skills but also **operational maturity**.

---

# 📊 Observability

The platform is designed to expose:

* Lambda execution logs
* API request metrics
* Lambda errors
* Lambda duration
* SQS queue depth
* DLQ messages
* application errors
* infrastructure events

The long-term observability architecture is:

```text
AWS Services
     │
     ▼
CloudWatch
     │
     ├── Logs
     ├── Metrics
     └── Alarms
           │
           ▼
      Observability
```

Grafana / Prometheus can be introduced later as an additional observability layer.

---

# 🛡️ Security Principles

The project follows several security principles.

### Least privilege

IAM policies should provide only the permissions required by each Lambda or service.

### No secrets in Git

Secrets must never be committed.

```text
❌ AWS_ACCESS_KEY_ID=...
❌ AWS_SECRET_ACCESS_KEY=...
❌ database_password=...
```

Local development should use non-production credentials and environment-specific configuration.

### Infrastructure scanning

Every OpenTofu change should pass the Trivy security stage.

### Immutable builds

Application artifacts should be built once and promoted between environments rather than rebuilt differently for each environment.

---

# 🚀 Getting Started

## Requirements

Install:

* Docker
* Docker Compose
* OpenTofu
* AWS CLI
* Python
* Git
* Trivy

Verify:

```bash
docker --version
tofu version
aws --version
python --version
trivy --version
```

---

## 1. Clone the repository

```bash
git clone https://github.com/<your-user>/cloudforge.git

cd cloudforge
```

---

## 2. Start Floci

```bash
docker compose up -d
```

Verify that Floci is running:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

---

## 3. Initialize OpenTofu

```bash
cd infrastructure/environments/dev

tofu init
```

---

## 4. Validate the infrastructure

```bash
tofu fmt -check
tofu validate
```

---

## 5. Review the infrastructure plan

```bash
tofu plan
```

---

## 6. Deploy locally

```bash
tofu apply
```

---

## 7. Run tests

From the repository root:

```bash
pytest
```

---

## 8. Run security scans

```bash
trivy fs .
```

---

# 🧹 Cleanup

Destroy the local infrastructure:

```bash
tofu destroy
```

Stop Floci:

```bash
docker compose down
```

---

# 📋 Makefile

To simplify the developer workflow, the project exposes common commands through a `Makefile`.

Example:

```bash
make up
make init
make fmt
make validate
make plan
make apply
make test
make security
make destroy
```

The goal is to make the project usable without requiring developers to remember every underlying command.

---

# 🗺️ Roadmap

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

---

# 📚 DevOps Skills Demonstrated

This project demonstrates practical experience with:

```text
Cloud
├── AWS architecture
├── Serverless
├── Event-driven architecture
└── Cloud-native services

Infrastructure
├── OpenTofu
├── Infrastructure as Code
├── Modules
└── Environment management

Containers
├── Docker
├── Docker Compose
└── Containerized testing

CI/CD
├── GitHub Actions
├── Automated testing
├── Infrastructure validation
└── Deployment workflows

DevSecOps
├── Trivy
├── IaC scanning
├── Secret detection
└── Dependency scanning

Testing
├── Unit tests
├── Integration tests
└── End-to-end tests

Observability
├── Logs
├── Metrics
├── Alerts
└── Incident response

SRE
├── Failure scenarios
├── Runbooks
├── Recovery
└── Post-mortems
```

---

# 🎓 Why CloudForge?

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

---

# 📄 License

This project is intended for educational and portfolio purposes.

License: MIT

### Pour le `ci.yml`

Je garderais effectivement **un seul fichier** au départ. Il deviendra le point central du projet :

```text
.github/workflows/ci.yml
```

Et je structurerais le workflow autour de **6 étapes** :

```text
1. checkout
      ↓
2. application tests
      ↓
3. OpenTofu fmt + validate
      ↓
4. Trivy
      ↓
5. Start Floci + OpenTofu plan
      ↓
6. Integration tests
```


[1]: https://opentofu.org/docs/cli/commands/validate/?utm_source=chatgpt.com "Command: validate | OpenTofu"
[2]: https://trivy.dev/docs/latest/target/filesystem/?utm_source=chatgpt.com "Filesystem - Trivy"
[3]: https://github.com/floci-io/floci?aid=recJDz3KDvQOXHHuO&utm_source=chatgpt.com "GitHub - floci-io/floci: Light, fluffy, and always free - The AWS Local Emulator alternative · GitHub"
[4]: https://opentofu.org/docs/cli/commands/fmt/?utm_source=chatgpt.com "Command: fmt | OpenTofu"
[5]: https://github.com/floci-io/floci-compatibility-tests?utm_source=chatgpt.com "GitHub - floci-io/floci-compatibility-tests: Test project for floci · GitHub"
