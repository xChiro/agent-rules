---
workflow_id: WORKFLOW-COMMON_SDD_MIGRATE_LEGACY_TESTS_WORKFLOW
trigger: manual
description: "Migrate legacy backend tests to the canonical unit and integration structure without weakening behavior evidence."
---

# Common SDD Migrate Legacy Tests Workflow

Use this workflow when an existing backend has tests outside the canonical structure or has separate repository, adapter, API, end-to-end, Lambda, or infrastructure suites that must be consolidated.

The target structure has exactly two runtime suites:

```text
tests/unit/
tests/integration/http/
tests/integration/infrastructure/
```

`http` and `infrastructure` are scopes of the single integration suite, not additional suites. Apply the language test rule and `common-test-layer-isolation.md` for implementation details.

## Phase 1: Establish The Migration Contract

- Create or update the owning refactor spec with `change_type: refactor`, the migration reason, non-goals, risk classification, and a documentation task.
- Record `WORKFLOW-COMMON_SDD_MIGRATE_LEGACY_TESTS_WORKFLOW` in `workflow-routing.md` and map every legacy test group to one target scope.
- Show the proposed inventory and migration plan before writing spec artifacts; obtain Gate 1 approval.
- Do not change production behavior, public contracts, business scenarios, or test expectations as part of this migration.
- Keep one migration microtask active at a time. Each task has one source group, one target scope, one `TEST-*`/`SCN-*` mapping, a verification command, and a rollback point.

## Phase 2: Inventory And Classify

For every legacy test file, record its current path, entry point, dependencies, state, external systems, build tags/project, and target path.

Classify by behavior rather than by the current folder name:

- Domain and application behavior without external infrastructure -> `tests/unit/`.
- Real HTTP, API Gateway, Lambda HTTP, message, worker, or CLI public-entry behavior -> `tests/integration/http/`.
- Real persistence, broker, cache, storage, database, queue, adapter, or resource wiring -> `tests/integration/infrastructure/`.
- Third-party API calls -> keep the application client and wiring real, but route the third party through a controlled WireMock-style simulator or equivalent.
- Tests that mix public entry and real resources -> place them in `tests/integration/http/`; use-case scenarios that exercise real adapters/resources belong in `tests/integration/infrastructure/`.

Do not classify a test as unit merely because it calls a handler directly. Do not classify an adapter test as HTTP unless a real public request enters the running service.

## Phase 3: Protect Current Behavior

- Run each legacy group independently from a clean process and capture its baseline command, result, duration, and diagnostics.
- Add or identify characterization tests for uncovered observable behavior before moving or simplifying tests.
- Preserve existing assertions, status codes, response contracts, persistence effects, queue messages, and error identity.
- Move assertions into the final `// Assert` section; use exact `// Arrange`, `// Act`, and `// Assert` comments with one physical-line Act statement that invokes the layer-appropriate SUT/use case/public boundary. Setup and action helpers return values or errors and never assert.
- Ask for Gate 2 approval before modifying test code.

## Phase 4: Migrate In Small Groups

For each approved group:

1. Create the target directory and update the test traceability path.
2. Move the test and its minimal fixtures/builders to the target scope; do not copy tests into both locations.
3. Remove dependencies on another test layer, shared mutable state, execution order, or unit-produced artifacts.
4. Keep unit tests free of network, database, filesystem, cloud SDK, Docker, and environment dependencies.
5. For `integration/http`, send a real request through the public boundary and use the real composition root and adapters.
6. For `integration/infrastructure`, write or preserve the use-case-driven RED first, then start real local infrastructure with Docker, Testcontainers, or a faithful emulator such as LocalStack or DynamoDB Local and make the real adapter implementation GREEN.
7. Mock or simulate only third-party APIs with WireMock, a small hand-written HTTP stub, or an equivalent controlled simulator; never mock the application's own adapter, persistence, queue, or local resource under test.
8. In Go, use the standard `testing` runner with `testify/assert` or `testify/require`; use hand-written outgoing-port doubles in unit tests and no generated mocking framework.
9. In C#, keep HTTP and infrastructure scopes in the integration project and use the real hosted composition with test-safe endpoints and credentials.
10. Obtain the affected layer gate before changing production code. This workflow normally changes test structure only; any production change requires the normal inside-out lifecycle.

Run the focused target command after every group. Do not require unit tests to run before HTTP or infrastructure integration tests, and do not use shared test state between scopes.

## Phase 5: Remove Legacy Structure

- Delete the old test file only after its target test passes independently and its traceability mapping is updated.
- Remove obsolete test projects, packages, build tags, fixtures, mocks, helpers, and CI commands only when no migrated test references them.
- Do not retain alias suites or compatibility copies. Git history and the migration spec preserve traceability.
- Update CI to the canonical jobs `unit-tests` and `integration-tests`; focused HTTP and infrastructure commands remain scopes of `integration-tests`.
- Update repository maps, test documentation, `tasks.md`, `traceability.yaml`, `verification.md`, and `change-summary.md`.

## Verification

Run and record, independently and from clean state:

```text
unit command
integration/http command
integration/infrastructure command
full project regression command
```

Also run the repository's format, lint, architecture, coverage, security, and clean-up gates. Confirm that the migration did not add a third runtime suite, weaken assertions, introduce test-order dependencies, or reduce production coverage. If a baseline test cannot be migrated without changing behavior, stop and evolve the spec instead of silently rewriting it.

## Done

- Every legacy test has one target scope and one traceability mapping.
- Only `unit` and `integration` runtime suites remain.
- Integration evidence is under the `http` or `infrastructure` scope.
- Unit tests use no external infrastructure; integration infrastructure is real locally; third-party APIs are controlled simulators.
- Each affected scope passes alone from clean state, and full regression passes.
- Legacy folders, duplicate tests, obsolete fixtures, and obsolete CI commands are removed.
- Spec artifacts, workflow routing, repository documentation, and verification evidence are converged.
