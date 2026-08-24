# CloudForge

> **Production-grade DevOps laboratory built on a local AWS environment with Floci, OpenTofu and Docker.**

CloudForge reproduces a realistic AWS production environment locally — no real AWS account required. It combines **Infrastructure as Code, CI/CD, security scanning, containerization, event-driven architecture and observability** to demonstrate the engineering workflow surrounding a production cloud platform.

The entire infrastructure is provisioned with **OpenTofu** against **Floci** (a local AWS emulator), while a single CI pipeline validates infrastructure, scans security and runs automated tests.

---

## Key Features

* **Local AWS simulation** — Floci provides AWS-compatible APIs on `localhost:4566`
* **Infrastructure as Code** — declarative, reusable OpenTofu modules per AWS service
* **Event-driven architecture** — API Gateway → Lambda → DynamoDB → Streams → EventBridge → SQS/SNS → S3
* **Web console** — browser UI for the domain served by nginx with a same-origin API proxy
* **CI pipeline** — one GitHub Actions workflow covering lint, tests, IaC validation and integration tests
* **DevSecOps** — Trivy scans for vulnerabilities, misconfigurations and secrets at every change
* **Reliability engineering** — controlled failure scenarios, DLQs, alarms and incident documentation

---

## Business Domain

Underneath the platform engineering, CloudForge runs a small but realistic application domain: **users own projects, and projects carry artifacts**.

| Entity | Business rules |
| ------ | -------------- |
| **User** | Created with `name` + `email`; emails are unique (`409` on duplicates); full updates via PUT |
| **Project** | Must reference an existing user as `owner` (`400` otherwise); follows a strict lifecycle below |
| **Artifact** | Uploaded to a project as `filename` + `content_base64`; payload validated and size-capped; stored in S3 under `projects/{id}/` |

Projects move through an enforced state machine — an archived project never reopens:

```text
draft  ──→ active, archived
active ──→ draft, archived
archived ──→ terminal
```

Every write to users or projects flows through the event pipeline shown in the architecture diagram: a dispatcher turns each DynamoDB stream record into a domain event, and a worker persists an **immutable, timestamped trace** of every change in S3. Failed jobs retry three times, then land in a dead-letter queue that raises an alert.

Cross-cutting rules apply everywhere: every endpoint requires Bearer authentication, and all errors share one normalized `{error, message}` shape with consistent status codes.

The application logic lives in `lambdas/` (handlers plus shared `common/` modules for auth, lifecycle and responses) and is exercised by unit tests without any AWS dependency.

---

## Architecture

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
                         ▼                           ▼
                 ┌───────────────┐         ┌────────────────┐
                 │ Lambda Users  │         │Lambda Projects │
                 └──────┬────────┘         └───────┬────────┘
                        └───────────┬──────────────┘
                                    ▼
                             ┌──────────────┐
                             │   DynamoDB   │
                             └──────┬───────┘
                                 Stream
                                    ▼
                             ┌──────────────┐
                             │  EventBridge │
                             └──────┬───────┘
                        ┌───────────┴───────────┐
                        ▼                       ▼
                ┌──────────────┐       ┌───────────────┐
                │ SQS + DLQ    │       │ SNS           │
                └──────┬───────┘       │ Notifications │
                       ▼               └───────────────┘
                ┌──────────────┐
                │ Worker Lambda│
                └──────┬───────┘
                       ▼
                ┌──────────────┐
                │      S3      │
                └──────────────┘
```

All services run locally through Floci. See [docs/01-architecture/](docs/01-architecture/) for details.

---

## Technology Stack

| Category      | Tools                                                              |
| ------------- | ------------------------------------------------------------------ |
| Infrastructure| [Floci](https://github.com/floci-io/floci), [OpenTofu](https://opentofu.org/), Docker Compose |
| Application   | Python, boto3, Lambda, REST API                                    |
| DevOps        | Git, GitHub Actions                                                |
| Security      | Trivy (filesystem, IaC, secrets, dependencies)                     |
| Testing       | Pytest, `tofu fmt` / `validate` / `plan`, integration & e2e tests  |

---

## Quick Start

Requirements: Docker, Docker Compose, OpenTofu, AWS CLI, Python, Git, Trivy.

```bash
# 1. Start the local AWS environment
docker compose up -d

# 2. Initialize and validate OpenTofu
cd infrastructure/environments/dev
tofu init && tofu fmt -check && tofu validate

# 3. Review the plan, then deploy
tofu plan
tofu apply

# 4. Run tests and security scan (from repository root)
pytest
trivy fs .

# 5. Open the web console (users, projects, artifacts)
docker compose up -d webapp && make ui-url
```

Full setup guide: [docs/04-devops/getting-started.md](docs/04-devops/getting-started.md)

Cleanup:

```bash
tofu destroy
docker compose down
```

---

## Repository Structure

```text
cloudforge/
│
├── .github/workflows/ci.yml   # Single CI workflow
├── app/                       # Application code (users, projects, shared)
├── lambdas/                   # Lambda handlers (users, projects, worker)
├── infrastructure/
│   ├── modules/               # Reusable OpenTofu modules per AWS service
│   └── environments/          # dev / staging / prod configurations
├── tests/                       # unit / integration / e2e
├── webapp/                      # browser console (vanilla JS + nginx proxy)
├── docker/                      # Container assets
├── rules/                     # Mandatory project constraints (agents)
├── skills/                    # Project-specific procedures (agents)
├── docs/                      # Project knowledge base
├── docker-compose.yml         # Local Floci environment
└── Makefile                   # Common developer commands
```

---

## Documentation

| Document | Content |
| -------- | ------- |
| [Architecture overview](docs/01-architecture/overview.md) | Goals and event-driven design |
| [AWS services](docs/01-architecture/aws-services.md) | Services used and their purpose |
| [ADRs](docs/01-architecture/decisions/README.md) | Architecture decision records |
| [OpenTofu](docs/02-infrastructure/opentofu.md) | Modules, environments, workflow |
| [Local environment](docs/02-infrastructure/local-environment.md) | Floci usage |
| [Getting started](docs/04-devops/getting-started.md) | Full setup guide |
| [CI pipeline](docs/04-devops/ci.md) | Pipeline stages and principles |
| [Security principles](docs/05-security/principles.md) | DevSecOps practices |
| [Failure scenarios](docs/07-reliability/failure-scenarios.md) | Reliability engineering |
| [Observability](docs/07-reliability/observability.md) | Logs, metrics, alarms |
| [Roadmap](docs/08-roadmap/roadmap.md) | Phases and backlog |

For AI agents working on this repository, start with [AGENTS.md](AGENTS.md).

---

## Why CloudForge?

CloudForge is intentionally more than an AWS demo project.

It demonstrates how a cloud platform can be **provisioned, tested, secured, deployed, monitored, operated — and recovered from failures**, using local tooling that mirrors production workflows.

The architecture is designed to evolve from a local development environment toward a realistic production deployment model.

## License

This project is intended for educational and portfolio purposes.

License: MIT
