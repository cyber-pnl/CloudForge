# Architecture Decision Records

This directory contains the Architecture Decision Records (ADRs) for CloudForge.

Architectural decisions must never be introduced silently — see `rules/01-architecture.md`.

## Convention

File name:

```text
ADR-XXX-short-description.md
```

Template:

```markdown
# ADR-XXX — Title

## Status

Proposed / Accepted / Deprecated / Superseded by ADR-YYY

## Context

What is the problem or forcing change?

## Decision

What was decided?

## Consequences

What becomes easier or harder?

## Alternatives Considered

Which options were rejected and why?
```

## Index

| ADR | Title | Status |
| --- | ----- | ------ |
| [ADR-001](ADR-001-sqs-over-sns.md) | SQS fanout over SNS delivery | Accepted |
| [ADR-002](ADR-002-application-level-auth.md) | Application-level authentication | Accepted |
| [ADR-003](ADR-003-observability-stack.md) | Observability stack | Accepted |
| [ADR-004](ADR-004-environment-topology.md) | Environment topology and promotion model | Accepted |
| [ADR-006](ADR-006-multicloud-azure.md) | Multi-cloud topology: Azure replica via Floci-AZ | Accepted |
