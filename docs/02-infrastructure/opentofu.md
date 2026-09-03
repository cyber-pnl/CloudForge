# OpenTofu — Infrastructure as Code

CloudForge uses **OpenTofu** as its Infrastructure as Code engine.

The infrastructure is divided into reusable modules.

## Layout

```text
infrastructure/
│
├── modules/                  # Reusable OpenTofu modules
│   ├── api-gateway/          # AWS API Gateway
│   ├── cloudwatch/           # AWS CloudWatch alarms
│   ├── dynamodb/             # AWS DynamoDB tables
│   ├── eventbridge/          # AWS EventBridge
│   ├── iam/                  # AWS IAM roles
│   ├── kms/                  # AWS KMS keys
│   ├── lambda/               # AWS Lambda functions
│   ├── platform/             # AWS platform compositor (all sub-modules)
│   ├── s3/                   # AWS S3 buckets
│   ├── sns/                  # AWS SNS topics
│   ├── sqs/                  # AWS SQS queues
│   ├── az-cosmosdb/          # Azure Cosmos DB (SQL API)
│   ├── az-storage/           # Azure Storage (Blob + Queue)
│   ├── az-keyvault/          # Azure Key Vault
│   ├── az-functions/          # Azure Functions (Service Plan + Function App)
│   ├── az-apim/               # Azure API Management
│   ├── az-eventgrid/          # Azure Event Grid (custom topic + subscriptions)
│   ├── az-monitor/            # Azure Log Analytics workspace
│   └── az-entra/              # Azure user-assigned managed identity
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
| `az-cosmosdb`| Cosmos DB account (SQL API), SQL database, SQL containers | Application data tables; Azure equivalent of DynamoDB. |
| `az-storage` | Storage account, blob containers, storage queues | Object storage and async messaging; Azure equivalent of S3 + SQS. |
| `az-keyvault` | Key Vault, secrets | Application secrets and encryption keys; Azure equivalent of KMS. |
| `az-functions` | Service plan, Linux Function App | Serverless compute; Azure equivalent of Lambda. |
| `az-apim` | API Management instance, APIs | REST API gateway; Azure equivalent of API Gateway. |
| `az-eventgrid` | Custom topic, event subscriptions | Event router; Azure equivalent of SNS/EventBridge. |
| `az-monitor` | Log Analytics workspace | Log ingestion and query; Azure equivalent of CloudWatch (logs surface). |
| `az-entra` | User-assigned managed identity | Workload identity for Function Apps; Azure equivalent of IAM roles. |

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

Azure development environment (Floci-AZ) replicating the serverless platform locally.

```text
infrastructure/environments/dev-az/
    main.tf        # azurerm provider → Floci-AZ, resource group, modules
    variables.tf   # subscription_id, tenant_id, metadata_host, name_prefix
    outputs.tf     # cosmosdb/ storage/ keyvault/ functions/ apim names and endpoints
```

Phase 1 (foundations) provisions:
- **Cosmos DB** account with SQL database and containers (users, projects)
- **Storage** account with blob containers (artifacts) and queues (jobs, jobs-dlq)
- **Key Vault** for application secrets

Phase 2 (compute and gateway) provisions:
- **Azure Functions** service plans and Linux Function Apps (users, projects, worker, dispatcher)
- **API Management** instance with Users and Projects APIs

Phase 3 (messaging and events) provisions:
- **Event Grid** custom topic with webhook event subscriptions

Phase 4 (observability and security) provisions:
- **Log Analytics** workspace for function logs (logs surface only)
- **User-assigned managed identity** attached to the Function Apps

```text
CI → Floci-AZ → OpenTofu (azurerm provider)
```

> **Emulator note:** Floci-AZ Event Grid supports webhook destinations only. Storage Queue, Azure Function, and Service Bus event subscription destinations are not supported; domain/namespace surfaces are out of scope. See [local-environment.md](local-environment.md#event-grid) for details.
>
> **Metrics note:** Floci-AZ emulates the Azure Monitor logs surface (Log Analytics ingestion + query) but **not** metrics, alerts, action groups, or autoscale. Metric alarms are documented but not evaluatable — parallel to Floci's CloudWatch limitation.

The `azurerm` provider is configured with `environment = "stack"` and `metadata_host = "localhost:4577"` to discover the cloud via Floci-AZ's HTTPS metadata endpoint. TLS is required — see [local-environment.md](local-environment.md#tls-is-mandatory-for-the-azurerm-provider).

See [deployment-strategy.md](../04-devops/deployment-strategy.md) for the full topology.

## Adding a module

Follow the procedure in `skills/opentofu/SKILL.md` and update this document when a module is added.
