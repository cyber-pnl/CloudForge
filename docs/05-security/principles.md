# Security Principles

Security is integrated directly into the development lifecycle. The rules are defined in `rules/03-security.md`; this document describes the principles applied across the platform.

## DevSecOps in CI

Trivy scans the repository for:

* vulnerabilities
* infrastructure misconfigurations
* secrets
* dependency issues

Example:

```bash
trivy fs .
```

The objective is to prevent insecure infrastructure from reaching the deployment stage.

```text
Developer
    │
    ▼
Pull Request
    │
    ▼
Trivy
    │
    ├── Vulnerabilities
    ├── Secrets
    ├── IaC Misconfiguration
    └── Dependencies
    │
    ▼
OpenTofu Validation
    │
    ▼
Integration Tests
```

## Least privilege

IAM policies should provide only the permissions required by each Lambda or service.

Prefer `specific resource + specific action + specific principal` over broad permissions.

## No secrets in Git

Secrets must never be committed.

```text
❌ AWS_ACCESS_KEY_ID=...
❌ AWS_SECRET_ACCESS_KEY=...
❌ database_password=...
```

Local development should use non-production credentials and environment-specific configuration.

## Infrastructure scanning

Every OpenTofu change should pass the Trivy security stage.

Findings may only be accepted through the documented exception procedure (`rules/03-security.md`) — never by weakening the scan.

## Immutable builds

Application artifacts should be built once and promoted between environments rather than rebuilt differently for each environment.

## Accepted findings

Security findings that are intentionally accepted must be documented here, with the narrowest possible scope (`rules/03-security.md`).

| Finding | Severity | Scope | Reason | Re-evaluation |
| ------- | -------- | ----- | ------ | ------------- |
| AWS-0089 — Bucket has logging disabled | LOW | `modules/s3` buckets in dev | S3 access logging requires a dedicated log destination bucket; the logging architecture decision belongs to the observability phase. | Phase 7 (Observability) |
