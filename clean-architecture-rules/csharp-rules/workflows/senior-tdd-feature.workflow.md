---
description: Implement a C# backend feature through a senior TDD vertical slice with Clean Architecture boundaries.
---

# C# Senior TDD Feature Workflow

Use this workflow for new or changed .NET backend behavior.

## Phase 1: Understand The Slice

**Goal**: Locate the smallest behavior change.

Checklist:

- Identify the actor and business outcome.
- Frame the acceptance behavior with A-TDD before choosing implementation details.
- Find the existing module, use case, ports, adapters, controllers, and tests.
- Preserve existing conventions unless the task asks for a refactor.
- Decide whether the first test is unit, integration, or API contract.
- Preserve or improve 90%+ unit coverage for touched domain/application code.

## Phase 2: Red

**Goal**: Add the smallest failing test.

Checklist:

- Use the established test project and assertion style.
- Name the test with Given-When-Then or local convention.
- Arrange only required data and dependencies.
- Act with one behavior call when practical.
- Assert observable behavior.
- Use real value objects/entities and manual fakes for outgoing ports.

Start with an edge case when the rule is risky. Otherwise start with the happy path that defines the slice.

## Phase 3: Green

**Goal**: Make the test pass with minimal production code.

Checklist:

- Add or update request/response records only if they clarify the boundary.
- Add only the focused ports currently needed.
- Keep business rules in entities/value objects/domain services when they belong there.
- Keep use cases as orchestration.
- Do not touch infrastructure unless the test or behavior requires it.

## Phase 4: Adapter And Boundary

**Goal**: Wire real infrastructure only when the feature needs it.

Checklist:

- Implement EF Core command/query adapters in DataAccess.
- Implement HTTP DTO/controller changes in WebApi.
- Implement message mapping in the message adapter project.
- Register dependencies in `ServiceCollectionExtensions` or `Program.cs`.
- Add integration/API tests for changed adapters or contracts.

## Phase 5: Refactor

**Goal**: Improve design with tests green.

Checklist:

- Remove duplication.
- Improve names.
- Extract value objects where repeated primitive rules appear.
- Split ports if a client depends on unused members.
- Move mapping back to the owning boundary.
- Delete unused code.

## Phase 6: Verify

**Goal**: Prove the touched slice works.

Checklist:

- Run targeted unit tests.
- Run relevant integration/API tests when adapters changed.
- Check domain/application unit coverage for touched projects; add meaningful tests if it is below 90%.
- Confirm files remain readable and close to size limits.
- Confirm no new framework dependency leaked into core.
- Summarize behavior, tests, and any unverified scope.
