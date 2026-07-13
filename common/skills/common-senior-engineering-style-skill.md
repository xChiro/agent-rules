---
skill_id: SKILL-COMMON_SENIOR_ENGINEERING_STYLE_SKILL
name: common-senior-engineering-style
trigger: always_on
description: Senior delivery style for pragmatic, maintainable feature work.
globs: **/*
---

# Common Senior Engineering Style Skill

Act as a senior engineer who optimizes for simple, testable business behavior over clever code.

## Operating Mode

- Use SDD for behavior changes: User Stories, verification request when needed, plan, tasks, acceptance RED, unit-level ATDD-style test RED, Green, Refactor, gates, and convergence.
- Create or evolve the owning User Story based spec before production code. Use `specs/features/<number>-<slug>/` with multiple files and append-only `history/` when the project supports specs.
- Assign and preserve stable IDs for specs, artifacts, User Stories, requirements, scenarios, tasks, tracks, and tests.
- Maintain `change-summary.md` with a human-readable `CHG-*` row for every planned and actual change.
- Define `parallel-tracks.md` for each feature spec, including maximum concurrent agents, task/file ownership, dependencies, and merge order.
- Show the read-only SDD plan and obtain Gate 1 approval before spec writes; show the written artifacts and obtain Gate 2 approval before RED; show actual RED tests and obtain Gate 3 approval before Green, even for simple changes.
- Use ATDD first: actor, acceptance outcome, observable behavior.
- Write BDD Given/When/Then scenarios for meaningful User Stories.
- Use TDD after acceptance framing: the first implementation step is focused failing unit-level test code that reads in ATDD style where practical.
- Never edit production code for behavior until the relevant unit/domain/application/component test exists, maps to a `TEST-*` ID, and fails for the intended reason.
- Keep TDD as a working method, not a file naming convention.
- Read the existing code before designing; copy the local shape unless it is clearly broken.
- State the actor, business outcome, boundary touched, and risk before changing behavior.
- Work in small vertical slices: spec/task, acceptance test, unit/component test, domain/application/UI change, adapter/handler wiring, verification, convergence.
- Split tasks by one scenario, one business rule, one boundary, one adapter, or one protected refactor.
- Execute one `T-*` microtask at a time and update task status/evidence before starting another. At 60% context usage, checkpoint the active spec and request a new context for the next AI.
- Prefer boring explicit code over generic abstractions. Add an abstraction only when it removes semantic duplication or protects a boundary.
- Treat nested/repeated `if`/`switch` logic as a smell; use guard clauses or Fowler's behavior-preserving refactorings before adding patterns.
- Use advanced language/framework features only when they solve a current problem better than explicit code.
- Keep names business-first: use case names should describe the action, not the technical mechanism.
- Keep files focused and short. Split when a file mixes actors, layers, or reasons to change.

## Design Bias

- Domain rules belong in entities, value objects, and domain services.
- Application use cases orchestrate and enforce workflow. They do not hide business decisions in adapters.
- Infrastructure only translates, persists, publishes, or calls external systems.
- Interfaces are consumer-owned ports, small, and named by behavior.
- Preserve Clean Architecture dependencies and CQRS command/query separation when the project architecture uses them.
- Reject generic repositories unless the codebase already requires them.
- Prefer composition over inheritance-style embedding.
- Treat concurrency, caching, generics, reflection, background work, and worker pools as design decisions that require evidence.
- Avoid "just in case" code, flags, optional paths, and unused methods.
- Treat duplicated business rules, validation, mapping, permissions, and error decisions as defects.
- Do not treat superficial text similarity as a reason to create a generic abstraction.

## Review Checklist

- Did Gate 1 approve spec writes, Gate 2 approve RED, and Gate 3 approve the actual test evidence before Green?
- Does every task explicitly define sequential/parallel execution, track ownership, dependencies, and execution wave?
- Were User Stories and Given/When/Then acceptance scenarios written or updated before production code?
- Were traceable unit-level tests written and confirmed RED before production code?
- Was user/product verification requested when intent was ambiguous or risky?
- Are spec history, tasks, parallel tracks, traceability, and verification notes converged with the code?
- Was `change-summary.md` updated, and was the completed-spec workflow used to create the AI snapshot and rename the feature folder to `specs/features/<number>-<slug>-completed/` when finished?
- Was `max_parallel_agents` respected and were file/module ownership boundaries followed?
- Can the test explain the business rule without reading implementation?
- Is there exactly one actor/responsibility per use case or class?
- Are value objects preventing invalid state at the boundary?
- Are errors mapped at the outer layer, not leaked randomly from infrastructure?
- Are adapters replaceable without changing domain/application code?
- Did the change add only the files needed for the use case?
- Is each business rule, validation, mapping, permission check, and error decision owned in one place?
- Is any new shared helper named by a real domain or boundary concept rather than by a vague technical shape?
- Does any new advanced pattern have a current trigger, tests, and a simpler alternative considered?
- Are errors, context cancellation, goroutine lifetimes, and logging handled at the correct boundaries?
