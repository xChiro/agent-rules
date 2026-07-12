---
rule_id: RULE-GO_HTTP_INTEGRATION_TESTS
trigger: always_on
description: Go HTTP integration tests through the real REST or Lambda boundary with local infrastructure.
globs: **/*_test.go,template.yaml
---

# Go HTTP Integration Tests

Apply `common/rules/common-http-integration-harness.md` for the shared boundary, resource, isolation, cleanup, and evidence contract.
Apply `common/rules/common-test-assertion-structure.md`: setup/request execution do not assert; all `assert`/`require` calls are in `// Then / Assert`.

## SDD Baseline

- Apply the common SDD lifecycle before changing test or production code.
- Trace each test with a `TEST-*` ID linked to its `US-*`, `REQ-*`, and `SCN-*` IDs.
- Write the BDD acceptance scenario first and confirm HTTP integration RED before implementation when the public behavior is new or changed.
- Write the focused domain/application unit test RED before production business logic.

## Only Two Backend Suites

Go backends use only:

1. Unit tests for domain/application behavior without external infrastructure.
2. HTTP integration tests for the complete public path with local infrastructure.

Do not create separate repository, persistence-adapter, handler, infrastructure, API, end-to-end, or Lambda-handler integration suites. Infrastructure behavior is proven through HTTP.

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
- Never replace touched infrastructure with mocks in this suite.
- Use dummy credentials and local endpoints.
- Apply production-equivalent migrations, schemas, indexes, and table definitions.
- Seed only required data and clean it deterministically.
- Isolate parallel tests by database/schema/table/key prefix or unique identifiers.
- Use bounded readiness checks and request timeouts; do not depend on arbitrary sleeps.
- When setup is non-trivial, keep `setup_test.go`, session helpers, fixture builders, and resource assertions beside the HTTP suite. Do not create a second infrastructure test tree.

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

- Put new suites under `tests/http/<context>/` unless the repository has a coherent equivalent.
- Name files `*_http_integration_test.go`.
- Start every file with `//go:build integration`.
- Use Given/When/Then in test names or sections; preserve a stronger local convention if one exists.
- Run the focused suite with `go test -v -tags=integration ./tests/http/...`.
- Use `testify/assert` or the repository's established assertion library; put all calls in `// Then / Assert` and cover response plus meaningful resource side effects.
- Use `-parallel` only after isolation is explicit in the spec and `parallel-tracks.md`.
- Unit tests run without tags using the repository's normal `go test` command.

## Done

- The test fails when HTTP routing, Lambda/API Gateway mapping, DI, persistence wiring, schema, or response mapping is broken.
- The request enters through HTTP and reaches local infrastructure.
- Test state is isolated and cleaned.
- The relevant unit and HTTP integration suites pass.
- `traceability.yaml` and `verification.md` record the concrete test path and command.
