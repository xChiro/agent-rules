---
workflow_id: WORKFLOW-COMMON_SDD_REFACTOR_INTEGRATION_TESTS_WORKFLOW
trigger: manual
description: "Refactor infrastructure integration tests driven by Application use cases and real locally managed infrastructure."
---

# Common SDD Refactor Integration Tests Workflow

Use this tool for `tests/integration/infrastructure/` or the repository's equivalent infrastructure-integration scope. Load `common-sdd-refactor-lifecycle.workflow.md`, `common-test-layer-isolation.md`, and `common-test-data-and-double-patterns.md`. If the test enters through HTTP, use `common-sdd-refactor-http-tests.workflow.md` instead.

## Mandatory Integration Contract

- The test starts from the Application use case and exercises the real Application port, adapter implementation, and locally managed resource. Do not call the adapter as the system under test in isolation.
- Use real Docker/Testcontainers services or faithful local emulators for databases, migrations, queues, topics, caches, object storage, and other infrastructure owned by the project.
- Never mock an owned local resource, Application port implementation, adapter, persistence layer, queue, cache, or storage under test.
- Third-party APIs may be simulated only with WireMock or a small hand-written HTTP stub. Do not add mocking libraries, generated mocks, or mock frameworks.
- Define the ATDD/BDD scenario and executable RED before changing infrastructure production code. Infrastructure GREEN must make that use-case scenario pass through the real implementation.
- Apply exact `// Arrange`, `// Act`, and `// Assert` sections. `Arrange` owns fresh scenario data and resource lifecycle without assertions; `Act` contains exactly one physical-line Application use-case call; `Assert` observes the result and real-resource side effects.
- Keep command/write and query/read scenarios separate when CQRS is used. Do not replace a query observation with a command-side result.

## Execution

1. Show the refactor plan, use case, actor, real resources, third-party simulators, isolation namespace, cleanup, non-goals, and commands; obtain Gate 1.
2. Update spec artifacts, `TEST-*` mapping, routing, tasks, and change summary; obtain Gate 2 before editing tests or infrastructure.
3. Run the baseline integration/infrastructure command from a clean process and capture readiness, schema/migration, seed, diagnostics, and cleanup evidence.
4. Refactor one test concern at a time: fixture lifecycle, readiness, namespace, Object Mother/Builder, use-case SUT factory, WireMock scenario, assertions, cleanup, or test-order isolation.
5. Keep the real resource and application wiring intact. Run the focused integration test after every change, then the complete infrastructure scope, unit scope for regression, and applicable architecture/coverage/security gates.
6. If the refactor requires changing the use case, adapter contract, schema, event meaning, or public behavior, stop and route to the normal SDD change/spec workflow.

## Done

- The infrastructure test is use-case-driven and passes with real locally managed infrastructure.
- Third parties are controlled only by WireMock or hand-written HTTP stubs.
- No owned adapter/resource was replaced by a mock and no mocking library was added.
- AAA, isolation, deterministic cleanup, traceability, and behavior preservation are verified.
