# Skill — Floci-AZ

## When to use

Use this skill when starting, verifying, debugging, or developing against the local Azure environment.

## Environment

Floci-AZ provides Azure-compatible APIs locally (Blob Storage, Cosmos DB, Azure Functions, API Management, Queue Storage, Event Grid, Key Vault, Azure Monitor, Entra ID, etc.) on a single unified port `4577`.

Default endpoint:

```text
http://localhost:4577
```

Default account / key (Floci-AZ well-known devstore credentials):

```text
devstoreaccount1
Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6I...
```

Start the environment:

```bash
docker compose up -d floci-az
```

Verify:

```bash
curl -sf http://localhost:4577/devstoreaccount1 | python3 -m json.tool
```

Stop the environment:

```bash
docker compose down
```

## How OpenTofu uses Floci-AZ

```text
OpenTofu (azurerm provider)
    │
    │ Azure Management API (ARM)
    ▼
Floci-AZ :4577
    │
    ├── Cosmos DB (NoSQL)
    ├── Blob Storage
    ├── Azure Functions
    ├── API Management
    ├── Queue Storage
    ├── Event Grid
    ├── Key Vault
    ├── Azure Monitor
    └── Entra ID
```

The `azurerm` provider is configured with `features {}` and endpoint overrides so all ARM calls land on `http://localhost:4577` instead of the real Azure API.

## Emulator-specific behavior

Do not assume every Azure service behaves exactly like real Azure.

1. **Dev account.** Floci-AZ exposes a single default storage account (`devstoreaccount1`); resource groups and ARM resources live under one subscription.
2. **Cosmos DB is embedded** at `/{account}-cosmos/` (NoSQL/SQL API) — no Docker required. Multi-API engines (MongoDB, PostgreSQL, Cassandra, Gremlin) are opt-in Docker sidecars.
3. **Azure Functions run via Docker** — each HTTP-triggered function spawns a container from a user-provided image.
4. **Credentials are never validated.** Floci-AZ accepts any credentials for local signing. Never use real Azure credentials locally.
5. **VM / AKS / ACR / Redis** may run mocked (management plane only) by default; enable real Docker backing when needed.

## Implementing an Azure feature

Follow this order:

1. Check Floci-AZ support for the service/API.
2. Check existing project documentation.
3. Validate the behavior locally against Floci-AZ.
4. Document any emulator-specific behavior in `docs/02-infrastructure/local-environment.md`.

## References

* Rules: `rules/02-opentofu.md`
* Docs: `docs/02-infrastructure/local-environment.md`
