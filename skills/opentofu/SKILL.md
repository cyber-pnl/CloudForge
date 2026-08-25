# Skill — OpenTofu

## When to use

Use this skill for any change to files under `infrastructure/` or any new Terraform/OpenTofu module.

## Standard workflow

```bash
tofu fmt
tofu init
tofu validate
tofu plan
tofu apply
```

Validation minimum for every infrastructure change:

```bash
tofu fmt -check
tofu validate
tofu plan
```

## Plan review checklist

Before applying, inspect the plan for:

* resource deletion
* replacement (`-/+`)
* IAM changes
* security-sensitive configuration
* data loss
* state changes

Do not blindly apply a plan.

## Adding a module

1. Check whether an equivalent module already exists in `infrastructure/modules/`.
2. Create the module with explicit variables, no magic values.
3. Consume it from the target environment under `infrastructure/environments/<env>/`.
4. Apply least privilege to all IAM policies (see `rules/03-security.md`).
5. Run the validation trio (`fmt -check`, `validate`, `plan`).
6. Document the module in `docs/02-infrastructure/opentofu.md`.

## Floci note

Plans and applies for AWS environments run against the local Floci endpoint (`http://localhost:4566`). See the Floci skill for environment setup and emulator-specific behavior.

## Feint note

Plans and applies for the Scaleway DR environment (`infrastructure/environments/scw-dr/`) run against the Feint endpoint (`http://localhost:4599`). The `scaleway/scaleway` provider uses an `api_url` override to point to Feint instead of the real Scaleway API. Credentials are Feint's documented public placeholders and are never validated. See the Feint skill for details.

## References

* Rules: `rules/02-opentofu.md`, `rules/03-security.md`
* Docs: `docs/02-infrastructure/opentofu.md`, `docs/02-infrastructure/local-environment.md`
