# Rule 03 — Security

Security is mandatory.

## Security Baseline

Never:

* commit credentials
* commit private keys
* hard-code secrets
* disable security checks to make CI pass
* ignore Trivy findings without justification
* grant unnecessary IAM permissions

Use least privilege.

Prefer:

```text
specific resource
+
specific action
+
specific principal
```

over broad permissions.

Avoid:

```text
Action: "*"
Resource: "*"
```

unless explicitly justified and documented.

## Trivy

Trivy is part of the project's security gate.

Relevant scans may include:

```bash
trivy fs .
```

and infrastructure-focused scanning when appropriate.

Do not suppress a vulnerability or misconfiguration simply because it causes CI to fail.

If a finding is intentionally accepted:

1. Understand the finding.
2. Determine whether it is a false positive or accepted risk.
3. Document the reason.
4. Use the narrowest possible exception.
5. Do not weaken the entire security scan.

## Secrets

Secrets must never be committed.

Before committing, check for:

```text
AWS credentials
API keys
private keys
passwords
tokens
database credentials
JWT secrets
environment files containing secrets
```

Do not add real credentials to:

```text
.env
terraform.tfvars
*.tfstate
configuration files
documentation
tests
fixtures
```

Use examples such as:

```text
example-secret
dummy-token
test-password
```

when values are required for documentation or tests.
