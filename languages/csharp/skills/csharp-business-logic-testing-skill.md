---
skill_id: SKILL-CSHARP_BUSINESS_LOGIC_TESTING_SKILL
name: csharp-business-logic-testing
trigger: model_decision
description: "C# business logic testing skill for implementing backend behavior through focused tests, minimal production code, refactoring, and 90%+ project-wide production coverage."
globs: "**/*.cs,**/*Test.cs,**/*Tests.cs"
---

# C# Business Logic Testing Skill

## SDD Integration

Load this skill only for C# Domain/Application test work after `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`. It adds testing technique; the common lifecycle owns BDD, gates, traceability, layer order, and convergence.

Use ATDD plus TDD for backend business behavior. Capture expected business behavior with focused tests before changing production logic. Start from the actor-visible outcome, then implement the smallest useful behavior and refactor with tests passing.

Keep all `Assert`, `Should`, `Throws`, or equivalent calls in the final `// Assert` section. Setup, fixtures, fakes, and action helpers return values/errors; they never assert.

Apply `RULE-COMMON_TEST_LAYER_ISOLATION`: Domain, Application, and HTTP Boundary projects/filters each pass alone in a fresh process; no layer consumes another layer's fixtures, host, output, environment mutation, or mutable state.
Apply `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`: use fresh Object Mothers/Test Data Builders, focused SUT factories, scoped fixtures, and manual outgoing-port doubles.

## TDD Cycle

1. ATDD frame: state the actor, acceptance outcome, and observable behavior.
2. Red: add the smallest failing test for the next business rule.
3. Green: implement the minimum production code that passes.
4. Refactor: improve names, duplication, boundaries, and size with tests green.
5. Repeat for edge cases, adapter behavior, and transport mapping.

## Test Selection

- Use unit tests for domain/application behavior.
- Use integration tests for EF Core, WebApi/Lambda, messaging, local-resource, and DI wiring; HTTP is the `integration/http` scope and use-case-driven real adapter/resource checks use `integration/infrastructure`.
- Use the existing test framework and assertion library.
- Prefer project-local manual fakes, stubs, or spies for outgoing ports.
- Do not use Moq, NSubstitute, FakeItEasy, JustMock, or similar mocking libraries.
- Do not mock entities or value objects.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and integration tests do not replace core coverage.

## Test Shape

- Use Given-When-Then naming; a local naming convention may not remove the Given/When/Then behavior meaning.
- Arrange only data and dependencies.
- Build Arrange data with fresh Mothers/builders; helpers return values/errors and never assert or execute the SUT.
- Act must contain exactly one executable statement on one physical line with the SUT/use-case behavior call.
- In `// Assert` (Then), assert observable outcome, persisted call, emitted event, exception, or response contract.
- Name the system under test `SUT` in new test classes unless local convention uses another casing.

## Edge Cases First

Start with small risky failures:

- empty or whitespace input
- out-of-range value
- missing required entity
- duplicate business key
- invalid state transition
- dependency failure
- idempotency or repeated command

Then add the happy path.

## Done Means

- A failing test existed before production code for changed business behavior.
- Production change is minimal.
- Refactor did not change behavior.
- Tests for the touched scope pass.
- Project-wide production coverage and domain/application unit coverage remain at 90% or higher, with no touched-scope regression.
- No unused test doubles, ports, request fields, or helpers remain.
- Every affected layer's standalone command and the combined command pass with `depends_on_test_layer: none`.
