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

## TDD Slice

1. Add or modify a unit test under the matching use case.
2. Create or extend value objects first when input has rules.
3. Implement use case orchestration with small command/query/validation ports.
4. Add infrastructure adapters only after application ports exist.
5. Wire DI providers last.
6. Add integration/end-to-end coverage when adapter behavior, messaging, auth/session, routing, or persistence changes.

## Avoid

- Raw primitive validation duplicated across handlers and use cases.
- Repositories with broad CRUD interfaces.
- Domain importing transport, persistence, cloud SDK, JSON, or framework concerns.
- Updating generated DI files by hand when generated wiring is expected.
