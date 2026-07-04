---
description: Create or change a C# application use case with TDD, DDD modeling, focused ports, and Clean Architecture boundaries.
---

# C# Create Use Case Workflow

Use this workflow when adding or modifying an application service/use case.

## Phase 1: Responsibility

**Goal**: Define the use case boundary.

Checklist:

- Identify the actor.
- State the single business outcome.
- Frame the acceptance behavior with A-TDD before implementation.
- Find the domain entity/value object that owns the rule.
- Identify required reads, writes, side effects, and external dependencies.
- Reuse existing module naming.

## Phase 2: Failing Unit Test

**Goal**: Capture behavior before implementation.

Checklist:

- Add test in the existing unit test project.
- Use manual fakes for outgoing ports.
- Use real domain objects/value objects.
- Assert exception for failure paths or returned result/port call for success.
- Keep Act to one use case call when practical.

## Phase 3: Model Domain Inputs

**Goal**: Prevent invalid state.

Checklist:

- Create or reuse value objects for meaningful primitives.
- Put invariant validation in value object/entity constructors or factories.
- Add direct value object/entity tests when rules are non-trivial.
- Avoid passing raw primitives across several layers when the concept has rules.

## Phase 4: Define Ports

**Goal**: Add only current dependencies.

Checklist:

- Commands for writes.
- Queries for reads.
- Checkers for existence/uniqueness.
- Publishers/senders for side effects.
- Clock/id/session ports only when deterministic behavior or boundary isolation needs them.

Do not create a generic repository or interface for private helpers.

## Phase 5: Implement Use Case

**Goal**: Orchestrate the behavior.

Checklist:

- Create value objects.
- Load required state.
- Invoke domain behavior.
- Persist through command ports.
- Return an application result or domain object.
- Throw typed business exceptions.
- Respect `CancellationToken` for new async boundaries.

## Phase 6: Wire And Verify

**Goal**: Connect only what changed.

Checklist:

- Add service registration.
- Add adapter implementations if required.
- Add integration tests for new adapters.
- Preserve or improve 90%+ unit coverage for touched domain/application code.
- Run targeted tests.
- Refactor names and duplication after green.
