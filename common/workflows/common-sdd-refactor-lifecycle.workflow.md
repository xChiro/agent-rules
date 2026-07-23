---
workflow_id: WORKFLOW-COMMON_SDD_REFACTOR_LIFECYCLE_WORKFLOW
trigger: manual
description: "Behavior-preserving SDD lifecycle for production code, unit tests, and integration tests."
---

# Common SDD Refactor Lifecycle Workflow

Use this workflow only when observable behavior must remain unchanged. If behavior, a public contract, or a User Story changes, use `common-sdd-spec.workflow.md` and `common-sdd-change-lifecycle.workflow.md` instead.

When invoked by `common-sdd-clean-up-gate.workflow.md`, return to that gate after the refactor and rerun the clean-up analysis before security, coverage, or final validation.

## Phase 1: Anchor The Refactor

- Find the owning spec, User Stories, scenarios, tasks, tests, and latest history entry.
- Read `workflow-routing.md` and confirm the primary refactor workflow plus supporting test-evidence and documentation workflows.
- Add or confirm a `documentation` task governed by `RULE-COMMON_SDD_DOCUMENTATION_GATE` and routed to `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; it must cover changed structure, ownership, boundaries, repository maps, and developer guidance.
- Prepare and show the proposed refactor spec/task update before writing it.
- Ask for Gate 1 approval before adding a refactor task or changing any spec artifact.
- After approval, add a small refactor task with `T-*` and `TEST-*` traceability.
- State the design problem, intended structural improvement, touched boundary, and explicit non-goals.
- Keep `max_parallel_agents: 1` unless tracks own disjoint files and verification surfaces.
- Mark every refactor task with `track_id`, `parallelizable`, dependencies, `can_run_with`, ownership, and execution wave.
- Mark every refactor task with `workflow_id`, `workflow_phase`, and supporting workflow IDs when needed.
- Each refactor task has one structural outcome, `done_when`, a narrow verification command, and one next step. Split broad cleanup into sequential microtasks.
- If context reaches 60%, stop starting new refactor tasks, update the active spec, and invoke `common-sdd-context-checkpoint.workflow.md` before requesting a new context.
- Show the written refactor artifacts and ask for Gate 2 approval before creating, modifying, or running characterization/unit/HTTP tests.

## Phase 2: Protect Existing Behavior

- Start only after Gate 2 approval.
- Identify existing acceptance, unit, and integration evidence.
- Add the smallest missing characterization or unit test before production refactoring.
- Confirm the protection test passes against current behavior.
- Do not weaken assertions, rewrite scenarios, or change expected HTTP contracts to simplify the refactor.
- Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before editing production structure. For characterization tests that are expected to pass, show the passing protection evidence and document why RED is not applicable.

Backend refactors use only two test suites:

1. Unit tests for domain/application behavior.
2. Boundary integration tests for public wiring and local infrastructure; HTTP is one possible entry mechanism.

## Phase 3: Refactor In Small Steps

- Before each structural edit, identify the affected actor, named use case, owning module, dependency direction, and the SOLID checks that the edit must preserve or improve. All five principles are mandatory: SRP, OCP, LSP, ISP, and DIP.
- Make one structural change at a time.
- When branching is the smell, record the chosen Fowler transformation: `Extract Function`, `Decompose Conditional`, `Replace Nested Conditional with Guard Clauses`, `Consolidate Conditional Expression`, `Replace Conditional with Polymorphism`, `Replace Type Code with State/Strategy`, `Introduce Special Case`, or `Replace Parameter with Explicit Methods`.
- Prefer a guard clause for preconditions and a clear closed classification for stable finite cases; refactor repeated/nested/policy-heavy branches instead of banning every `if` or `switch`.
- Preserve and, when required, restore both Clean Architecture views: ownership/development progresses Domain policy → Application use case/ports → Infrastructure/Interface → Composition, while compile-time dependencies point inward as Composition/Interface/Infrastructure → Application → Domain.
- Keep every actor-visible backend behavior behind its Application use case. A refactor must not move business policy into handlers, controllers, adapters, repositories, DTOs, or composition.
- Keep transport, cloud SDK, persistence, and framework types outside domain/application.
- Keep Domain/Application names abstract and provider-neutral during renames or moves. Do not introduce or preserve `DynamoDB`, `Cosmos`, `Kafka`, or equivalent provider names in inner-layer files, packages, ports, types, DTOs, events, or errors; name the business capability and leave concrete provider names in outer adapters/configuration.
- Run the smallest relevant unit test after each inner-layer change.
- Run the focused integration/http or integration/infrastructure test after delivery mapping, message/worker wiring, DI, persistence, schema, or infrastructure changes.
- Update `tasks.md`, `verification.md`, and `change-summary.md` after each structural microtask.
- Stop and evolve the spec if the refactor reveals a required behavior change.
- Do not introduce a strategy/interface/registry/HOC only to remove one simple branch. Record the simpler option considered and why the selected design protects a real variation or boundary.

## Phase 4: Verify

- Run the affected unit suite.
- Run the affected integration scope when an outer boundary or local resource was touched.
- Run build, format, lint, architecture, coverage, complexity, or mutation gates when the repository defines them.
- Record commands, results, exceptions, and residual risk in `verification.md`.
- Record the context checkpoint path and exact resume action when a handoff occurred.

## Phase 5: Converge

- Update `tasks.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, architecture docs, and repository map when structure changed.
- Update `workflow-routing.md` and pass `RULE-COMMON_SDD_DOCUMENTATION_GATE` by invoking `common-sdd-update-documentation.workflow.md` for every refactor. If its surface analysis finds no affected project documentation, record `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`.
- Add an append-only history entry when the refactor changes architecture or ownership.
- Report protected behavior, structural changes, tests run, actual agent count, and unverified scope.

## Done

- Observable behavior and public contracts are unchanged.
- Protection tests existed before production refactoring.
- Gate 3 approved the actual test evidence before production refactoring.
- Unit tests pass.
- Relevant integration tests pass.
- No architecture boundary was weakened.
- Domain/Application dependencies and names remain abstract and provider-neutral; concrete technology names are confined to outer adapters/configuration.
- Clean Architecture, named use-case ownership, and all five SOLID checks were reviewed and pass: actor-based SRP, OCP, LSP, ISP, and DIP.
- Spec artifacts and implementation converge.
- The documentation gate passed through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, including an explicit inspected-surface/no-change record when no project documentation was affected.
