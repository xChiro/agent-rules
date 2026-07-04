---
trigger: model_decision
description: C# unit testing and TDD standards for domain and application code using xUnit, FluentAssertions, manual fakes, and Given-When-Then naming.
globs: **/*Test.cs,**/*Tests.cs,**/*.Tests/**/*.cs,**/*.UnitTests/**/*.cs
---

# C# Unit Testing Standards

Follow A-TDD and TDD for new behavior: frame the actor-visible acceptance behavior, then use Red, Green, Refactor. Do not write production behavior before a failing test captures the expected behavior.

## Test Scope

Unit tests cover domain and application behavior without infrastructure.

No unit test should use:

- EF Core or real `DbContext`
- RabbitMQ or broker clients
- filesystem or network
- real external APIs
- real time when deterministic behavior matters
- ASP.NET host unless the test is intentionally an API/integration test

Use real entities and value objects. Fake outgoing ports.

## A-TDD Coverage Objective

Use A-TDD to translate actor-expected behavior into executable tests, then drive domain/application design through focused unit tests.

Coverage target:

- Maintain 90%+ unit test coverage for domain and application layers.
- Prioritize entities, value objects, domain services, use cases, and application ports.
- Do not inflate coverage with shallow tests for DTO-only files, generated code, framework wiring, or trivial property holders.
- Use integration tests for EF Core, WebApi, message bus, hosted services, and DI, but not as a substitute for core unit coverage.
- If touched domain/application code is below 90%, add meaningful unit tests before finishing.

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
- Assert/Then verifies observable behavior.
- Name the system under test `SUT` in new test classes unless local style uses `sut`.
- Keep one reason to fail per test.
- Avoid over-asserting unrelated fields.

## Assertions

- Use the assertion style already established in the project: FluentAssertions or xUnit assertions.
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
- Verify mocks only when the interaction is the observable behavior.
- Prefer one meaningful behavior test over several shallow line-coverage tests.

## Manual Doubles

Prefer manual fakes/mocks for outgoing ports when they stay simple.

Guidelines:

- Mock outgoing dependencies, not domain objects.
- Keep doubles behavior-focused.
- Do not make doubles smarter than the production port contract.
- Delete unused doubles.
- Prefer builders/fixtures when setup becomes repetitive.

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
- Domain/application unit coverage remains at 90%+ or improves toward it in touched projects.
- Test is deterministic and readable.
- Production code was refactored after green when needed.
