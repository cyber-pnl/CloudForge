# Rule 00 — Project

## Mission

CloudForge is a production-grade DevOps laboratory.

The project simulates AWS locally using **Floci** and Scaleway using **Feint**, manages infrastructure with **OpenTofu**, validates changes through **GitHub Actions**, and integrates **DevSecOps practices with Trivy**.

The objective is to build a realistic, maintainable and reproducible cloud platform.

Agents are expected to behave like members of a professional engineering team.

Do not optimize for producing code quickly.

Optimize for:

* correctness
* maintainability
* security
* testability
* reproducibility
* observability
* architectural consistency

## Core Principle

> **Do not make the repository merely work. Make it reproducible, explainable, testable and operable.**

Agents are not expected to maximize the amount of code produced.

They are expected to improve the engineering quality of the platform.

## Code Quality

Prefer:

* simple implementations
* explicit behavior
* small modules
* reusable components
* clear names
* deterministic behavior
* strong validation

Avoid:

* unnecessary abstractions
* premature optimization
* duplicated configuration
* hidden side effects
* magic values
* undocumented workarounds

Do not introduce a framework simply because it is popular.

## Existing Code Has Priority

Before creating a new module, function, resource or utility:

Search the repository.

Ask:

```text
Does this already exist?

Can it be reused?

Can the existing implementation be extended?

Would a new abstraction duplicate existing behavior?
```

Do not duplicate existing functionality.

## Dependencies

Before introducing a dependency, evaluate:

* necessity
* maintenance status
* security
* license
* compatibility
* project complexity

Do not add dependencies for trivial functionality that can be implemented with the existing stack.

## Backlog

The project roadmap and implementation backlog are maintained under:

```text
docs/08-roadmap/
```

Agents should work on explicit backlog items whenever possible.

A task should have:

* identifier
* objective
* acceptance criteria
* dependencies
* validation requirements

Example:

```text
CF-021 — Add EventBridge integration

Acceptance criteria:

- EventBridge resource exists in OpenTofu
- Event pattern is documented
- DynamoDB events can reach EventBridge
- Integration test exists
- OpenTofu validation passes
- Trivy passes
- Architecture documentation is updated
```
