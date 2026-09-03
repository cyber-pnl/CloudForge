# CI Pipeline

CloudForge intentionally uses **one GitHub Actions workflow**:

```text
.github/workflows/ci.yml
```

The workflow is responsible for validating the complete project.

## Jobs

The workflow is split into six GitHub Actions **jobs** so every stage is a
separate box on the run page:

```text
  Pull Request / Push / Dispatch
        │
        ├──────────────┬──────────────┐
        ▼              ▼              ▼
 ┌─────────────┐ ┌───────────┐ ┌─────────────┐
 │ 1 · Validate│ │ 2 · Unit  │ │ 3 · Security│      (parallel)
 │     IaC     │ │   tests   │ │    gates    │
 └──────┬──────┘ └─────┬─────┘ └──────┬──────┘
        └──────────────┼──────────────┘
                       ▼
             ┌──────────────────┐
             │ 4 · Integration  │   floci → plan → apply → e2e
             │   ephemeral dev  │   → destroy (always)
             └────────┬─────────┘
                      │
        ┌─────────────┴──────────────────────┐
        ▼                                    ▼
┌──────────────────┐              ┌──────────────────────┐
│ 5 · Promote to   │              │ 6 · Multi-cloud      │
│     staging      │ (dispatch)   │  validation (Floci-AZ) │
└──────────────────┘              └──────────────────────┘
```

Jobs 1–3 are deterministic, fast checks and run in parallel for fail-fast
feedback; the integration and multi-cloud jobs only start once all three pass.
The promote job appears as "skipped" unless the run was dispatched with
`deploy_staging`.

The multi-cloud job validates the Azure DR environment against the Floci-AZ
emulator (job 6), exercising a second cloud provider through the same IaC
gates (`fmt-check`, `validate`, `plan`) in the single workflow. It stops at
**plan**: the Azure `apply` is not run because Azure Functions cannot be
provisioned (Floci-AZ does not emulate `Microsoft.Web/serverfarms`) — see
`docs/02-infrastructure/multicloud-journal.md`.

The plan validates the full provider interaction against the emulator; the apply stage deploys the stack so the integration tests can exercise real endpoints (`scripts/integration-tests.sh`). The final destroy only cleans the ephemeral runner environment — its failure never masks a pipeline failure.

Before destroying, the teardown empties `s3://cloudforge-dev-artifacts` recursively: the emulator refuses to delete a non-empty bucket, and every integration run uploads artifacts, so the destroy would otherwise always fail. The same rule applies to local cleanups — empty the bucket before running `tofu destroy`.

## Trivy gate policy

The scan runs once as a full report, then as three independent gates:

1. **Report** — every finding is printed regardless of type or severity.
2. **Secrets gate** — any secret finding fails the build. The local `terraform.tfstate` is excluded from this gate because OpenTofu stores sensitive variables there by design; the file must stay git-ignored, which the pipeline verifies explicitly.
3. **IaC misconfiguration gate** — the build fails on `HIGH` or `CRITICAL`.
4. **Dependency vulnerability gate** — the build fails on `HIGH` or `CRITICAL`. Lambda packages are built before scanning so vendored dependencies (`lambdas/*/build`) are actually inspected.

Lower severities are handled through the accepted-findings ledger in `docs/05-security/principles.md`; they must be either fixed or documented there, never ignored silently.

## Principles

* One workflow only — do not create additional workflows unless the architecture explicitly changes (`rules/07-ci.md`). Job splitting inside the single workflow is encouraged for readability.
* Fail fast on deterministic validation failures — the three fast jobs run in parallel and block the integration job.
* Do not hide errors.
* Security checks must never be disabled to make CI pass.
* Every exception to a gate is narrow (one file, one severity range) and justified in documentation.

> **Fail fast, validate early, never deploy untested infrastructure.**

Any stage change must be reflected in this document (see `skills/ci/SKILL.md`).
