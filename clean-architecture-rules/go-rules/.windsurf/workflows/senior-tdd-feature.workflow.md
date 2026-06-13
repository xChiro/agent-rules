---
trigger: manual
description: Implement a feature in senior TDD style using DDD, Clean Architecture, CQRS, and value objects.
---

# Senior TDD Feature Workflow

Use this workflow whenever implementing or changing business behavior.

## 1. Read and Frame

- Identify the bounded context, actor, use case, and business outcome.
- Locate the closest existing use case, tests, ports, value objects, and adapters.
- State which layer owns the rule.
- Identify whether the change touches I/O, context propagation, concurrency, error mapping, logging, security, or performance.
- Prefer the simplest explicit design unless an advanced pattern has a current trigger.

## 2. Red

- Write the smallest failing test first.
- Prefer an edge case if it defines an invariant; otherwise start with the happy path.
- Keep Given setup clear, When as one behavior call, Then as observable assertions.
- Use no build tag for normal unit tests.
- Add `//go:build integration` for integration tests.
- Add `//go:build e2e` for end-to-end tests.

## 3. Domain/Application Green

- Add value objects/entities/domain methods before duplicating primitive validation.
- Add command/query/validation ports only for real boundaries or substitutable policies.
- Use concrete collaborators inside a package when no boundary or substitution exists.
- Pass context through application/I/O paths, not pure domain objects.
- Implement only the orchestration and behavior required by the failing test.

## 4. Adapters and Wiring

- Implement infrastructure adapters after ports are stable.
- Map DTOs at boundaries only.
- Wire DI/composition last.

## 5. Refactor and Verify

- Remove unused helpers, ports, request fields, and duplicate validations.
- Remove decorative interfaces, generic helpers, and extension points that are not needed now.
- Verify error wrapping, `errors.Is/As` decisions, and boundary logging.
- Verify goroutine lifetime, cancellation, and error collection when concurrency was touched.
- Check file size, naming, and dependency direction.
- Run targeted tests, then broader tests when adapters or wiring changed.
- Run `go test -race ./...` when shared state or goroutines changed.
- Summarize behavior added, tests run, and residual risk.
