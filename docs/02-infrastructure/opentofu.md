# OpenTofu — Infrastructure as Code

CloudForge uses **OpenTofu** as its Infrastructure as Code engine.

The infrastructure is divided into reusable modules.

## Layout

```text
infrastructure/
│
├── modules/                  # Reusable OpenTofu modules (AWS)
│   ├── api-gateway/
│   ├── cloudwatch/
│   ├── dynamodb/
│   ├── eventbridge/
│   ├── iam/
│   ├── kms/
│   ├── lambda/
│   ├── platform/
│   ├── s3/
│   ├── sns/
│   └── sqs/
│
├── environments/
│   ├── dev/                  # Ephemeral AWS dev
│   ├── staging/              # Long-lived AWS staging
│   ├── prod/                 # Long-lived AWS production
│   └── dev-az/                # Azure dev environment (Floci-AZ)
│
└── proxy/                    # Unified cloud endpoint (nginx)
```

Additional modules are added in later phases following the same pattern.

## Modules

| Module       | Resources | Purpose |
| ------------ | --------- | ------- |
| `platform`   | all resources via sub-modules | Complete platform stack consumed by dev/staging/prod wrappers |
| `s3`         | bucket, versioning, public access block, SSE configuration | Object storage with secure defaults; optional customer managed KMS encryption via `kms_master_key_arn`. |
| `kms`        | key with rotation, alias | Customer managed encryption keys consumed by other modules. |
| `dynamodb`   | table (PAY_PER_REQUEST), point-in-time recovery | Application data tables. |
| `iam`        | Lambda execution role with scoped inline policy | Least-privilege roles; extra statements are passed per function and restricted to the resources it owns. |
| `lambda`     | function, CloudWatch log group with retention | Deployment packages are zipped from source directories via the `archive` provider. |
| `api-gateway`| REST API, nested resources (`/{id}` and sub-resources), AWS_PROXY integrations, deployment, stage | Routes are declared as maps per depth level; every route is backed by a Lambda proxy integration. |
| `cloudwatch` | metric alarms | Operational alarms; documented but not evaluated by Floci (see local-environment.md). |
| `sqs`        | queue | Asynchronous processing; optional CMK encryption. |
| `sns`        | topic | Notifications fan-out; optional CMK encryption. |
| `eventbridge`| custom bus, rules with single target each | Domain events routing; patterns are passed as JSON strings. |

Each environment consumes the same reusable modules with environment-specific configuration.

Lambda packages are **byte-reproducible**: `make package` strips `__pycache__` directories (their `.pyc` files embed source mtimes) and normalizes file timestamps to the epoch, so rebuilding without code changes yields identical zips and identical `source_code_hash` values. Without this, every repackaging would flag all Lambda functions as drifted even though nothing changed.

Integration glue that binds resources across modules — event source mappings, SQS redrive policies, API routes to functions — lives in the environment files rather than inside modules: these resources need ARNs of other modules' outputs and would otherwise force `count`/`for_each` on values only known at apply time.

The AWS provider is pinned to `~> 5.0` for Floci compatibility — see [Local Environment](local-environment.md#provider-version-pinning).

```text
                ┌───────────────┐
                │    Modules    │
                └───────┬───────┘
                        │
         ┌──────────────┼──────────────┬──────────────┐
         ▼              ▼              ▼              ▼
        DEV          STAGING         PROD         DEV-AZ
     (Floci)        (Floci)        (Floci)       (Floci-AZ)
```

## Standard workflow

```bash
tofu fmt
tofu init
tofu validate
tofu plan
tofu apply
```

`tofu fmt` enforces canonical OpenTofu formatting, while `tofu validate` checks the configuration for syntactic and internal consistency.

Validation minimum for every change:

```bash
tofu fmt -check
tofu validate
tofu plan
```

## Environments

### Development

Used for local development and automated validation.

```text
Developer → Floci → OpenTofu
```

### Staging

Used to validate the complete platform before production.

```text
GitHub → CI → Floci → OpenTofu
```

### Production

Represents the desired production architecture. The project is initially executed entirely locally; the infrastructure is intentionally structured so that a future migration to real AWS can be explored without redesigning the entire architecture.

### Azure dev-az

Azure development environment (Floci-AZ) replicating the full serverless platform locally. Provisions API Management, Azure Functions, Cosmos DB, Blob Storage, Queue Storage, Event Grid, Azure Monitor, Key Vault and Entra ID through the `azurerm` provider against the Floci-AZ emulator.

```text
CI → Floci-AZ → OpenTofu (azurerm provider)
```

See [deployment-strategy.md](../04-devops/deployment-strategy.md) for the full topology.

## Adding a module

Follow the procedure in `skills/opentofu/SKILL.md` and update this document when a module is added.
