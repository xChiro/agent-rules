---
rule_id: RULE-COMMON_HTTP_INTEGRATION_HARNESS
trigger: model_decision
description: Shared harness contract for HTTP integration tests that exercise real application wiring and local infrastructure.
---

# Common HTTP Integration Harness

Apply this rule to backend `http-integration` tasks. It is the common replacement for separate infrastructure, API, adapter, handler, Lambda, and E2E runtime-test workflows.

Apply `common-test-assertion-structure.md`: setup and request execution do not assert; all response and side-effect assertions belong in the `Then/Assert` section.

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
8. In `Then/Assert`, assert the response and meaningful persistence/resource side effects.
9. Clean up created state and capture safe diagnostics on failure.

The setup and cleanup path must be deterministic and safe to run repeatedly.

## Real Local Resources

Use the repository's established local resource strategy. Typical resources are PostgreSQL, MySQL, DynamoDB Local, LocalStack, Redis, RabbitMQ, SQS-compatible queues, object storage, and temporary filesystems.

- Use Docker Compose, Testcontainers, SAM local, or the existing repository harness.
- Do not replace infrastructure wiring with mocks in this suite.
- Use dummy credentials and localhost endpoints only.
- Do not require shared developer or production resources.
- Keep readiness failures bounded and report the dependency, endpoint, and last diagnostic.

## Isolation

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

Use small assertion helpers for repeated resource evidence only from `Then/Assert`. Helpers must fail with the resource name, identifier, expected value, and observed value without leaking secrets or full payloads.

## Migration From E2E

The old E2E suite is not a third backend test suite. Its public HTTP scenarios, real-resource setup, session helpers, fixtures, cleanup, and CI execution belong in `http-integration`. A post-deploy smoke check may remain an operational check, but it is not a replacement for local HTTP integration evidence.

## Done

- The test enters through HTTP and uses the real composition root.
- Required local resources are real or faithful local emulators.
- Migrations/schema and minimal seed data are applied.
- Isolation and cleanup are deterministic.
- Response and relevant resource side effects are asserted.
- The test can run in CI without production credentials or shared state.
- `traceability.yaml` and `verification.md` record the test ID, command, resources, and evidence.
