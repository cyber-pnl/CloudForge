# Skill — Architecture

## When to use

Use this skill when adding or changing AWS or Azure services, modifying the event-driven flow, or making a decision that affects the platform design.

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

4. For every new Azure service, answer (see `rules/01-architecture.md`):

   ```text
   Why is this service required on Azure?
   Is it supported by Floci-AZ?
   How will it be tested against Floci-AZ?
   ```

5. If the change is a significant architectural decision, create an ADR in `docs/01-architecture/decisions/` following `ADR-XXX-short-description.md` with sections: Status, Context, Decision, Consequences, Alternatives Considered.
6. Update `docs/01-architecture/aws-services.md` when a service is added. Update the Azure table when adding Azure services.
7. Validate with the OpenTofu skill if infrastructure is touched.

## References

* Rules: `rules/00-project.md`, `rules/01-architecture.md`
* Docs: `docs/01-architecture/`
