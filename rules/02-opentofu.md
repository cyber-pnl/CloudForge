# Rule 02 — OpenTofu

## Declarative Infrastructure

CloudForge uses **OpenTofu**.

Infrastructure MUST be managed declaratively.

Do not manually create infrastructure when it belongs in OpenTofu.

Do not introduce AWS resources directly through CLI commands as a replacement for IaC.

The desired workflow is:

```text
OpenTofu (AWS)
    ↓
Floci
    ↓
AWS-compatible infrastructure
```

For Azure:

```text
OpenTofu (azurerm provider)
    ↓
Floci-AZ
    ↓
Azure-compatible infrastructure
```

Never:

```text
Manual AWS CLI
    ↓
Infrastructure
```

unless the action is explicitly part of a test, diagnostic procedure or documented operational workflow.

## Validation

Every infrastructure change must be validated.

At minimum:

```bash
tofu fmt -check
tofu validate
tofu plan
```

When modifying an existing environment, inspect the plan carefully.

Do not blindly apply a plan.

Pay particular attention to:

* resource deletion
* replacement
* IAM changes
* security-sensitive configuration
* data loss
* state changes

## Destructive Operations

Agents must be particularly careful with:

```bash
tofu destroy
docker compose down -v
rm -rf
git reset --hard
git clean
```

Do not perform destructive operations unless required by the task or necessary for a clean, reproducible test environment.

Before destructive infrastructure operations, understand what will be removed.
