# Skill — Testing

## When to use

Use this skill before claiming any task complete, and when writing or modifying tests.

## Test matrix by change type

| Change type            | Required checks                                             |
| ---------------------- | ----------------------------------------------------------- |
| Python application     | `pytest`                                                     |
| OpenTofu               | `tofu fmt -check` && `tofu validate` && `tofu plan`          |
| Any repository change  | `trivy fs .`                                                 |
| Integration work       | Floci up → provision → integration tests → verify behavior   |
| Scaleway DR work       | Feint up → tofu validate/plan/apply on scw-dr → verify      |

## Testing levels

```text
Unit
  ↓
Integration
  ↓
End-to-End
```

* Unit tests validate application logic independently: `pytest tests/unit`.
* Infrastructure validation uses OpenTofu commands (see OpenTofu skill).
* Integration tests run against the local Floci environment.
* End-to-end tests cover the full business workflow from API entry point to storage/event processing.

## Rules

* Tests must validate behavior, not coverage numbers.
* Run the smallest relevant set of checks before completion.
* If a test cannot be executed, explicitly report why.
* Never claim that a test passed when it was not executed.
* If a test fails: observe, reproduce, understand, fix — never disable it (see `rules/06-agent.md`).

## References

* Rules: `rules/04-testing.md`, `rules/06-agent.md`
* Docs: `docs/04-devops/ci.md`
