---
skill_id: SKILL-CSHARP_BUSINESS_LOGIC_TESTING_SKILL
name: csharp-business-logic-testing
trigger: model_decision
description: C# business logic testing skill for implementing backend behavior through focused tests, minimal production code, refactoring, and 90%+ project-wide production coverage.
globs: **/*.cs,**/*Test.cs,**/*Tests.cs
---

# C# Business Logic Testing Skill

## SDD Baseline

- Follow `common-sdd-agentic-discipline.md` for every behavior-changing task.
- Keep specs versioned under `specs/features/<number>-<slug>/` when the project supports SDD artifacts.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Start with BDD Given/When/Then acceptance evidence, then unit-level ATDD-style focused failing test code, then production code.
- Refactor only with tests green and converge specs, tasks, parallel tracks, traceability, verification notes, and code.

Use ATDD plus TDD for backend business behavior. Capture expected business behavior with focused tests before changing production logic. Start from the actor-visible outcome, then implement the smallest useful behavior and refactor with tests passing.

Keep all `Assert`, `Should`, `Throws`, or equivalent calls in the final `Then/Assert` section. Setup, fixtures, fakes, and action helpers return values/errors; they never assert.

## TDD Cycle

1. ATDD frame: state the actor, acceptance outcome, and observable behavior.
2. Red: add the smallest failing test for the next business rule.
3. Green: implement the minimum production code that passes.
4. Refactor: improve names, duplication, boundaries, and size with tests green.
5. Repeat for edge cases, adapter behavior, and transport mapping.

## Test Selection

- Use unit tests for domain/application behavior.
- Use HTTP integration tests for EF Core, WebApi/Lambda, local-resource, and DI wiring.
- Use the existing test framework and assertion library.
- Prefer project-local manual fakes, stubs, or spies for outgoing ports.
- Do not use Moq, NSubstitute, FakeItEasy, JustMock, or similar mocking libraries.
- Do not mock entities or value objects.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and HTTP integration tests do not replace core coverage.

## Test Shape

- Use Given-When-Then naming or the local established naming.
- Arrange only data and dependencies.
- Act with one behavior call when practical.
- In `Then/Assert`, assert observable outcome, persisted call, emitted event, exception, or response contract.
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
- Project-wide production coverage remains at 90%+; domain/application unit coverage remains at 90%+ or improves in touched projects.
- No unused test doubles, ports, request fields, or helpers remain.
