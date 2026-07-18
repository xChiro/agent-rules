---
skill_id: SKILL-GO_BUSINESS_LOGIC_TESTING_SKILL
name: go-business-logic-testing
trigger: model_decision
description: "Business logic testing skill for senior-style incremental implementation with 90%+ project-wide production coverage and protected domain/application behavior."
globs: "**/*_test.go"
---

# Go Business Logic Testing Skill

## SDD Integration

Load this skill only for Go Domain/Application test work after `RULE-COMMON_SDD_AGENTIC_DISCIPLINE`. It adds testing technique; the common lifecycle owns BDD, gates, traceability, layer order, and convergence.


Use ATDD plus TDD for backend business behavior. Capture expected business behavior with focused tests before changing production logic. Start from the actor-visible outcome, then implement the smallest useful behavior and refactor with tests passing.

Use Go's standard `testing` package for the runner and `github.com/stretchr/testify/assert`/`require` for assertions. Do not use `require.NoError(t, err)`; prefer an explicit context-rich `if err != nil` check with `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe. Keep all assertion calls, including `assert.*`, other `require.*`, and `t.Error`/`t.Fatalf`, in the final `// Assert` section. Setup, fixtures, doubles, and action helpers return values/errors; they never assert. Production APIs under test may be imported; do not use generated mocks or mocking frameworks in unit tests. Integration tests may run external simulators such as WireMock in Docker.

Apply `RULE-COMMON_TEST_LAYER_ISOLATION`: run focused Domain, Application, and Boundary commands independently with `-count=1`; no command consumes another layer's fixtures, process, cache, output, or mutable state. The full suite is combined regression evidence only.
Apply `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`: use fresh Object Mothers/Test Data Builders, focused SUT factories, scoped fixtures, and outgoing-port doubles only.

## TDD Cycle

1. ATDD frame: state the actor, acceptance outcome, and observable behavior.
2. Domain Red/Green/Refactor when an invariant changes; pass `LAYER-GATE-DOMAIN`.
3. Application Red/Green/Refactor with hand-written outgoing-port doubles; pass `LAYER-GATE-APPLICATION`.
4. When outer production is affected, create executable Boundary RED, then implement infrastructure, delivery, and module-owned composition in order; otherwise keep Boundary GREEN and `not_affected`.
5. Refactor each layer with tests green and repeat for meaningful partitions.

## Test Shape

- Use Given-When-Then naming.
- Use exact `// Arrange`, `// Act`, and `// Assert` comments; `// Act` contains exactly one executable statement on one physical line that invokes the SUT/use case.
- Arrange only data and dependencies needed by the behavior.
- Create Arrange data through fresh Mothers/builders; helpers return values/errors and never assert or execute the SUT.
- In `// Assert` (Then), assert observable outcomes, persisted calls, emitted events, and returned errors.
- Prefer table tests/builders for repeated cases.
- Use real value objects/entities in domain tests; hand-write doubles only for outgoing application ports.
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
- After the core gate, integration tests verify real adapters, mapping, DI, migrations/tables, messaging, and transaction/event behavior. HTTP is the `integration/http` scope.
- Boundary integration tests verify request/message parsing, delivery status or acknowledgment, error mapping, auth/session extraction when applicable, response/event DTOs, DI, persistence, and local-resource wiring.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and integration tests must not mask weak core coverage.

## Test Tags

- Unit tests are the default fast suite and normally do not use a Go build tag.
- Boundary integration tests must start with `//go:build integration`.
- Do not create a third runtime suite; use `tests/integration/http/` and `tests/integration/infrastructure/` as scopes of the single integration suite.
- Keep tagged tests out of the default unit run unless the repository intentionally documents a different policy.

## Done Means

- A failing test existed before production code for changed business behavior.
- New behavior has happy path and meaningful edge cases.
- Project-wide production coverage and domain/application unit coverage remain at 90% or higher, with no touched-scope regression.
- No unused ports, request fields, mocks, or test helpers.
- The final test command for the touched scope passes.
- Every affected layer's standalone command and the combined command pass; `depends_on_test_layer` is `none`.
