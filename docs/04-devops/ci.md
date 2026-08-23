# CI Pipeline

CloudForge intentionally uses **one GitHub Actions workflow**:

```text
.github/workflows/ci.yml
```

The workflow is responsible for validating the complete project.

## Stages

```text
                Pull Request / Push
                        │
                        ▼
                ┌───────────────┐
                │   Checkout    │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │  Lint / Test  │
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

## Principles

* One workflow only — do not create additional workflows unless the architecture explicitly changes (`rules/07-ci.md`).
* Fail fast on deterministic validation failures.
* Do not hide errors.
* Security checks must never be disabled to make CI pass.

> **Fail fast, validate early, never deploy untested infrastructure.**

Any stage change must be reflected in this document (see `skills/ci/SKILL.md`).
