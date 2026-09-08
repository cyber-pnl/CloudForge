# ADR-007 — Azure Functions provisioned via the Floci-AZ native API (emulator-only)

## Status

Accepted

## Context

CloudForge replicates its serverless platform on Azure locally with **Floci-AZ**
(`localhost:4577`) using the **azurerm** OpenTofu provider (see ADR-006). The
Azure workload includes four HTTP-triggered Azure Functions (users, projects,
worker, dispatcher).

Two independent blockers prevented the functions from being provisioned with
`azurerm`:

1. **No App Service Plan.** Floci-AZ does not emulate
   `Microsoft.Web/serverfarms` (HTTP 404), yet the `azurerm` provider requires
   an App Service Plan before it can create a Function App. Without a plan, no
   Function App can be created through the provider.

2. **Unusable identity/authority path.** The underlying Go Azure SDK (MSAL)
   requires an `https` authority during Entra token discovery, but Floci-AZ's
   discovery issuer is hardcoded to `http` (only `/metadata/endpoints` honours
   `X-Forwarded-Proto`, fixed in v0.12.0). MSAL's
   `ValidateIssuerMatchesAuthority` enforces that the issuer scheme and host
   match the authority, so token acquisition fails outright. This blocks the
   `azapi`/`azurerm` hybrid path as well.

While investigating a workaround, we discovered that Floci-AZ exposes a *native*
Functions management API (specific to the emulator, not a real Azure API). It
successfully provisions a Function App and deploys a Python v2 function, and the
function is actually invocable over HTTP.

## Decision

Provision the Azure Functions through **Floci-AZ's native Functions management
API** instead of the `azurerm`/`azapi` providers, driven from OpenTofu via a
`null_resource` + `local-exec` provisioner that invokes a helper script
(`scripts/azure-functions-deploy.sh`).

The API is called with `curl` and uses HTTPS (`Endpoint`/`AZ_FUNCTIONS_ENDPOINT`
defaults to `https://localhost:4577`; `-k` skips TLS verification for the
emulator's self-signed certificate). HTTPS is required so that public
`invoke_url`/webhook URLs satisfy consumers that require `https` (e.g. the Event
Grid worker subscription).

Only the **Python v2 runtime** is supported. The package is `host.json` plus a
generated `function_app.py` whose HTTP route equals the function name. Classic
v1/v2 layouts for Node/Java/.NET are not picked up by the emulator (0 functions
found) and are rejected by the script.

This path is **emulator-only** and is **not** portable to a real Azure App
Service deployment.

## Consequences

* The four Function Apps (and their Event Grid worker subscription) now validate
  and plan cleanly; the stack reaches `Plan: 21 to add` in `dev-az`.
* The functions are genuinely deployable and invocable against Floci-AZ, closing
  the earlier "no deployable Azure workload" gap for local experiments.
* A `null` provider and `local-exec` script are introduced, deviating from a
  purely declarative `azurerm` model — acceptable here because it is confined to
  the local emulator and documented as such.
* This decision does **not** lift the wider `tofu apply` blocker on `dev-az`,
  which is still caused by other azurerm data-plane DNS/TLS routing (see
  `docs/02-infrastructure/multicloud-journal.md`); `apply` remains out of scope
  and the CI gate stays at plan/validation.
* ADR-006's note that Azure Functions are unprovidable is superseded for the
  emulator-native path only.

## Alternatives Considered

* **`azurerm` Function App (unchanged)**: blocked by the missing App Service
  Plan emulation (404).
* **`azapi`/`azurerm` hybrid via `Microsoft.Web/sites` + managed identity**:
  blocked by the https-authority assertion in the Go SDK/MSAL against Floci-AZ's
  http-discovery issuer; `FLOCI_AZ_SERVICES_ENTRA_ISSUER` only changes the issued
  token's `iss` claim, not the discovery document, so it is ineffective.
* **Documentation only (no implementation)**: rejected once the native API was
  proven to work empirically; the user asked to see it working before documenting.
* **Port hybrid `azurerm` for storage/queue + native API for functions**: more
  complex, and the same https/MSAL blocker affects any provider identity use.
