---
rule_id: RULE-CSHARP_BUSINESS_LOGIC_UNIT_TESTS
trigger: model_decision
description: C# business logic unit test rules for domain and application code using xUnit, FluentAssertions, manual fakes, and Given-When-Then naming.
globs: **/*Test.cs,**/*Tests.cs,**/*.Tests/**/*.cs,**/*.UnitTests/**/*.cs
---

# C# Business Logic Unit Tests

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.
- Apply `common-test-assertion-structure.md`: all `Assert`, `Should`, `Throws`, or equivalent calls belong only in `// Then / Assert`.

For new backend business behavior, use ATDD plus TDD: frame the actor-visible acceptance behavior, capture it with a focused failing test, implement the smallest useful production logic, and refactor with tests passing.

## Test Scope

Unit tests cover domain and application behavior without infrastructure.

No unit test should use:

- EF Core or real `DbContext`
- RabbitMQ or broker clients
- filesystem or network
- real external APIs
- real time when deterministic behavior matters
- ASP.NET/Lambda host unless the test is intentionally an HTTP integration test

Use real entities and value objects. Create project-local manual fakes, stubs, or spies for outgoing ports.

Do not use mocking libraries such as Moq, NSubstitute, FakeItEasy, JustMock, or similar tools. Test doubles should be small hand-written classes in the test project.

## acceptance behavior Coverage Objective

Use ATDD to translate actor-expected behavior into executable tests, then drive domain/application design through focused unit tests.

Use the Red, Green, Refactor loop:

- Red: add the smallest failing test for the next rule.
- Green: implement only enough production code to pass.
- Refactor: improve structure with tests green.

Coverage target:

- Maintain 90%+ aggregate project-wide production coverage, with domain/application unit coverage also at least 90%.
- Prioritize entities, value objects, domain services, use cases, and application ports.
- Do not inflate coverage with shallow tests for DTO-only files, generated code, framework wiring, or trivial property holders.
- Use HTTP integration tests for EF Core, WebApi/Lambda, local-resource, and DI wiring, but not as a substitute for core unit coverage.
- If project-wide coverage drops below 90% or touched domain/application coverage regresses, add meaningful tests before finishing.

## Naming

Prefer Given-When-Then test names for new tests:

```csharp
[Fact]
public async Task GivenValidTelemetry_WhenProcessed_ThenRecordDataSuccessfully()
```

If the project already uses snake_case, follow it. Do not rename existing test styles unless the task is a naming refactor.

## Structure

Use clear sections:

```csharp
// Arrange
var SUT = CreateSut();

// Act
var result = await SUT.Execute(request);

// Assert
result.Should().NotBeNull();
```

- Arrange/Given creates data and dependencies only.
- Act/When should be one behavior call when practical.
- Assert/Then is the only section that calls assertion APIs and verifies observable behavior.
- Builders, fixtures, setup, fakes, and action helpers return data/errors; they do not assert.
- Name the system under test `SUT` in new test classes unless local style uses `sut`.
- Keep one reason to fail per test.
- Avoid over-asserting unrelated fields.

## Assertions

- Use the assertion style already established in the project: FluentAssertions or xUnit assertions.
- Keep every assertion call in the final `// Then / Assert` section; do not assert in Arrange, Act, setup, fixtures, or helpers.
- Do not mix assertion styles in one test class without a reason.
- Assert exception type, parameter name, and stable domain message when relevant.
- Avoid brittle full framework messages unless message is a public contract.
- Assert interactions only when the interaction is the observable outcome.
- Do not repeat the same assertion block across many tests; extract a named assertion helper only for a stable behavior contract.
- Do not assert every field when the scenario only cares about one business outcome.

## Suite Quality

- Do not create trivial tests only to raise coverage.
- Avoid tests that only instantiate DTOs, call getters, verify constants, or cover framework wiring without behavior.
- Avoid fragile tests coupled to private methods, internal call order, exact timestamps, log text, full error strings, or unrelated implementation details.
- Verify manual fake/spy calls only when the interaction is the observable behavior.
- Prefer one meaningful behavior test over several shallow line-coverage tests.

## Manual Doubles

Use manual test doubles for outgoing ports when unit tests need a dependency.

Guidelines:

- Fake or spy outgoing dependencies, not domain objects.
- Keep doubles behavior-focused.
- Do not make doubles smarter than the production port contract.
- Delete unused doubles.
- Prefer builders/fixtures when setup becomes repetitive.
- Do not add Moq, NSubstitute, FakeItEasy, JustMock, or similar mocking packages.

## Test Data

- Use real value objects and entities.
- Create small factory methods for valid defaults.
- Use builders when many tests vary a few fields.
- Avoid magic values when a named constant improves intent.
- Avoid test data that violates unrelated invariants.

## Edge Cases First

Start with risky small failures:

- null, empty, whitespace
- out-of-range number
- invalid enum/state
- duplicate business key
- missing entity
- unauthorized actor
- idempotency or repeated command
- dependency exception

Then add the happy path.

## Organization

Group tests by business concern or behavior, not by "happy path" and "error cases".

Prefer:

```text
BrandCreatorTest.cs
VersionCreatorTestCabin.cs
SpeedValidationTests.cs
DeviceValidationTests.cs
```

Avoid broad catch-all files that exceed 150 lines.

## Done Criteria

- Failing test existed first.
- Test exercises behavior through the smallest meaningful public contract.
- No infrastructure appears in unit tests.
- Project-wide production coverage remains at 90%+; domain/application unit coverage remains at 90%+ or improves in touched projects.
- Test is deterministic and readable.
- Production code was refactored after green when needed.
