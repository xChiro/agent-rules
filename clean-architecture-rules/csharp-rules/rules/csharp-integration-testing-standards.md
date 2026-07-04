---
trigger: model_decision
description: C# integration testing standards for EF Core, WebApi, message bus, hosted services, Testcontainers, and real adapter verification.
globs: **/*.IntegrationTest/**/*.cs,**/*.IntegrationTests/**/*.cs,**/*IntegrationTest.cs,**/*IntegrationTests.cs
---

# C# Integration Testing Standards

Integration tests verify real adapters and wiring through stable ports or public boundaries.

## Scope

Use integration tests for:

- EF Core mappings and migrations
- repository/command/query adapters
- WebApi contracts and middleware
- message consumers/producers
- hosted services
- DI composition
- transactions, idempotency, and unique constraints

Do not use integration tests to replace fast domain/application unit tests.

## Infrastructure

- Prefer Testcontainers or docker-compose for PostgreSQL, RabbitMQ, Redis, and other real dependencies.
- Use the project fixture pattern already present.
- Reset state between tests.
- Seed only the data required by the behavior.
- Avoid relying on test order.
- Keep waits bounded and explicit.

## Boundaries

Test through the adapter or public boundary:

- command/query adapter through its port interface
- WebApi through `HttpClient` or WebApplicationFactory
- message consumer through producer and real broker when practical
- hosted service through the service plus controlled dependencies

Avoid asserting EF internal tracking details unless mapping behavior is the test target.

## Database Tests

- Apply migrations or use the same schema setup as production.
- Verify conversions between domain objects and persistence DTOs.
- Verify unique indexes, required fields, value lengths, and query filters when relevant.
- Use `AsNoTracking()` in read adapters unless tracking is part of the behavior.
- Keep tests isolated by transaction, fresh container, schema reset, or cleanup helper.

## Messaging Tests

- Verify message contract mapping.
- Verify the consumer calls the application use case with the expected request.
- Verify poison message behavior and that processing continues after a classified bad message.
- Verify idempotency when duplicate message IDs are possible.
- Do not log or assert full sensitive payloads.
- Avoid sleeps as the primary synchronization mechanism when a deterministic signal can be used.

## WebApi Tests

Verify:

- route and method
- status code
- request parsing
- response DTO shape
- exception mapping
- auth/session extraction when relevant

Do not duplicate business rule unit tests through HTTP unless the contract itself is the behavior being protected.

## Reliability

- No unbounded `Task.Delay`.
- No tests depending on real wall-clock time unless the clock is controlled.
- No shared mutable static state between tests.
- No hidden dependency on local developer machines beyond Docker and documented env vars.

## Done Criteria

- The test fails when the adapter mapping or wiring is wrong.
- The test uses real infrastructure where the risk is infrastructure behavior.
- Cleanup is explicit.
- The test command for the changed scope passes.
