---
workflow_id: WORKFLOW-COMMON_SDD_REFACTOR_HTTP_TESTS_WORKFLOW
trigger: manual
description: "Refactor HTTP integration tests through the real public boundary, composition root, and locally managed infrastructure."
---

# Common SDD Refactor HTTP Tests Workflow

Use this tool for `tests/integration/http/` or the repository's equivalent HTTP integration scope. Load `common-sdd-refactor-lifecycle.workflow.md`, `common-http-integration-harness.md`, `common-test-layer-isolation.md`, and `common-test-data-and-double-patterns.md`.

## Mandatory HTTP Contract

- The test sends a real HTTP request through the public router/server or API Gateway/Lambda harness and uses the real composition root, Application use case, adapters, and locally managed infrastructure.
- Do not call a controller, handler, Lambda function, use case, repository, or adapter directly from an HTTP integration test.
- Do not replace owned databases, queues, caches, storage, adapters, or composition wiring with mocks. Simulate only third-party APIs using WireMock or a small hand-written HTTP stub; never add mocking libraries or generated mocks.
- Define the ATDD/BDD scenario and executable HTTP RED before changing routing, delivery, infrastructure, DI, schema, or composition production code. Preserve the public contract during a behavior-preserving refactor.
- Apply exact `// Arrange`, `// Act`, and `// Assert` sections. `Arrange` owns fresh request data, real resources, readiness, seed, and cleanup without assertions; `Act` contains exactly one physical-line public HTTP request; `Assert` contains all response and observable side-effect assertions.
- Keep exhaustive business-rule partitions in Domain/Application unit tests. HTTP tests prove public routing, serialization, auth/session context, mapping, DI, persistence wiring, and error contracts.

## Execution

1. Show the refactor plan, public endpoint, actor, scenario, real resources, third-party simulator, isolation, cleanup, non-goals, and commands; obtain Gate 1.
2. Update spec artifacts, `TEST-*` mapping, routing, tasks, and change summary; obtain Gate 2 before editing tests or outer production.
3. Run the baseline HTTP integration command from a clean process and capture readiness, schema/migration, seed, diagnostics, and cleanup evidence.
4. Refactor one test concern at a time: request builder, Object Mother, SUT/public client factory, fixture lifecycle, readiness, WireMock scenario, assertion grouping, response contract, or isolation.
5. Run the focused HTTP test after every change, then the complete HTTP scope, relevant infrastructure scope, core unit regression, and applicable architecture/coverage/security gates.
6. If the refactor requires changing business behavior, a public contract, authorization, schema semantics, or use-case responsibility, stop and route to SDD spec evolution.

## Done

- The test enters through the real HTTP/public boundary and preserves the real composition path.
- The test follows BDD and exact AAA with one public request in `Act`.
- Local infrastructure remains real, third parties use only controlled WireMock/hand-written stubs, and cleanup is deterministic.
- Public contract, traceability, isolation, and regression evidence are verified.
