# OpenTofu — Infrastructure as Code

CloudForge uses **OpenTofu** as its Infrastructure as Code engine.

The infrastructure is divided into reusable modules.

## Layout

```text
infrastructure/
│
├── modules/
│   ├── kms/
│   └── s3/
│
└── environments/
    └── dev/
```

Additional modules are added in later phases following the same pattern.

## Modules

| Module | Resources | Purpose |
| ------ | --------- | ------- |
| `s3`   | bucket, versioning, public access block, SSE configuration | Object storage with secure defaults; optional customer managed KMS encryption via `kms_master_key_arn`. |
| `kms`  | key with rotation, alias | Customer managed encryption keys consumed by other modules. |

Each environment consumes the same reusable modules with environment-specific configuration.

```text
                ┌───────────────┐
                │    Modules    │
                └───────┬───────┘
                        │
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
       DEV           STAGING          PROD
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

## Adding a module

Follow the procedure in `skills/opentofu/SKILL.md` and update this document when a module is added.
