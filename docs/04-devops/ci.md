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
                │    Apply      │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │ Integration   │
                │ Tests         │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │   Destroy     │
                │  (ephemeral)  │
                └───────────────┘
```

The plan validates the full provider interaction against the emulator; the apply stage deploys the stack so the integration tests can exercise real endpoints (`scripts/integration-tests.sh`). The final destroy only cleans the ephemeral runner environment — its failure never masks a pipeline failure.

## Trivy gate policy

The scan runs once as a full report, then as three independent gates:

1. **Report** — every finding is printed regardless of type or severity.
2. **Secrets gate** — any secret finding fails the build. The local `terraform.tfstate` is excluded from this gate because OpenTofu stores sensitive variables there by design; the file must stay git-ignored, which the pipeline verifies explicitly.
3. **IaC misconfiguration gate** — the build fails on `HIGH` or `CRITICAL`.
4. **Dependency vulnerability gate** — the build fails on `HIGH` or `CRITICAL`. Lambda packages are built before scanning so vendored dependencies (`lambdas/*/build`) are actually inspected.

Lower severities are handled through the accepted-findings ledger in `docs/05-security/principles.md`; they must be either fixed or documented there, never ignored silently.

## Principles

* One workflow only — do not create additional workflows unless the architecture explicitly changes (`rules/07-ci.md`).
* Fail fast on deterministic validation failures.
* Do not hide errors.
* Security checks must never be disabled to make CI pass.
* Every exception to a gate is narrow (one file, one severity range) and justified in documentation.

> **Fail fast, validate early, never deploy untested infrastructure.**

Any stage change must be reflected in this document (see `skills/ci/SKILL.md`).
