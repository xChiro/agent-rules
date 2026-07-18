---
rule_id: RULE-CSHARP_HTTP_INTEGRATION_TESTS
trigger: model_decision
description: "C# HTTP integration tests through ASP.NET Core or Lambda with real local infrastructure."
globs: "**/*.IntegrationTests/**/*.cs,**/*HttpIntegrationTest.cs,**/*HttpIntegrationTests.cs"
---

# C# HTTP Integration Tests

Apply `common/rules/common-http-integration-harness.md` for the shared boundary, resource, isolation, cleanup, and evidence contract.
Apply `common/rules/common-test-layer-isolation.md`: the HTTP project boots and tears down independently and never requires a unit-test process to run first.
Apply `common/rules/common-test-data-and-double-patterns.md`: use fresh scenario data and scoped fixtures; keep the real hosted composition and local infrastructure path real.
Apply `common/rules/common-test-assertion-structure.md`: use Given/When/Then behavior naming, exact `// Arrange`, `// Act`, and `// Assert` comments, keep `// Act` to one executable public request statement on one physical line, and keep all assertion APIs in `// Assert`.

## SDD Baseline

- Apply the common SDD lifecycle before changing test or production code.
- Trace every test with a `TEST-*` ID linked to its User Story, requirement, and scenario.
- Write abstract BDD acceptance first.
- Complete affected domain/application RED-GREEN-refactor cycles and pass `LAYER-GATE-APPLICATION` before executable HTTP RED.
- Obtain Gate 3-BOUNDARY before infrastructure, delivery, or composition production changes.

## Only Two Backend Suites

C# backends use only two suite roles:

1. Unit tests for domain/application behavior without external infrastructure.
2. Integration tests for the complete public path or infrastructure wiring with local infrastructure. This rule defines the HTTP scope; infrastructure-focused tests belong in the integration test project under an `Infrastructure` scope.

Do not create a third integration suite or project. Keep HTTP scenarios in the integration project's HTTP scope and use-case-driven persistence, broker, storage, cache, and adapter/resource scenarios in its Infrastructure scope.

## Public Boundary

Send a real HTTP request through:

- `WebApplicationFactory`/`HttpClient` or the repository's real hosted API fixture.
- `sam local start-api`, an equivalent API Gateway emulator, or the established Lambda HTTP harness for serverless services.

Calling a controller, Minimal API delegate, Lambda handler, use case, DbContext, repository, or adapter directly is not an HTTP integration test.

The path should include routing/API Gateway mapping, middleware, auth/session extraction, validation, DTO mapping, application behavior, DI, real adapters, local resources, and response mapping.

## Local Infrastructure

- Prefer Testcontainers, Docker Compose, or faithful local service emulators.
- Use the production database provider and production-equivalent migrations/schema.
- Never mock a touched local infrastructure dependency in this suite. Third-party APIs may use controlled WireMock-style simulators with explicit request/response contracts and failure scenarios.
- Use dummy credentials and local endpoints.
- Seed minimal state and reset it deterministically.
- Isolate tests by database/schema/table/key prefix or unique identifiers.
- Use bounded readiness checks and cancellation tokens; avoid arbitrary `Task.Delay`.
- Use the existing Testcontainers, Docker Compose, or local fixture pattern. Keep fixture setup, builders, and resource assertions in the integration project, separated into HTTP and Infrastructure scopes.
- Object Mothers/builders create request and domain data only; fixtures own host/resources/readiness/cleanup and never assert during Arrange.
- Apply migrations/schema through the real application setup and dispose resources with `IAsyncLifetime`, fixture disposal, or the established cleanup mechanism.
- Infrastructure-scope tests start at the Application use case, use the real adapter implementation and owned local resource, and simulate only third-party APIs with WireMock or a small hand-written HTTP stub.
- In `// Assert` (Then), assert response contracts and meaningful database/cache/queue/object-store side effects, not only status codes.

## Required HTTP Evidence

Cover route/method, request parsing, auth/tenant context, validation, status, headers, response contract, error mapping, persistence side effects, idempotency/conflicts, and Lambda/API Gateway translation when relevant. Keep exhaustive domain decisions in unit tests.

## C# Conventions

- Prefer a dedicated `HttpIntegrationTests` project or the repository's coherent equivalent.
- Name tests with Given/When/Then behavior; preserve only the project's casing convention, not a convention that removes the Given/When/Then meaning.
- Use the real service composition root, overriding only environment endpoints and test-safe credentials.
- Run the focused HTTP integration test project separately from unit test projects.
- Run it from clean state in its own process; do not reuse a unit-test host, service provider, fixture instance, token, environment mutation, database row, or generated identifier.

## Done

- The test fails when routing, middleware, Lambda/API Gateway mapping, DI, EF mapping/migration, local-resource wiring, or response mapping is broken.
- The request enters through HTTP and reaches local infrastructure.
- State is isolated and cleaned.
- The HTTP project passes alone with the same result before or after the unit projects.
- Unit and HTTP integration suites pass.
- `traceability.yaml` and `verification.md` record the test path and command.
