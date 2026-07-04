---
trigger: model_decision
description: C# A-TDD and TDD skill for implementing backend behavior through failing tests, minimal production code, refactoring, and 90%+ domain/application unit coverage.
globs: **/*.cs,**/*Test.cs,**/*Tests.cs
---

# C# TDD Senior Skill

Never implement new production behavior before a failing test captures the expected behavior. Use A-TDD to frame actor-visible acceptance behavior before choosing the first unit test.

## Cycle

1. A-TDD: state the actor, acceptance outcome, and observable behavior.
2. Red: add the smallest failing test for the next business rule.
3. Green: write the minimum production code that passes.
4. Refactor: improve names, duplication, boundaries, and size with tests green.
5. Repeat for edge cases, adapter behavior, and transport mapping.

## Test Selection

- Use unit tests for domain/application behavior.
- Use integration tests for EF Core, WebApi, message broker, hosted service, and DI wiring.
- Use the existing test framework and assertion library.
- Prefer manual fakes for outgoing ports.
- Do not mock entities or value objects.
- Maintain 90%+ unit coverage for domain/application layers; integration tests do not replace this target.

## Test Shape

- Use Given-When-Then naming or the local established naming.
- Arrange only data and dependencies.
- Act with one behavior call when practical.
- Assert observable outcome, persisted call, emitted event, exception, or response contract.
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

- Test failed before production code changed.
- Production change is minimal.
- Refactor did not change behavior.
- Tests for the touched scope pass.
- Domain/application unit coverage remains at 90%+ or improves toward it in touched projects.
- No unused mocks, ports, request fields, or helpers remain.
