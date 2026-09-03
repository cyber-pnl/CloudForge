# Skill — DevSecOps

## When to use

Use this skill for security scanning, handling Trivy findings, verifying secrets hygiene, or reviewing IAM policies.

## Scans

Filesystem scan (minimum gate):

```bash
trivy fs .
```

Add infrastructure-focused scanning when appropriate.

## Handling a finding

Do not suppress a finding simply because it makes CI fail.

1. Understand the finding.
2. Determine whether it is a false positive or an accepted risk.
3. Document the reason.
4. Use the narrowest possible exception.
5. Do not weaken the entire security scan.

## Secrets hygiene

Before any commit, check for:

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

Never place real credentials in `.env`, `terraform.tfvars`, `*.tfstate`, configuration, documentation, tests or fixtures. Use placeholders such as `example-secret`, `dummy-token`, `test-password`.

## IAM review

Prefer:

```text
specific resource + specific action + specific principal
```

Avoid `"Action": "*"` / `"Resource": "*"` unless explicitly justified and documented.

## Emulator credentials

Floci-AZ accepts any credentials for local development; never use real Azure credentials in the local environment. Trivy scans apply to Azure provider configuration.

## References

* Rules: `rules/03-security.md`
* Docs: `docs/05-security/principles.md`, `docs/04-devops/ci.md`
