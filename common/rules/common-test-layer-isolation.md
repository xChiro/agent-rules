---
rule_id: RULE-COMMON_TEST_LAYER_ISOLATION
trigger: model_decision
description: "Mandatory independence and deterministic isolation between Domain, Application, and executable Boundary test layers."
---

# Common Test Layer Isolation

Development order does not create runtime coupling between test layers. Domain, Application, and executable Boundary evidence must each be runnable alone from a clean process, in any order, without another test layer preparing state or running first.

## Independent Layer Contracts

### Domain

- A focused standalone command selects the domain tests without running Application or Boundary tests.
- Tests use domain production code, real domain values, and pure layer-owned or neutral stateless test helpers only.
- Tests do not import Application, adapters, delivery code, composition, cloud SDKs, filesystem, network, database, environment state, or a real clock/random source.

### Application

- A focused standalone command selects the application tests without requiring Domain tests to run first. Application may depend on Domain production APIs, never on Domain test execution or mutable test state.
- Tests use hand-written doubles only for outgoing Application-owned ports and do not boot real infrastructure, HTTP/message hosts, DI, or deployment configuration.
- Fixtures and captured calls are created per test; no singleton double or package/class fixture may leak mutations between cases.

### Unit Test Boundary

- The canonical `unit` suite tests only Domain and Application production code: domain behavior, invariants, policies, and use-case orchestration.
- Do not use unit tests as the primary test for HTTP requests, database persistence, migrations, queues, caches, object storage, cloud SDK wiring, adapters, DI composition, or other infrastructure behavior. Those behaviors belong in `integration/http` or `integration/infrastructure`.

### Integration Suite: HTTP Scope

- A focused standalone command starts from a clean process and bootstraps its own real composition root and required local resources.
- The suite owns readiness, schema/migration, minimal seed, unique namespace, request/message execution, diagnostics, and deterministic cleanup.
- It does not consume state, fixtures, generated IDs, in-memory servers, or side effects left by Domain/Application tests, and those tests do not need to run first.
- The HTTP scope lives under `tests/integration/http/` or the repository's equivalent and enters through the real public boundary.

### Integration Suite: Infrastructure Scope

- A focused standalone command starts from a clean process and verifies the real persistence, messaging, storage, cache, or adapter integration against Docker/Testcontainers or a faithful local emulator.
- The infrastructure scope starts from the Application use case and uses the real composition of the use case, application port, adapter, and local resource. Do not call the adapter as the system under test from a separate direct-adapter test.
- It must not replace the touched database, queue, cache, storage, or other infrastructure resource with a mock. Third-party HTTP/API dependencies may use WireMock or a small hand-written HTTP stub, with scenario-specific contracts, failure modes, timeouts, and outgoing-contract assertions.
- The infrastructure scope lives under `tests/integration/infrastructure/` or the repository's equivalent. HTTP and infrastructure are focused scopes of one `integration` suite/job, not separate runtime suites.
- Each scope owns readiness, schema/migration, minimal seed, unique namespace, diagnostics, and deterministic cleanup.

### Existing Outer-Layer Focused Scopes

- When a repository keeps focused Infrastructure, Interface, or Composition test packages inside the canonical integration suite, each focused scope also has its own standalone command and isolated state.
- These commands may test pure mapping or wiring but do not replace executable Boundary evidence and do not create another runtime suite or human Gate 3 scope.
- An outer focused test cannot reuse a host, adapter instance, resource, environment mutation, or fixture created by a core or Boundary test.

## Isolation Invariants

1. Every test layer has a documented `standalone_test_command`; a combined command is additional evidence, not a substitute.
2. `depends_on_test_layer` is always `none`. Architectural production dependencies are allowed inward; runtime test-order dependencies are not.
3. Each test owns its mutable state. Use per-test instances, tenant/partition/schema/key prefixes, queues, temporary directories, ports, clocks, IDs, and random seeds as applicable.
4. Tests are repeatable and order-independent. Running a layer alone, after another layer, with shuffle/random order, or repeatedly must not change its result.
5. Setup and cleanup belong to the same layer. Cleanup runs on success and failure and may delete only resources allocated by that test namespace.
6. Environment variables, global registries, clocks, random sources, feature flags, and process-wide hooks are restored before a test ends.
7. A shared helper is allowed only in a neutral test-support module when it is immutable/stateless and has no test lifecycle, assertions, business policy, or outer-layer dependency.
8. Coverage reports may be merged after all commands finish; test execution must not consume another layer's coverage file, result artifact, cache, or mutable workspace.
9. CI may reuse an immutable production build artifact, but each test job provisions its own test state and must not depend on success artifacts or side effects from another test job.
10. Parallel execution is optional and allowed only after isolation is proven. Independence between layers is mandatory even when each layer runs sequentially.

## Required SDD Evidence

For every affected test scope, record in `tasks.md`, `red-green-refactor.md`, and `verification.md`:

- `test_layer: domain | application | boundary | infrastructure | interface | composition`;
- `integration_scope: http | infrastructure` whenever `test_layer: boundary | infrastructure | interface | composition` is exercised by the integration suite;
- canonical path: `tests/unit/` for unit tests, `tests/integration/http/` for public-entry tests, or `tests/integration/infrastructure/` for real adapter/resource tests;
- `standalone_test_command`;
- `depends_on_test_layer: none`;
- `isolation_scope` and owned mutable resources;
- setup, cleanup, and deterministic clock/ID/random strategy;
- standalone result and combined-suite result;
- shuffle/repeat/parallel evidence when required by risk.

Gate 3 rejects evidence when the focused command passes only after another layer, reuses state created elsewhere, cannot clean up its own resources, or hides an ordering dependency behind a combined command.
