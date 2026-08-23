# Rule 05 — Git

Use small, focused changes.

Do not mix unrelated modifications.

A change should ideally represent one logical purpose.

Good:

```text
Add DynamoDB OpenTofu module
```

Bad:

```text
Add DynamoDB + refactor API + change CI + update README
```

Avoid modifying unrelated files.

Never rewrite project history unless explicitly requested.

Never commit secrets.
