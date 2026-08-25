# Skill — Feint

## When to use

Use this skill when starting, verifying, debugging, or developing against the local Scaleway environment.

## Environment

Feint provides Scaleway-compatible APIs locally.

Default endpoint:

```text
http://localhost:4599
```

Start the environment:

```bash
docker compose up -d feint
```

Verify:

```bash
curl -sf http://localhost:4599/_feint/health | python3 -m json.tool
```

Stop the environment:

```bash
docker compose down
```

## How OpenTofu uses Feint

```text
OpenTofu (scaleway/scaleway provider)
    │
    │ Scaleway API  (api_url override)
    ▼
Feint :4599
    │
    ├── Instance (compute)
    ├── VPC / VPCgw (networking)
    ├── Block (block storage)
    └── IAM (access control)
```

The provider configuration in `infrastructure/environments/scw-dr/main.tf` sets `api_url = var.feint_endpoint` to route all Scaleway API calls to Feint.

## Emulator-specific behavior

1. **Control-plane only.** Created servers report API state but never boot. The lab proves reproducible provisioning, not workload execution on Scaleway.
2. **No Object Storage.** The Scaleway S3-compatible API is not emulated.
3. **Credentials are never validated.** Feint accepts any signing credentials. Never use real Scaleway credentials in the local environment.
4. **Volume attachment drift.** The Scaleway provider re-applies `additional_volume_ids` on every plan when the volume was created in the same apply. This is harmless and idempotent.

## Implementing a Scaleway feature

Follow this order:

1. Check Feint support for the service/API.
2. Check existing project documentation.
3. Validate the behavior locally against Feint.
4. Document any emulator-specific behavior in `docs/02-infrastructure/local-environment.md`.

## Health check

```bash
curl -sf http://localhost:4599/_feint/health | python3 -m json.tool
```

## References

* Rules: `rules/02-opentofu.md`
* Docs: `docs/02-infrastructure/local-environment.md`, `docs/01-architecture/decisions/ADR-005-multicloud-scaleway.md`
