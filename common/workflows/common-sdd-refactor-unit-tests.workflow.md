---
workflow_id: WORKFLOW-COMMON_SDD_REFACTOR_UNIT_TESTS_WORKFLOW
trigger: manual
description: "Refactor Domain and Application unit tests while preserving observable behavior, ATDD evidence, and isolated test contracts."
---

# Common SDD Refactor Unit Tests Workflow

Use this tool only for refactoring `tests/unit/` or the repository's equivalent Domain/Application unit-test scope. Load `common-sdd-refactor-lifecycle.workflow.md` and `common-test-assertion-structure.md`; use the language-specific test rules as stricter constraints.

Unit tests cover only Domain and Application production behavior. Do not use this tool to test or refactor HTTP, database, messaging, cache, storage, cloud SDK, adapter, DI, or composition behavior; route those changes to the integration or HTTP refactor tool.

## Mandatory Test Contract

- Preserve the business behavior, `TEST-*` mapping, Given/When/Then meaning, and observable outcomes. Never weaken an assertion or rewrite a scenario to make a refactor pass.
- Every test has exact `// Arrange`, `// Act`, and `// Assert` sections. `Arrange` creates fresh data/dependencies and has no assertions.
- `Act` contains exactly one executable statement on one physical line, and that statement executes the SUT: the Domain object/policy or Application use case. It may not call a builder, fixture, helper, state read, assertion, or second behavior.
- `Assert` contains all assertion/failure APIs and observes return values, errors, state transitions, events, or meaningful outgoing-port interactions.
- Use Object Mothers, Test Data Builders, focused SUT factories, and scoped fixtures. Helpers return data/errors/state and never assert or contain business policy.
- Keep Domain/Application test names, fixtures, doubles, SUT factories, and file/package names provider-neutral. Tests describe business capabilities; provider-specific names belong to the outer adapter/infrastructure test scope.
- Use real Domain values. Application doubles are small hand-written doubles only for outgoing Application-owned ports. Do not add mocking libraries, generated mocks, or mock frameworks.
- In Go, use `testing` plus `testify/assert` or `testify/require` for assertions, never `require.NoError(t, err)`, and keep the replacement error handling in `// Assert`.

## Execution

1. Show the unit-test refactor plan, affected behavior/actor/use case, test files, non-goals, and verification commands; obtain Gate 1.
2. Update spec artifacts, task/change rows, `TEST-*` traceability, and routing; obtain Gate 2 before editing tests.
3. Run the baseline Domain/Application standalone command and record the current behavior and isolation evidence.
4. Refactor one test concern at a time: names, AAA sections, duplicated data setup, Mother/Builder ownership, SUT factory wiring, double scope, assertion clarity, or test-layer isolation.
5. Run the focused unit test after every change, then the standalone Domain and Application commands, race/repeat/shuffle checks when applicable, and the full project regression.
6. Re-run the clean-up gate and verify no infrastructure dependency, hidden assertion, shared mutable state, test-order dependency, or behavior expectation changed.

## Done

- Only Domain/Application unit-test scope was changed.
- Every test follows Given/When/Then plus exact AAA, with one SUT execution in `Act`.
- Tests are deterministic, isolated, readable, and use only permitted hand-written doubles.
- Unit evidence and all spec/verification artifacts converge.
