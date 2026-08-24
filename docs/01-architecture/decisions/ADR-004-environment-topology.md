# ADR-004 — Environment topology and promotion model

## Status

Accepted (2026-08)

## Context

Phase 9 requires staging and production environments plus a deployment,
rollback and disaster-recovery story. Everything runs on one local Floci
instance, so the design must answer: how do environments stay separated, and
what does "production" mean inside an emulator?

Probe results that constrain the decision:

* Floci maps the access key to an isolated account id (`000000000001` gets its
  own resources). This isolation is **control-plane only**: the REST API
  execute plane resolves APIs in the default account exclusively, so an API
  deployed under another account cannot be invoked over HTTP.
* Resource names are global per service within an account.

## Decision

1. **One shared platform module.** `infrastructure/modules/platform` contains
   the entire stack; each environment under `infrastructure/environments/`
   (dev, staging, prod) is a thin wrapper providing the provider block,
   `name_prefix`, bucket name and API token. No environment-specific logic
   exists outside the wrappers.

2. **Environments are separated by name prefix in the same default account**
   (`cloudforge-dev-`, `cloudforge-staging-`, `cloudforge-prod-`). The
   multi-account feature stays documented as a control-plane-only mechanism;
   using it would make HTTP testing impossible.

3. **Lifecycle differs per environment**, mirroring real-world practice:
   - dev: ephemeral — rebuilt by CI from scratch on every run.
   - staging: long-lived locally; promoted manually via CI dispatch after dev
     passes (`workflow_dispatch` input).
   - prod: long-lived locally; deployed only by explicit local apply, never
     automated.

4. **Rollback = redeploy a previous build**, because OpenTofu state only moves
   forward. Lambda packages are built from the working tree, so rollback means
   checking out the previous git revision and re-running package + apply.

5. **Disaster recovery = cold rebuild** (runbook RB-03), already exercised by
   every CI run: destroy state, recreate from compose + tofu apply. The lab
   accepts data loss on rebuild; persistence survives container restarts but
   not recreation.

## Consequences

* Adding an environment is ~60 lines of wrapper, zero duplication.
* Plans stay clean across refactors thanks to declarative `moved {}` blocks.
* The emulator's execute-plane limitation is documented rather than worked
  around with fragile hacks.
