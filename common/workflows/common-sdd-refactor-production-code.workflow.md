---
workflow_id: WORKFLOW-COMMON_SDD_REFACTOR_PRODUCTION_CODE_WORKFLOW
trigger: manual
description: "Refactor backend production code while preserving behavior, Clean Architecture, named use cases, CQRS, and all SOLID principles."
---

# Common SDD Refactor Production Code Workflow

Use this tool for behavior-preserving refactors of production code in Domain, Application, Infrastructure, Interface, or Composition. Load `common-sdd-refactor-lifecycle.workflow.md` as the governing parent and use the language-specific refactor adapter when one exists.

This workflow may improve structure, ownership, duplication, complexity, naming, or boundaries. It must not change acceptance behavior, public contracts, authorization, security, data semantics, event meaning, or CQRS responsibilities. If any of those must change, stop and route through `common-sdd-evolve-spec.workflow.md`.

## Mandatory Design Contract

- Identify the affected actor and apply SRP exactly as Robert C. Martin defines it in *Clean Architecture*: **a module should be responsible to one, and only one, actor**. SRP is not one method or one statement per class.
- Preserve both Clean Architecture views: ownership/development progresses Domain policy → Application use case/ports → outer adapters → Composition, while compile-time dependencies point inward as Composition/Interface/Infrastructure → Application → Domain.
- Keep every actor-visible backend behavior behind its named Application use case. Do not move business policy into controllers, handlers, adapters, repositories, DTOs, or composition.
- Keep Domain/Application names abstract and provider-neutral. Refactors must not create or retain names such as `DynamoDB`, `Cosmos`, `Kafka`, `SQS`, `SNS`, or `AWS` in inner-layer files, packages, ports, types, DTOs, events, methods, or errors; provider-specific names belong in outer adapters and composition only.
- Review all five SOLID principles before and after every structural wave: SRP, OCP, LSP, ISP, and DIP. Record actor, variation boundary, substitutability contract, interface consumer, and dependency direction.
- Preserve CQRS command/query separation, one behavior per focused port, error identity, cancellation, resource ownership, and public contracts.

## Execution

1. Show the refactor plan, scope, non-goals, affected actor/use case, files, tracks, and verification commands; obtain Gate 1.
2. Update the refactor spec, tasks, `TEST-*` protection evidence, routing, and traceability; obtain Gate 2 before test or production edits.
3. Protect unchanged behavior with the smallest relevant unit or integration test. Apply exact `// Arrange`, `// Act`, and `// Assert`; `// Act` contains one physical-line call to the layer-appropriate SUT.
4. Obtain Gate 3 for the protection evidence before production edits. Use `unit` for Domain/Application behavior and the applicable integration scope for outer behavior.
5. Make one behavior-preserving structural change at a time: rename, move responsibility, remove semantic duplication, extract a named concept, correct dependency direction, or apply one justified Fowler transformation.
6. Run the smallest affected test after each wave, then formatter, compiler/typecheck, linter, architecture, dependency, coverage, and quality gates required by the repository.
7. Re-run the complete clean-up analysis, including spaghetti/code smells, actor-based SRP, all SOLID principles, Clean Architecture, CQRS, and duplication.
8. Converge `tasks.md`, `change-summary.md`, `verification.md`, `traceability.yaml`, `workflow-routing.md`, documentation, and append-only history.

## Done

- Behavior and public contracts are unchanged and protected by green evidence.
- The named use case, actor ownership, dependency direction, and all five SOLID checks are recorded and pass.
- No business policy moved outward and no speculative abstraction was introduced.
- The common clean-up gate and documentation gate pass.
