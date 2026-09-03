# Documentation

The `docs/` directory is the source of truth for the current project knowledge. Before changing architecture, read the relevant documentation. After changing architecture, update it (see `rules/01-architecture.md`).

## Index

```text
docs/
├── 01-architecture/          Platform architecture
│   ├── overview.md           Goals and event-driven design
│   ├── aws-services.md       AWS services and their purpose
│   └── decisions/            Architecture Decision Records (ADR)
├── 02-infrastructure/        Infrastructure as Code
│   ├── opentofu.md           Modules, environments, workflow
│   └── local-environment.md  Floci + Floci-AZ usage and emulator notes
├── 04-devops/
│   ├── ci.md                 CI pipeline stages and principles
│   ├── deployment-strategy.md Environments, promotion, rollback and DR
│   └── getting-started.md    Full local setup guide
├── 05-security/
│   └── principles.md         DevSecOps principles
├── 07-reliability/
│   ├── failure-scenarios.md  Controlled failure scenarios
│   ├── incidents/             Incident reports (INC-001, INC-002)
│   ├── observability.md      Logs, metrics, alarms
│   └── runbooks.md           Operational procedures
└── 08-roadmap/
    └── roadmap.md            Phases and backlog
```
