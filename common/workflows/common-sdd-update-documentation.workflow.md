---
workflow_id: WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW
trigger: manual
description: Create or update project, SDD, architecture, testing, AI-context, and operational documentation after a verified change.
---

# Common SDD Update Documentation Workflow

Use this workflow for every `documentation` task selected in `workflow-routing.md` and every invocation of `RULE-COMMON_SDD_DOCUMENTATION_GATE`. It keeps documentation synchronized with the approved spec, verified tests, code, architecture, and operational behavior. It replaces the former language-specific documentation-update workflows.

## Preconditions

- The owning spec and `workflow-routing.md` identify this workflow for the task.
- `RULE-COMMON_SDD_DOCUMENTATION_GATE` is loaded for the owning SDD lifecycle.
- The relevant behavior or structural change has been verified, or the task is explicitly documentation-only.
- The documentation task has a `T-*` ID, `ART-*` ownership, `workflow_id`, track, dependencies, and done conditions.
- Do not overwrite append-only history entries. Add a new history entry for changed intent or architecture.

## Phase 1: Inspect The Real Repository

Read the owning spec, latest history, source structure, tests, build files, dependency manifests, API/IaC templates, CI workflows, and existing documentation.

Record the actual paths and commands. Do not document files, commands, endpoints, dependencies, or architecture that were not verified in the repository.

## Phase 2: Determine The Documentation Surface

Update only the surfaces affected by the task:

- SDD artifacts: `spec.md`, `change-summary.md`, `plan.md`, `code-quality-review.md`, `security-review.md`, `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, and append-only `history/`. Clean-up evidence must include the <150-line source-file result when code is in scope.
- Architecture: domain model, Clean Architecture boundaries, CQRS commands/queries, dependency direction, repository map, and ADRs.
- Developer guide: setup, local dependencies, commands, configuration, use cases, REST/Lambda contracts, persistence, messaging, and file organization.
- AI context: stable project purpose, current architecture, key files, constraints, and known non-goals.
- Testing guide: User Stories, BDD scenarios, ATDD-style unit tests, the two backend suites, HTTP resources, isolation, cleanup, and exact commands.
- Operations and CI: GitHub job names, local services, readiness, migrations/tables, artifacts, branches, environments, OIDC, secrets, deploy gates, and smoke checks.
- Public documentation: root README, API docs, runbooks, changelog, or release notes when the changed behavior is user-facing.

Do not create duplicate documentation when an existing document owns the topic. Add a link or update the existing owner.

## Phase 3: Update In Dependency Order

Update in this order so downstream documents describe the approved source:

1. `spec.md`, `change-summary.md`, and `acceptance.feature` for behavior and the human-readable change record.
2. `plan.md`, contracts, data model, decisions, and architecture notes.
3. `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, and `traceability.yaml`.
4. Code/test structure documentation and developer/AI context.
5. CI, deployment, runbooks, README, and release-facing documentation.
6. `verification.md` and the append-only history entry.

## Phase 4: Validate Documentation

- Every referenced path exists or is explicitly marked as a future artifact.
- Every command is copied from a project script, build file, or verified workflow.
- Workflow IDs, artifact IDs, task IDs, test IDs, and links resolve.
- Documentation describes `unit-tests` and `http-integration-tests` without inventing a third backend runtime suite.
- HTTP integration documentation names real local resources, readiness, isolation, cleanup, and diagnostics.
- Architecture documentation preserves SOLID, Clean Architecture, CQRS, DDD, and dependency direction.
- No secrets, tokens, private endpoints, or production credentials are documented.
- Markdown links, YAML, OpenAPI, and CI expressions pass the repository's available checks.

## Phase 5: Verification Request

Show the user:

- Documentation files created or changed.
- The selected workflow and task IDs.
- The source evidence used for each meaningful documentation update.
- Commands/checks run and remaining unverified claims.

Ask for verification when documentation changes product behavior, architecture, public contracts, security, deployment, or operational instructions. Record the decision in `verification.md`.

## Done

- Documentation matches the approved spec, code, tests, architecture, and CI behavior.
- `change-summary.md` reflects the actual changes and deviations from the approved plan.
- `workflow-routing.md` and `traceability.yaml` identify this workflow for the documentation task.
- Every changed documentation artifact has a stable `ART-*` ID.
- History is append-only and records conceptual or architecture changes.
- Broken references, invented commands, stale workflow names, and contradictory test-suite descriptions are absent.
