# Rule 01 — Architecture

## Documentation Is a Source of Truth

The `docs/` directory represents the current project knowledge.

Before changing architecture, read the relevant documentation.
After changing architecture, update the documentation.

Architecture changes should normally update:

```text
docs/01-architecture/
```

Infrastructure changes should normally update:

```text
docs/02-infrastructure/
```

CI/CD changes should normally update:

```text
docs/04-devops/
```

Security changes should normally update:

```text
docs/05-security/
```

Operational changes should normally update:

```text
docs/07-reliability/
```

## Architectural Decisions (ADR)

Do not silently introduce architectural decisions.

Important decisions must be documented as ADRs.

Location:

```text
docs/01-architecture/decisions/
```

ADR naming convention:

```text
ADR-XXX-short-description.md
```

An ADR should contain:

```text
# ADR-XXX — Title

## Status

## Context

## Decision

## Consequences

## Alternatives Considered
```

If a task requires a significant architectural decision, create or update the appropriate ADR.

## AWS Architecture

Every AWS service must have a clear purpose.

Before adding a new AWS service, answer:

```text
Why is this service required?

What responsibility does it have?

Why is it preferable to an existing service?

Is it supported by Floci?

How will it be tested?

How will it be observed?

What are its security implications?
```

Avoid adding AWS services simply to increase the number of services in the project.

Architectural complexity must have a reason.

## Azure Architecture

Every Azure service must have a clear purpose and be supported by the Floci-AZ emulator.

Before adding a new Azure service, answer:

```text
Why is this service required on Azure (vs. AWS)?

Is it supported by Floci-AZ?

What responsibility does it have?

How will it be tested against Floci-AZ?

What are its security implications?
```

Azure services replicate the AWS platform on a second cloud. The two clouds are kept in feature parity where the emulators allow it. Document any gap in `docs/02-infrastructure/local-environment.md`.
