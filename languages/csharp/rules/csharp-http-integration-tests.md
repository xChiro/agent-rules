---
rule_id: RULE-CSHARP_HTTP_INTEGRATION_TESTS
trigger: model_decision
description: C# HTTP integration tests through ASP.NET Core or Lambda with real local infrastructure.
globs: **/*.IntegrationTests/**/*.cs,**/*HttpIntegrationTest.cs,**/*HttpIntegrationTests.cs
---

# C# HTTP Integration Tests

Apply `common/rules/common-http-integration-harness.md` for the shared boundary, resource, isolation, cleanup, and evidence contract.
Apply `common/rules/common-test-assertion-structure.md`: setup/request execution do not assert; all assertion APIs are in the `Then/Assert` section.

## SDD Baseline

- Apply the common SDD lifecycle before changing test or production code.
- Trace every test with a `TEST-*` ID linked to its User Story, requirement, and scenario.
- Write BDD acceptance evidence and HTTP integration RED before implementing changed public behavior.
- Write focused domain/application unit RED before production business logic.

## Only Two Backend Suites

C# backends use only:

1. Unit tests for domain/application behavior without external infrastructure.
2. HTTP integration tests for the complete public path with local infrastructure.

Do not create separate EF Core, repository, adapter, controller, infrastructure, WebApi, end-to-end, or Lambda-handler integration suites. Verify those concerns through HTTP.

## Public Boundary

Send a real HTTP request through:

- `WebApplicationFactory`/`HttpClient` or the repository's real hosted API fixture.
- `sam local start-api`, an equivalent API Gateway emulator, or the established Lambda HTTP harness for serverless services.

Calling a controller, Minimal API delegate, Lambda handler, use case, DbContext, repository, or adapter directly is not an HTTP integration test.

The path should include routing/API Gateway mapping, middleware, auth/session extraction, validation, DTO mapping, application behavior, DI, real adapters, local resources, and response mapping.

## Local Infrastructure

- Prefer Testcontainers, Docker Compose, or faithful local service emulators.
- Use the production database provider and production-equivalent migrations/schema.
- Never mock a touched external dependency in this suite.
- Use dummy credentials and local endpoints.
- Seed minimal state and reset it deterministically.
- Isolate tests by database/schema/table/key prefix or unique identifiers.
- Use bounded readiness checks and cancellation tokens; avoid arbitrary `Task.Delay`.
- Use the existing Testcontainers, Docker Compose, or local fixture pattern. Keep fixture setup, builders, and resource assertions in the HTTP integration project.
- Apply migrations/schema through the real application setup and dispose resources with `IAsyncLifetime`, fixture disposal, or the established cleanup mechanism.
- In `Then/Assert`, assert response contracts and meaningful database/cache/queue/object-store side effects, not only status codes.

## Required HTTP Evidence

Cover route/method, request parsing, auth/tenant context, validation, status, headers, response contract, error mapping, persistence side effects, idempotency/conflicts, and Lambda/API Gateway translation when relevant. Keep exhaustive domain decisions in unit tests.

## C# Conventions

- Prefer a dedicated `HttpIntegrationTests` project or the repository's coherent equivalent.
- Name tests in Given/When/Then or the established behavior convention.
- Use the real service composition root, overriding only environment endpoints and test-safe credentials.
- Run the focused HTTP integration test project separately from unit test projects.

## Done

- The test fails when routing, middleware, Lambda/API Gateway mapping, DI, EF mapping/migration, local-resource wiring, or response mapping is broken.
- The request enters through HTTP and reaches local infrastructure.
- State is isolated and cleaned.
- Unit and HTTP integration suites pass.
- `traceability.yaml` and `verification.md` record the test path and command.
