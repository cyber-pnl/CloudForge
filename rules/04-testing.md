# Rule 04 — Testing

Every code change should have an appropriate test strategy.

## Testing Levels

```text
Unit
  ↓
Integration
  ↓
End-to-End
```

Do not write tests only to satisfy coverage.

Tests should validate behavior.

Infrastructure changes should include infrastructure validation.

Application changes should include application tests.

Integration changes should include integration tests.

## Test Before Claiming Completion

An agent must not report a task as complete without validation.

Before completion, run the smallest relevant set of checks.

For infrastructure:

```bash
tofu fmt -check
tofu validate
tofu plan
```

For Python:

```bash
pytest
```

For security:

```bash
trivy fs .
```

For integration work:

```text
Start Floci
    ↓
Provision infrastructure
    ↓
Run integration tests
    ↓
Verify expected AWS behavior
```

For Scaleway DR work:

```text
Start Feint
    ↓
Provision scw-dr environment
    ↓
Run tofu validate / plan / apply
    ↓
Verify expected Scaleway behavior
```

If a test cannot be executed, explicitly report why.

Never claim that a test passed when it was not executed.
