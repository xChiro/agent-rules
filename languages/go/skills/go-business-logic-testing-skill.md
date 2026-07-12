---
skill_id: SKILL-GO_BUSINESS_LOGIC_TESTING_SKILL
name: go-business-logic-testing
trigger: always_on
description: Business logic testing skill for senior-style incremental implementation with 90%+ project-wide production coverage and protected domain/application behavior.
globs: **/*_test.go,**/*Test.cs,**/*Tests.cs
---

# Go Business Logic Testing Skill

## SDD Baseline

- Follow `common-sdd-agentic-discipline.md` for every behavior-changing task.
- Keep specs versioned under `specs/features/<number>-<slug>/` when the project supports SDD artifacts.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Start with BDD Given/When/Then acceptance evidence, then unit-level ATDD-style focused failing test code, then production code.
- Refactor only with tests green and converge specs, tasks, parallel tracks, traceability, verification notes, and code.


Use ATDD plus TDD for backend business behavior. Capture expected business behavior with focused tests before changing production logic. Start from the actor-visible outcome, then implement the smallest useful behavior and refactor with tests passing.

Keep all `assert`/`require` calls in the final `Then/Assert` section. Setup, fixtures, fakes, and the action helper return values/errors; they never assert.

## TDD Cycle

1. ATDD frame: state the actor, acceptance outcome, and observable behavior.
2. Red: write the smallest failing test for the next business rule.
3. Green: implement the minimum production code needed to pass.
4. Refactor: improve names, duplication, boundaries, and file size with tests green.
5. Repeat for edge cases, alternative flows, infrastructure, and transport mapping.

## Test Shape

- Use Given-When-Then naming.
- Keep the When section to one behavior call.
- Arrange only data and dependencies needed by the behavior.
- In `Then/Assert`, assert observable outcomes, persisted calls, emitted events, and returned errors.
- Prefer table tests/builders for repeated cases.
- Use real value objects/entities in unit tests; fake ports/adapters.
- Do not mock domain objects.

## Edge Cases First

Start with small failure modes before happy path when the rule is risky:

- empty or whitespace input
- invalid enum/status/type
- out-of-range numbers
- missing entity
- duplicate business key
- unauthorized actor
- idempotency and repeated commands
- external dependency failure

## Boundaries

- Domain/application unit tests must not touch databases, queues, network, filesystem, environment, or clocks directly.
- Integration tests verify real adapters, mapping, DI, migrations/tables, messaging, and transaction/event behavior.
- HTTP integration tests verify request parsing, status codes, error mapping, auth/session extraction, response DTOs, DI, persistence, and local-resource wiring.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and HTTP integration tests must not mask weak core coverage.

## Test Tags

- Unit tests are the default fast suite and normally do not use a Go build tag.
- HTTP integration tests must start with `//go:build integration`.
- Do not create separate API, infrastructure, repository, adapter, handler, or contract runtime suites.
- Keep tagged tests out of the default unit run unless the repository intentionally documents a different policy.

## Done Means

- A failing test existed before production code for changed business behavior.
- New behavior has happy path and meaningful edge cases.
- Project-wide production coverage remains at 90%+; domain/application unit coverage remains at 90%+ or improves in touched packages.
- No unused ports, request fields, mocks, or test helpers.
- The final test command for the touched scope passes.
