# Skill — Floci

## When to use

Use this skill when starting, verifying, debugging, or developing against the local AWS environment.

## Environment

Floci provides AWS-compatible APIs locally.

Default endpoint:

```text
http://localhost:4566
```

Start the environment:

```bash
docker compose up -d
```

Verify:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
```

Stop the environment:

```bash
docker compose down
```

## Implementing an AWS feature

Follow this order:

1. Check Floci support for the service/API.
2. Check existing project documentation.
3. Validate the behavior locally against Floci.
4. Document any emulator-specific behavior.

## Emulator-specific behavior

Do not assume that every AWS service behaves exactly like real AWS.

* Floci-specific workarounds must be isolated (single place) and documented.
* Do not spread emulator-specific assumptions throughout the application.
* Record known divergences in `docs/02-infrastructure/local-environment.md`.

## References

* Rules: `rules/02-opentofu.md`
* Docs: `docs/02-infrastructure/local-environment.md`
