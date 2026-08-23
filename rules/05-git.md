# Rule 05 — Git

## Changes

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

## Commits

Upon completing a task, agents are expected to commit the work with a conventional commit message.

Format:

```text
<type>(<scope>): short imperative description
```

Allowed types:

| Type       | Use for                                  |
| ---------- | ---------------------------------------- |
| `feat`     | New feature or infrastructure capability |
| `fix`      | Bug fix                                  |
| `docs`     | Documentation only                       |
| `refactor` | Code change that neither fixes nor adds  |
| `test`     | Tests only                               |
| `ci`       | CI workflow changes                      |
| `build`    | Build system, Docker, dependencies        |
| `chore`    | Maintenance, tooling, repository hygiene |
| `perf`     | Performance improvement                  |
| `style`    | Formatting only                          |
| `revert`   | Reverting a previous commit              |

Scope (optional) should identify the affected area:

```text
infrastructure, app, tests, ci, security, docs, rules, skills
```

Examples:

```text
feat(infrastructure): add dynamodb module with streams
fix(app): validate user id in projects handler
docs(rules): add conventional commit policy
ci: add trivy scan stage before tofu plan
chore: pin floci image version in compose file
```

Commit rules:

* Subject line in English, imperative mood, ideally ≤ 72 characters.
* One logical purpose per commit.
* Never commit secrets.
* Never rewrite project history unless explicitly requested.
* If a task spans multiple logical purposes, split it into multiple commits.
