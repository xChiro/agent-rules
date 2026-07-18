---
rule_id: RULE-GO_HTTP_INTEGRATION_TESTS
trigger: model_decision
description: "Go HTTP integration tests through the real REST or Lambda boundary with local infrastructure."
globs: "**/*_test.go,template.yaml"
---

# Go HTTP Integration Tests

Apply `common/rules/common-http-integration-harness.md` for the shared boundary, resource, isolation, cleanup, and evidence contract.
Apply `common/rules/common-test-layer-isolation.md`: the HTTP command owns its lifecycle and cannot depend on Domain/Application tests having run.
Apply `common/rules/common-test-data-and-double-patterns.md`: use scoped fixtures and fresh scenario data; keep the public request and real local infrastructure path real.
Apply `common/rules/common-test-assertion-structure.md`: use Given/When/Then behavior naming, exact `// Arrange`, `// Act`, and `// Assert` comments, keep `// Act` to one executable public request statement on one physical line, and keep all calls to `testing.T` failure methods in `// Assert`.

## SDD Baseline

- Apply the common SDD lifecycle before changing test or production code.
- Trace each test with a `TEST-*` ID linked to its `US-*`, `REQ-*`, and `SCN-*` IDs.
- Write the abstract BDD acceptance scenario first.
- Complete affected domain/application RED-GREEN-refactor cycles and pass `LAYER-GATE-APPLICATION` before creating executable HTTP RED.
- Confirm HTTP integration RED and obtain Gate 3-BOUNDARY before implementing infrastructure, delivery, or composition changes.

## Only Two Backend Suites

Go backends use only two suite roles:

1. Unit tests for domain/application behavior without external infrastructure.
2. Integration tests for the complete public path or infrastructure wiring with local infrastructure. This rule defines the `tests/integration/http/` scope; infrastructure-focused tests belong in `tests/integration/infrastructure/`.

Do not create a third integration suite. Keep HTTP tests under `tests/integration/http/` and persistence, broker, storage, cache, and adapter/resource tests under `tests/integration/infrastructure/`.

## Public Boundary

The test must send an HTTP request through the same boundary used by clients:

- Router/server endpoint for long-running services.
- `sam local start-api`, an equivalent local API Gateway emulator, or the repository's established HTTP harness for Lambda.

Calling a controller, handler, Lambda function, use case, repository, or adapter directly is not an HTTP integration test.

The exercised path should include, when applicable:

```text
HTTP request
  -> router or API Gateway mapping
  -> authentication/session extraction
  -> validation and DTO mapping
  -> use case
  -> real persistence/infrastructure adapter
  -> local database or service emulator
  -> HTTP response
```

## Local Infrastructure

- Use real local dependencies or faithful emulators: PostgreSQL, DynamoDB Local, LocalStack, Redis, object storage, or the project equivalent.
- Never replace touched local infrastructure with mocks in this suite. Third-party APIs may use controlled WireMock-style simulators with explicit contract, timeout, error, and retry scenarios.
- Use dummy credentials and local endpoints.
- Apply production-equivalent migrations, schemas, indexes, and table definitions.
- Seed only required data and clean it deterministically.
- Isolate parallel tests by database/schema/table/key prefix or unique identifiers.
- Use bounded readiness checks and request timeouts; do not depend on arbitrary sleeps.
- When setup is non-trivial, keep `setup_test.go`, session helpers, fixture builders, and resource assertions beside the HTTP scope. Infrastructure-specific setup belongs beside `tests/integration/infrastructure/` as the other scope of the same suite.
- HTTP fixtures own readiness, seed, namespace, and cleanup; Object Mothers/builders create request/domain data only and never assert.

## Required HTTP Evidence

Cover only contract and wiring risks that matter:

- route and HTTP method
- request body, path, query, and header parsing
- authentication, authorization, tenant, and session context
- status code, headers, and response body
- error mapping and validation
- persistence side effects through a follow-up HTTP read when practical
- idempotency or conflict behavior when part of the contract
- API Gateway/Lambda event and response translation for serverless endpoints

Keep exhaustive business-rule combinations in unit tests.

## Go Conventions

- Put HTTP tests under `tests/integration/http/<context>/` unless the repository has a coherent equivalent.
- Name files `*_http_integration_test.go`.
- Start every file with `//go:build integration`.
- Use Given/When/Then in test names or sections and exact `// Arrange`, `// Act`, `// Assert` comments; preserve a stronger local convention only when it does not weaken the one-line Act rule.
- Run the focused suite with `go test -v -tags=integration ./tests/integration/http/...`.
- For every new or changed test, Given/When/Then naming and exact `// Arrange`, `// Act`, and `// Assert` comments are mandatory; local casing conventions must not remove the BDD meaning or weaken the one-line Act rule.
- Use Go's standard `testing` package for the runner and `testify/assert` or `testify/require` for assertions. Do not use `require.NoError(t, err)`; use an explicit context-rich error check and `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe. Put all assertion calls in `// Assert`; production API types may be imported, but do not add generated mocks or mocking frameworks.
- Use `-parallel` only after isolation is explicit in the spec and `parallel-tracks.md`.
- Unit tests run without tags using the repository's normal `go test` command.
- Run boundary evidence with `-count=1`; execute it from clean state without a preceding unit command and record the standalone result.
- Do not reuse a unit-test `httptest.Server`, global router, token, environment mutation, fixture, temporary directory, in-memory repository, or generated ID.

## Done

- The test fails when HTTP routing, Lambda/API Gateway mapping, DI, persistence wiring, schema, or response mapping is broken.
- The request enters through HTTP and reaches local infrastructure.
- Test state is isolated and cleaned.
- The HTTP suite passes alone and produces the same result regardless of whether unit layers ran before it.
- The relevant unit and integration/http or integration/infrastructure scopes pass.
- `traceability.yaml` and `verification.md` record the concrete test path and command.
