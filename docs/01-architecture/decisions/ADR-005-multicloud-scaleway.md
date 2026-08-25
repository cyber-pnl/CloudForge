# ADR-005 — Multi-cloud topology: Scaleway warm-standby via Feint

## Status

Accepted (2026-08) · updated 2026-08 (DR workload mapping added)

## Context

Phase 10 introduces multi-cloud. The candidate second cloud is Scaleway,
emulated locally by [Feint](https://github.com/stephrobert/feint) — one
binary, one port (`4599`), no account. Probe results that constrain the
decision:

* Feint mounts **357 routes**; the Scaleway pack covers compute and network:
  `instance` (67), `lb` (37), `vpc` (17), `vpcgw` (15), `block` (22),
  `ipam` (9), `iam` (5), `marketplace` (1).
* **No Object Storage, no serverless, no queues** — the products CloudForge's
  application actually runs on are absent from the emulation.
* The official OpenTofu provider `scaleway/scaleway 2.81.0` applies cleanly
  against it through the provider's `api_url` override (probe: VPC + private
  network + DEV1-S instance, `3 added`, private IP published). Credentials
  exist only to satisfy client-side signing: the emulator never checks them.
* By default Feint is a control plane: created servers answer API calls but
  boot nothing (`capabilities.machines: false`). Machine runtimes (Incus/OVN)
  are out of scope for this lab.

## Decision

1. **CloudForge stays primary on AWS/Floci.** The application plane
   (API Gateway, Lambda, DynamoDB, SQS/SNS/EventBridge, S3) is not natively
   ported to Scaleway — the emulator cannot serve those products.

2. **Scaleway plays the warm-standby DR site.** A dedicated environment
   `infrastructure/environments/scw-dr/` provisions a minimal IaaS footprint
   with the real Scaleway provider: VPC, private network, standby instance
   and block volume.

3. **DR workload is containerized on IaaS primitives.** When Floci goes down,
   the application runs as Docker containers on the Scaleway instance:

   | AWS managed | Scaleway IaaS |
   |---|---|
   | API Gateway | nginx reverse proxy |
   | Lambda | Python Docker containers |
   | DynamoDB | PostgreSQL container |
   | S3 | Block volume filesystem |
   | SQS / SNS | Redis container |
   | EventBridge | Cron worker container |
   | Secrets Manager | Vault container |

4. **One repo, two providers, one CI workflow.** The Scaleway provider is
   pinned (`~> 2.81`) next to the AWS one; validation follows the same gates
   (`fmt-check`, `validate`, `plan`, then apply+verify in CI) inside the
   existing single workflow as an additional job (`rules/07-ci.md` holds).

5. **The DR story has two chapters.** Phase 9's recovery procedure rebuilds
   the primary platform on Floci. Phases 11-12 add the ability to fail over
   to Scaleway when the primary cloud is lost — the classic *serverless
   primary + IaaS secondary* pattern.

## Consequences

* Feint joins `docker-compose.yml` pinned to a named version (no `latest`),
  following the same supply-chain discipline as every other image here.
* Emulator quirks discovered along the way are recorded in
  `docs/02-infrastructure/local-environment.md`, exactly like Floci's.
* The DR site transitions from "control-plane only provisioning" (Phase 10)
  to "full workload execution via Docker containers" (Phases 11-12).
* Data migration (DynamoDB → PostgreSQL) and API compatibility (REST
  endpoints served by nginx) are the primary integration risks; they are
  validated by E2E tests in Phase 12.
* Trivy scans the new provider configuration like any other IaC; accepted
  findings go through the ledger in `docs/05-security/principles.md`.
