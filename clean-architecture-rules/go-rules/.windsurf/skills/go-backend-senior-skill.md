---
trigger: always_on
description: Go backend skill for Clean Architecture, DDD, CQRS, TDD, and transport adapters.
globs: **/*.go,template.yaml
---

# Go Backend Senior Skill

Use the existing backend style in the current repository.

## Project Shape

- Domain module path: `internal/{bounded_context}/domain/{entity}`.
- Application use cases: `internal/{bounded_context}/application/{use_case}`.
- Ports: `application/{use_case}/ports/{commands|queries|validation}` or shared application ports when reuse is already established.
- Infrastructure adapters: `internal/{bounded_context}/infrastructure/{persistence|messaging|session|auth|external}`.
- Interface adapters: `internal/{bounded_context}/interfaces/{http|grpc|cli|worker}`.
- Tests mirror the feature: `tests/{context}/unit_tests/...`, `tests/{context}/integration_tests/...`, `tests/end2end/...`.

## Go Style

- Constructors are `NewType(...) (*Type, error)` or `NewType(...) Type` depending on validation.
- Use cases expose `Execute(ctx context.Context, request Request) (Response, error)` or `Execute(ctx, request) error`.
- Tests use `Test_given_condition_when_action_then_result`, `t.Parallel()`, setup helpers, builders, and focused mocks.
- Prefer sentinel domain/application errors for business cases; wrap technical failures with `fmt.Errorf("failed to ...: %w", err)`.
- Keep DTOs without infrastructure tags in application. Put transport or persistence tags in interface/infrastructure DTOs only.
- Run `gofmt` on touched Go files.

## Senior Go Decisions

- Use concrete types inside a package unless an interface protects a real boundary or enables real substitution.
- Define interfaces near consumers; keep them small and named by behavior.
- Pass `context.Context` only through request-scoped I/O/application paths, never through pure domain objects.
- Use `errors.Is/As` for decisions and avoid comparing error strings.
- Prefer composition over embedding for reuse.
- Use generics only when they remove real duplication across current call sites and improve type safety.
- Start goroutines only with explicit ownership, cancellation, and error collection.
- Use `errgroup` for parallel I/O that should cancel as a group.
- Benchmark/profile before performance-oriented complexity unless the algorithmic issue is obvious.
- Log at boundaries and avoid logging the same returned error in every layer.

## Advanced Pattern Gate

Before adding strategy, worker pool, functional options, generic helpers, event outbox, streaming, caching, or background processing, confirm:

- The current feature needs it now.
- The simpler explicit implementation was considered.
- The pattern has tests or operational evidence behind it.
- The pattern does not create unused extension points.

## TDD Slice

1. Add or modify a unit test under the matching use case.
2. Create or extend value objects first when input has rules.
3. Implement use case orchestration with small command/query/validation ports.
4. Add infrastructure adapters only after application ports exist.
5. Wire DI providers last.
6. Add integration/end-to-end coverage when adapter behavior, messaging, auth/session, routing, or persistence changes.

## Test Tags

- Unit tests run by default without a Go build tag.
- Integration test files must start with `//go:build integration`.
- End-to-end test files must start with `//go:build e2e`.
- Prefer `e2e` over `endtoend`; use `contract` only for API/provider-consumer contract suites.
- Document the matching command when adding a tagged suite, for example `go test -tags=e2e ./tests/end2end/...`.

## Avoid

- Raw primitive validation duplicated across handlers and use cases.
- Repositories with broad CRUD interfaces.
- Domain importing transport, persistence, cloud SDK, JSON, or framework concerns.
- Updating generated DI files by hand when generated wiring is expected.
- Interfaces, factories, builders, or functional options created only for style.
- Fire-and-forget goroutines without shutdown, cancellation, or error handling.
