---
rule_id: RULE-COMMON_HTTP_INTEGRATION_HARNESS
trigger: model_decision
description: "Shared harness contract for HTTP integration tests that exercise real application wiring and local infrastructure."
---

# Common HTTP Integration Harness

Apply this HTTP specialization to backend `integration/http` tasks whose public entry is HTTP. It is one scope of the canonical integration suite; infrastructure-focused tests belong in `integration/infrastructure`.

Apply `common-test-assertion-structure.md`: use exact `// Arrange`, `// Act`, and `// Assert` sections; the public request is the single one-line Act statement, and all response/side-effect assertions belong in `// Assert`.

Apply `common-test-layer-isolation.md`: the HTTP suite must start, seed, execute, and clean up by itself from a clean process. It must pass when no Domain/Application test command has run.

## Boundary

- Enter through a real HTTP request to the running server, API Gateway emulator, or `sam local start-api`.
- Use the real composition root and dependency injection wiring.
- Reach the local database, cache, queue, object store, or emulator required by the behavior.
- Do not call handlers, controllers, Lambda functions, repositories, DbContexts, or adapters directly from the HTTP integration test.
- Keep business-rule combinations and invalid-state partitions in unit tests.

## Required Lifecycle

For every HTTP integration slice:

1. Allocate an isolated test namespace, schema, table prefix, queue, bucket prefix, or identifier set.
2. Start or connect to local infrastructure.
3. Wait for readiness with bounded retries, useful diagnostics, and cancellation support.
4. Apply production-equivalent migrations, tables, indexes, or schemas.
5. Seed only the minimum data required by the scenario.
6. Start the real HTTP boundary with test-safe configuration.
7. Send the request using the public contract.
8. In `// Assert` (Then), assert the response and meaningful persistence/resource side effects.
9. Clean up created state and capture safe diagnostics on failure.

The setup and cleanup path must be deterministic and safe to run repeatedly.

## Real Local Resources

Use the repository's established local resource strategy. Typical resources are PostgreSQL, MySQL, DynamoDB Local, LocalStack, Redis, RabbitMQ, SQS-compatible queues, object storage, and temporary filesystems.

- Use Docker Compose, Testcontainers, SAM local, or the existing repository harness.
- Do not replace touched local infrastructure wiring with mocks in this suite. Third-party APIs may be replaced by controlled WireMock-style simulators; the application client, serialization, timeout, retry, and error mapping remain real.
- Use dummy credentials and localhost endpoints only.
- Do not require shared developer or production resources.
- Keep readiness failures bounded and report the dependency, endpoint, and last diagnostic.

## Isolation

Cross-layer isolation is mandatory: never consume a database row, token, server, queue message, environment mutation, generated identifier, fixture, or cache produced by a unit-test process. The boundary harness owns a fresh namespace and its complete lifecycle.

Choose the least expensive safe strategy for each resource:

- Database: transaction rollback, unique schema, unique table prefix, or deterministic cleanup.
- DynamoDB: unique table or key prefix and explicit cleanup.
- Cache: unique key prefix and cleanup of created keys.
- Queue: unique queue/topic where supported, purge or delete after the scenario.
- Object storage: unique bucket/key prefix and cleanup.
- Filesystem: unique temporary directory and deferred removal.
- External API emulator: scenario-specific identifiers and cleanup calls.

Parallel execution is allowed only when isolation is proven. A test that shares mutable state must remain sequential and document why in the spec.

## Evidence

Each scenario should prove the public behavior, not only a status code. Cover the relevant route and method, authentication or tenant context, request parsing, validation, response headers and contract, error mapping, persistence side effects, idempotency/conflicts, and API Gateway/Lambda translation.

Use small assertion helpers for repeated resource evidence only from `// Assert`. Helpers must fail with the resource name, identifier, expected value, and observed value without leaking secrets or full payloads.

## Migration From E2E

The old E2E suite is not a third backend test suite. Its public HTTP scenarios, real-resource setup, session helpers, fixtures, cleanup, and CI execution belong in `integration/http`; adapter/resource checks belong in `integration/infrastructure`. A post-deploy smoke check may remain an operational check, but it is not a replacement for local integration evidence.

## Done

- The test enters through HTTP and uses the real composition root.
- Required local resources are real or faithful local emulators.
- Migrations/schema and minimal seed data are applied.
- Isolation and cleanup are deterministic.
- Response and relevant resource side effects are asserted.
- The test can run in CI without production credentials or shared state.
- The documented boundary command passes alone from clean state and does not depend on the unit-test job.
- `traceability.yaml` and `verification.md` record the test ID, command, resources, and evidence.
