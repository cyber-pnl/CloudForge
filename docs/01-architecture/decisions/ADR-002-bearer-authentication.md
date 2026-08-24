# ADR-002 — Application-level bearer authentication

## Status

Accepted

## Context

Phase 4 requires an authentication model for the users and projects APIs. On real AWS the default answer would be a Cognito user pool behind an API Gateway `COGNITO_USER_POOLS` authorizer.

Floci was probed during Phase 4 planning:

* Cognito CRUD operations succeed (a user pool can be created and deleted).
* An API Gateway authorizer of type `COGNITO_USER_POOLS` can be created.
* **Authorizers are not enforced at invocation time**: a method configured with the authorizer still returned `200` when called without any token.

An authentication model that is not enforced is a security illusion. Additionally, `DeleteAuthorizer` is broken in the emulator (it responds with an S3 `NoSuchBucket` error), leaving orphaned resources behind.

## Decision

Authentication lives in the application layer:

* Every API request must carry `Authorization: Bearer <token>`.
* The expected token is injected into each function through the `API_TOKEN` environment variable, provisioned by OpenTofu (`var.api_token`, sensitive). The local development value (`local-dev-token`) is a placeholder documented in `terraform.tfvars.example`, not a secret.
* Token comparison uses constant-time comparison (`hmac.compare_digest`).

## Consequences

* Authentication is real, testable and enforced everywhere in this lab; unit tests cover the full acceptance matrix.
* The model is intentionally minimal: no identity federation, no expiry, one shared token. It must be revisited before anything resembling production.
* When migrating toward real AWS, replace with a Cognito authorizer or a Lambda (JWT) authorizer; handlers only need the check removed from the toolkit (`lambdas/common/auth.py`) since it is centralized.
