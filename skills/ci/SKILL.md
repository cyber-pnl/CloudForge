# Skill — CI

## When to use

Use this skill when modifying `.github/workflows/ci.yml` or changing pipeline behavior.

## Constraints

The project intentionally uses **one** CI workflow:

```text
.github/workflows/ci.yml
```

Do not create additional workflows unless the architecture explicitly changes.

## Expected stages

```text
Checkout
    ↓
Tests
    ↓
OpenTofu formatting
    ↓
OpenTofu validation
    ↓
Trivy
    ↓
Floci
    ↓
OpenTofu plan
    ↓
Integration tests
```

## Principles

* Fail fast on deterministic validation failures.
* Do not hide errors.
* Security checks must never be disabled to make CI pass.
* Any stage change must be reflected in `docs/04-devops/ci.md`.

## Procedure

1. Read `docs/04-devops/ci.md` and the current workflow file.
2. Make the smallest change consistent with the expected stages.
3. Validate workflow syntax locally if possible.
4. Update `docs/04-devops/ci.md` when stages change.
5. If a significant architectural decision is involved, add an ADR (`rules/01-architecture.md`).

## References

* Rules: `rules/07-ci.md`, `rules/03-security.md`
* Docs: `docs/04-devops/ci.md`
