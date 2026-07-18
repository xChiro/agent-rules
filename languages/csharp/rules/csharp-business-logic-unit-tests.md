---
rule_id: RULE-CSHARP_BUSINESS_LOGIC_UNIT_TESTS
trigger: model_decision
description: "C# business logic unit test rules for domain and application code using xUnit, FluentAssertions, manual fakes, and Given-When-Then naming."
globs: "**/*Test.cs,**/*Tests.cs,**/*.Tests/**/*.cs,**/*.UnitTests/**/*.cs"
---

# C# Business Logic Unit Tests

## SDD Integration

Apply `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`, `RULE-COMMON_TEST_ASSERTION_STRUCTURE`, `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`, and `RULE-COMMON_TEST_LAYER_ISOLATION`. This rule adds C# unit-test mechanics only; the common lifecycle owns BDD, Domain/Application gates, traceability, and convergence.

For new backend business behavior, use ATDD plus TDD: frame the actor-visible acceptance behavior, capture it with a focused failing test, implement the smallest useful production logic, and refactor with tests passing.

## Test Scope

Unit tests cover domain and application behavior without infrastructure.

## Layer Independence (MANDATORY)

- Domain and Application have separate focused project/filter commands; each passes alone in a fresh test process.
- Application tests may reference Domain production assemblies, never Domain test execution, test fixtures, output, or mutable state.
- Domain tests do not reference Application or outer-layer production/test projects.
- Create manual doubles, clocks, IDs, random sources, and captured calls per test. Collection/class fixtures must be immutable or reset completely per case.
- The solution-wide unit command is combined regression evidence, not a replacement for the two standalone layer results.
- Randomized order/repeat/parallel execution is risk-selected evidence; independence is mandatory even when execution is sequential.

No unit test should use:

- EF Core or real `DbContext`
- RabbitMQ or broker clients
- filesystem or network
- real external APIs
- real time when deterministic behavior matters
- ASP.NET/Lambda host unless the test is intentionally an HTTP integration test

Use real entities and value objects. Create project-local manual fakes, stubs, or spies for outgoing ports.

Object Mothers return fresh valid records/entities; builders express one meaningful scenario variation. They do not assert, perform I/O, or encode application orchestration. Keep command/write test data separate from query/read-model test data.

Do not use mocking libraries such as Moq, NSubstitute, FakeItEasy, JustMock, or similar tools. Test doubles should be small hand-written classes in the test project.

## Acceptance Behavior And Coverage Objective

Use ATDD to translate actor-expected behavior into executable tests, then drive domain/application design through focused unit tests.

Use the Red, Green, Refactor loop:

- Red: add the smallest failing test for the next rule.
- Green: implement only enough production code to pass.
- Refactor: improve structure with tests green.

Coverage target:

- Maintain 90%+ aggregate project-wide production coverage, with domain/application unit coverage also at least 90%.
- Prioritize entities, value objects, domain services, use cases, and application ports.
- Do not inflate coverage with shallow tests for DTO-only files, generated code, framework wiring, or trivial property holders.
- Use integration tests for EF Core, WebApi/Lambda, messaging, local-resource, and DI wiring, but not as a substitute for core unit coverage. HTTP is the `integration/http` scope; infrastructure tests invoke the use case with real adapters/resources in `integration/infrastructure`.
- If project-wide coverage drops below 90% or touched domain/application coverage regresses, add meaningful tests before finishing.

## Naming

Use Given-When-Then test names for new tests:

```csharp
[Fact]
public async Task GivenValidTelemetry_WhenProcessed_ThenRecordDataSuccessfully()
```

If the project already uses snake_case, preserve that casing while retaining the Given_When_Then meaning. Rename existing tests when the test is touched or the legacy-test migration workflow is invoked.

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
- Act/When must be exactly one executable statement on one physical line containing the SUT/use-case behavior call.
- Assert/Then is the only section that calls assertion APIs and verifies observable behavior.
- Builders, fixtures, setup, fakes, and action helpers return data/errors; they do not assert.
- SUT factories expose constructor dependencies and do not hide business decisions or external resources.
- Name the system under test `SUT` in new test classes unless local style uses `sut`.
- Keep one reason to fail per test.
- Avoid over-asserting unrelated fields.

## Assertions

- Use the assertion style already established in the project: FluentAssertions or xUnit assertions.
- Keep every assertion call in the final `// Assert` section; do not assert in Arrange, Act, setup, fixtures, or helpers.
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

Avoid broad catch-all files that reach 150 lines; the common clean-up gate requires fewer than 150 physical lines.

## Done Criteria

- Failing test existed first.
- Test exercises behavior through the smallest meaningful public contract.
- No infrastructure appears in unit tests.
- Project-wide production coverage and domain/application unit coverage remain at 90% or higher, with no touched-scope regression.
- Test is deterministic and readable.
- Domain and Application standalone commands pass with `depends_on_test_layer: none` and no shared mutable fixture or environment state.
- Production code was refactored after green when needed.
