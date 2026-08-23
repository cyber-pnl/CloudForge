# Rule 06 — Agent Behavior

## Mandatory Workflow

Before modifying the repository, agents MUST follow this workflow:

```text
Understand
    ↓
Inspect
    ↓
Plan
    ↓
Implement
    ↓
Validate
    ↓
Test
    ↓
Security Scan
    ↓
Document
    ↓
Review
```

An agent must not start implementing a non-trivial task immediately.

## Read Before Acting

Before making changes, inspect:

1. `AGENTS.md`
2. Relevant files under `rules/`
3. Relevant files under `docs/`
4. Relevant `skills/`
5. Existing implementation
6. Existing tests

Do not assume that an architecture or implementation does not exist simply because it was not mentioned in the task.

Search the repository first.

## Rules Precedence

When a rule conflicts with an implementation preference, the rule takes precedence.

Agents must not bypass a rule without an explicit architectural decision.

## Skills

The `skills/` directory contains project-specific procedures.

Use the appropriate skill before performing specialized work.

Do not invent a project-specific procedure when an existing skill already covers the task.

## Failure Handling

If something fails:

Do not immediately work around the failure.

First:

```text
Observe
   ↓
Reproduce
   ↓
Understand
   ↓
Identify root cause
   ↓
Fix
   ↓
Test
```

Do not:

* disable the test
* disable Trivy
* remove validation
* ignore an OpenTofu error
* silently change architecture
* add arbitrary retries without understanding the failure

## Ambiguous Requirements

If the task is ambiguous but a safe interpretation exists:

1. Inspect existing architecture.
2. Follow existing conventions.
3. Choose the smallest change consistent with the project.
4. Document the assumption.

If the ambiguity could result in:

* data loss
* security risk
* architectural divergence
* destructive infrastructure changes

stop and request clarification.

## Agent Communication

When reporting completed work, summarize:

```text
## Implemented

What changed.

## Validation

Commands executed and results.

## Security

Trivy/security results.

## Documentation

Documents updated.

## Notes

Important assumptions, limitations or follow-up work.
```

Never report only:

```text
Done.
```

## Final Verification

Before finishing any task, ask:

```text
Did I understand the existing architecture?

Did I follow the rules?

Did I use the appropriate skill?

Did I inspect the documentation?

Did I introduce an architectural decision?

Did I update the documentation?

Did I test the implementation?

Did I run the relevant OpenTofu checks?

Did I run the relevant Trivy scan?

Did I introduce secrets?

Did I modify unrelated files?

Can another engineer understand this change?
```

If any answer is "no", the task should not be considered complete.
