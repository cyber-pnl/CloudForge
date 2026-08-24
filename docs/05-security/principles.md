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

## Security gates

`make security` (and the CI pipeline) enforces four layers:

| Gate | Scope | Failure condition |
| ---- | ----- | ----------------- |
| Secrets | all tracked files | any secret finding |
| IaC misconfiguration | `*.tf` files | HIGH or CRITICAL |
| Dependencies | vendored lambda packages (`lambdas/*/build`) and lockfiles | HIGH or CRITICAL |
| Accepted findings | documented exceptions only | ledger entry required |

Lambda packages are built before scanning so dependency scanning inspects what actually ships. The local `terraform.tfstate` is excluded from the secrets gate: OpenTofu stores sensitive variables there by design, the file is verified to stay git-ignored, and no other file benefits from that exception.

## Accepted findings

Security findings that are intentionally accepted must be documented here, with the narrowest possible scope (`rules/03-security.md`). Emulator limitations are verified through CLI probes before acceptance (`skills/floci/SKILL.md`).

| Finding | Severity | Scope | Reason | Re-evaluation |
| ------- | -------- | ----- | ------ | ------------- |
| AWS-0089 — Bucket has logging disabled | LOW | `modules/s3` buckets in dev | S3 access logging requires a dedicated log destination bucket; grouped with the API Gateway logging decision below. | Phase 7 (Observability) |
| AWS-0001 — Access logging is not configured | MEDIUM | `modules/api-gateway` stage | Stage access log settings are silently dropped by Floci (`UpdateStage` probe). Configuring them would create permanent state drift. | Next Floci upgrade |
| AWS-0003 / AWS-0066 — Tracing not enabled | LOW | API Gateway stage, Lambda functions | Floci provides no X-Ray service. | Migration toward real AWS |
| AWS-0004 — Authorization is not enabled | LOW | `/users`, `/projects` methods | Public API is intentional at this stage; the authentication model is a Phase 4 deliverable. | Phase 4 (Application) |
| AWS-0025 — Table encryption does not use CMK | LOW | `modules/dynamodb` tables | DynamoDB server-side encryption with customer keys is not implemented by Floci (`SSEDescription` absent). | Next Floci upgrade |
| AWS-0017 — Log group is not encrypted | LOW | Lambda log groups | `logs:AssociateKmsKey` is reported as `UnsupportedOperation` by Floci. | Next Floci upgrade |
