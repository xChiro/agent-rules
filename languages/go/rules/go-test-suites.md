---
rule_id: RULE-GO_TEST_SUITES
trigger: model_decision
description: "Go backend suite taxonomy with only unit and integration tests."
globs: "**/*_test.go"
---

# Go Test Suites

All tests follow `common-test-assertion-structure.md`: exact `// Arrange`, `// Act`, and `// Assert` sections, BDD Given/When/Then meaning, and one physical-line Act statement.

All tests also follow `common-test-layer-isolation.md`: Domain, Application, HTTP integration, and Infrastructure integration commands run independently from clean state and have no test-order dependency.

Apply `common-test-data-and-double-patterns.md`: use fresh Object Mother functions or small Test Data Builders, focused SUT factories, scoped fixtures, and outgoing-port doubles only.

Go uses the standard `testing` runner together with the popular `github.com/stretchr/testify/assert` and `github.com/stretchr/testify/require` helpers for assertions. Do not use `require.NoError(t, err)`; prefer an explicit, context-rich `if err != nil` check with `t.Fatalf` when the test cannot continue, or `assert.NoError` only when continuation is safe. Tests may import production APIs under test. Generated mocks and mocking frameworks are prohibited for new or changed tests; use small hand-written doubles, or WireMock/a small hand-written HTTP stub for third-party APIs.

This prohibition applies to unit-test doubles and assertion tooling. It does not prohibit running an external integration simulator such as WireMock in Docker; the application client and integration wiring remain real.

## Two Suites Only

Go backends use:

- `unit`: fast domain/application behavior with no external infrastructure; runs by default.
- `integration`: one suite under `tests/integration/`, with `http/` for real public entry behavior and `infrastructure/` for use-case-driven real adapter/resource wiring; both use the `integration` build tag.

Do not create a third suite or top-level folder for repository, adapter, handler, API, end-to-end, or Lambda integration. Place the evidence in `tests/integration/http/` or `tests/integration/infrastructure/`.

## Independent Test Layers

The two-suite taxonomy does not merge test-layer lifecycles:

- Domain has a focused package command and uses only Domain production code plus stateless helpers.
- Application has a different focused package command; it may import Domain production APIs but never Domain test packages, fixtures, execution output, or mutable state.
- HTTP integration has its own tagged command and provisions its server, local resources, seed, namespace, and cleanup without running unit tests first.
- Infrastructure integration has its own tagged command and provisions real databases, brokers, caches, storage, or emulators plus any controlled third-party simulators without running HTTP tests first.
- Interface and Composition behavior that touches delivery, DI, adapters, or resources belongs in the applicable `integration/http` or `integration/infrastructure` scope; static build/architecture checks are quality evidence, not another runtime suite.
- Record each affected focused command. `go test ./...` or `make test` is combined regression evidence, not proof that a layer is standalone.
- Use `-count=1` for clean evidence and `-shuffle=on` or repeated runs when risk requires order-dependence detection.

## Unit Tests

- Do not add a build tag unless the repository has an intentional existing convention.
- Run with the repository's normal command, typically `go test ./...`.
- Keep them deterministic and independent from network, database, filesystem, clock, cloud SDK, and environment state.
- Use real values for domain behavior and focused hand-written stubs/fakes/spies/mocks only for outgoing application ports.
- Use fresh deterministic Object Mothers or builders for test data; helpers return data/errors and never assert or contain business policy.
- Trace changed behavior with `TEST-*` IDs.
- Create all fakes, clocks, IDs, RNGs, and captured-call slices per test; do not share mutable package globals between Domain or Application cases.

## Integration Tests

Create HTTP RED only after `LAYER-GATE-APPLICATION`; infrastructure integration RED may be created for a use-case scenario that requires real adapter/resource behavior after the core gate and before affected infrastructure production.

- HTTP location: `tests/integration/http/<context>/` or a coherent existing equivalent.
- Infrastructure location: `tests/integration/infrastructure/<context>/` or a coherent existing equivalent.
- Filename: `*_integration_test.go`, with the scope expressed by the directory.
- First non-blank line: `//go:build integration`.
- HTTP tests enter through real HTTP, never direct handler/function/adapter calls.
- Infrastructure tests invoke the Application use case with the real adapter implementation and real local resources. They must not call the adapter as the system under test or replace an owned resource with a mock. Third-party APIs may use WireMock or a small hand-written HTTP stub.
- Run with `go test -v -tags=integration ./tests/integration/...` or the repository's documented equivalent; focused `http` and `infrastructure` commands must also be recorded when both are affected.
- Each integration scope must pass from a fresh process before any unit command and after unit commands; results must be identical.

## CI Contract

The canonical test jobs are `unit-tests` and `integration-tests`. A build, lint, architecture, package, security, deploy, or smoke job is not a third test suite.

The jobs start with independent state and neither test job declares the other as a state/artifact prerequisite. A deploy job may depend on both successful results.
