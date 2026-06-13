---
trigger: always_on
description: TDD and ATDD skill for senior-style incremental implementation.
globs: **/*_test.go,**/*Test.cs,**/*Tests.cs
---

# TDD Senior Skill

Never implement production behavior before a failing test captures the expected behavior.

## Cycle

1. Red: write the smallest failing test for the next business rule.
2. Green: write the minimum production code needed to pass.
3. Refactor: improve names, duplication, boundaries, and file size with tests green.
4. Repeat for edge cases, alternative flows, infrastructure, and transport mapping.

## Test Shape

- Use Given-When-Then naming.
- Keep the When section to one behavior call.
- Arrange only data and dependencies needed by the behavior.
- Assert observable outcomes, persisted calls, emitted events, and returned errors.
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
- Handler/API tests verify request parsing, status codes, error mapping, auth/session extraction, and response DTOs.

## Test Tags

- Unit tests are the default fast suite and normally do not use a Go build tag.
- Integration tests must start with `//go:build integration`.
- End-to-end tests must start with `//go:build e2e`.
- Use `e2e` as the standard tag name for full end-to-end flows. Use `contract` only for provider-consumer/API contract tests.
- Keep tagged tests out of the default unit run unless the repository intentionally documents a different policy.

## Done Means

- Failing test existed before production code.
- New behavior has happy path and meaningful edge cases.
- No unused ports, request fields, mocks, or test helpers.
- The final test command for the touched scope passes.
