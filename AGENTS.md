# CloudForge — Agent Instructions

CloudForge is a production-grade DevOps laboratory: AWS simulated locally with **Floci**, infrastructure managed with **OpenTofu**, changes validated through **GitHub Actions**, and **DevSecOps** practices enforced with **Trivy**.

Agents are expected to behave like members of a professional engineering team. Do not optimize for producing code quickly — optimize for correctness, maintainability, security, testability, reproducibility, observability and architectural consistency.

## Mandatory Workflow

Before modifying the repository:

```text
Understand → Inspect → Plan → Implement → Validate → Test → Security Scan → Document → Review
```

An agent must not start implementing a non-trivial task immediately.

## Repository Layout for Agents

```text
AGENTS.md      This entry point — start here
rules/         Mandatory project constraints (override implementation preferences)
skills/        Project-specific procedures — use before specialized work
docs/          Source of truth for project knowledge
```

### Rules

| File | Scope |
| ---- | ----- |
| `rules/00-project.md` | Mission, core principle, code quality, dependencies, backlog |
| `rules/01-architecture.md` | Documentation updates, ADRs, AWS service justification |
| `rules/02-opentofu.md` | Declarative IaC, validation, destructive operations |
| `rules/03-security.md` | Security baseline, Trivy policy, secrets |
| `rules/04-testing.md` | Testing levels, validation before completion |
| `rules/05-git.md` | Small focused changes |
| `rules/06-agent.md` | Workflow, failure handling, ambiguity, communication, final checklist |
| `rules/07-ci.md` | Single CI workflow constraint |

When a rule conflicts with an implementation preference, the rule takes precedence.

### Skills

Read the relevant skill before performing specialized work:

| Skill | Use for |
| ----- | ------- |
| `skills/architecture/SKILL.md` | Adding/changing AWS services, ADRs |
| `skills/opentofu/SKILL.md` | Any change under `infrastructure/` |
| `skills/floci/SKILL.md` | Local AWS environment work |
| `skills/devsecops/SKILL.md` | Security scans, findings, secrets, IAM |
| `skills/testing/SKILL.md` | Test strategy and pre-completion checks |
| `skills/ci/SKILL.md` | Changes to `.github/workflows/ci.yml` |
| `skills/incident-response/SKILL.md` | Failure scenarios and incident reports |

Do not invent a project-specific procedure when an existing skill already covers the task.

### Documentation

Project knowledge lives under `docs/` (see `docs/README.md` for the index). Before acting, read the relevant docs; after changing behavior, update them.

## Quick Reference

* Local AWS endpoint: `http://localhost:4566`
* Infrastructure validation minimum: `tofu fmt -check && tofu validate && tofu plan`
* Tests: `pytest`
* Security gate: `trivy fs .`
* CI workflow: `.github/workflows/ci.yml` (single workflow only)
* Backlog: `docs/08-roadmap/`

## Core Principle

> **Do not make the repository merely work. Make it reproducible, explainable, testable and operable.**
