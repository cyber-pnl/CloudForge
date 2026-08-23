# Skill — Architecture

## When to use

Use this skill when adding or changing AWS services, modifying the event-driven flow, or making a decision that affects the platform design.

## Procedure

1. Read `docs/01-architecture/overview.md` and `docs/01-architecture/aws-services.md`.
2. Check existing OpenTofu modules under `infrastructure/modules/` before introducing anything new.
3. For every new AWS service, answer the justification checklist (see `rules/01-architecture.md`):

   ```text
   Why is this service required?
   What responsibility does it have?
   Why is it preferable to an existing service?
   Is it supported by Floci?
   How will it be tested?
   How will it be observed?
   What are its security implications?
   ```

4. If the change is a significant architectural decision, create an ADR in `docs/01-architecture/decisions/` following `ADR-XXX-short-description.md` with sections: Status, Context, Decision, Consequences, Alternatives Considered.
5. Update `docs/01-architecture/aws-services.md` when a service is added.
6. Validate with the OpenTofu skill if infrastructure is touched.

## References

* Rules: `rules/00-project.md`, `rules/01-architecture.md`
* Docs: `docs/01-architecture/`
