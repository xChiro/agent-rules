---
skill_id: SKILL-GO_BACKEND_SENIOR_SKILL
name: go-backend-senior
trigger: always_on
description: Go backend skill for Clean Architecture, DDD, CQRS, ATDD/TDD business behavior, and transport adapters.
globs: **/*.go,template.yaml
---

# Go Backend Senior Skill

## SDD Baseline

- Follow `common-sdd-agentic-discipline.md` for every behavior-changing task.
- Keep specs versioned under `specs/features/<number>-<slug>/` when the project supports SDD artifacts.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Start with BDD Given/When/Then acceptance evidence, then unit-level ATDD-style focused failing test code, then production code.
- Refactor only with tests green and converge specs, tasks, parallel tracks, traceability, verification notes, and code.


Use the existing backend style in the current repository.

## Project Shape

- Domain module path: `internal/{bounded_context}/domain/{entity}`.
- Application use cases: `internal/{bounded_context}/application/{use_case}`.
- Ports: `application/{use_case}/ports/{commands|queries|validation}` or shared application ports when reuse is already established.
- Infrastructure adapters: `internal/{bounded_context}/infrastructure/{persistence|messaging|session|auth|external}`.
- Interface adapters: `internal/{bounded_context}/interfaces/{http|grpc|cli|worker}`.
- Tests use only unit suites and `tests/http/{context}/...` HTTP integration suites.

## Go Style

- Constructors are `NewType(...) (*Type, error)` or `NewType(...) Type` depending on validation.
- Use cases expose `Execute(ctx context.Context, request Request) (Response, error)` or `Execute(ctx, request) error`.
- Tests use `Test_given_condition_when_action_then_result`, `t.Parallel()`, setup helpers, builders, and focused mocks.
- Prefer sentinel domain/application errors for business cases; wrap technical failures with `fmt.Errorf("failed to ...: %w", err)`.
- Keep DTOs without infrastructure tags in application. Put transport or persistence tags in interface/infrastructure DTOs only.
- Keep boundary mapping functions with the DTO that owns the external shape: HTTP DTOs expose `ToApplication`/`FromApplication`, persistence DTOs expose `FromDomain`/`ToDomain`, and message DTOs expose message conversion. Use a boundary-local companion only for generated DTOs or deliberate multi-source projections.
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

## Business Feature Slice

1. Use ATDD to frame actor-visible behavior and acceptance outcome.
2. Add or modify a unit test under the matching use case.
3. Create or extend value objects first when input has rules.
4. Implement use case orchestration with small command/query/validation ports.
5. Add infrastructure adapters only after application ports exist.
6. Wire DI providers last.
7. Add HTTP integration coverage when routing, Lambda/API Gateway mapping, auth/session, DI, persistence, or local-resource wiring changes.
8. Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and HTTP integration tests do not replace core coverage.

## Test Tags

- Unit tests run by default without a Go build tag.
- HTTP integration files must start with `//go:build integration`.
- Do not create additional integration or contract runtime suites; use checked-in schema validation when contract drift needs a static gate.
- Document the matching command, for example `go test -tags=integration ./tests/http/...`.

## Avoid

- Raw primitive validation duplicated across handlers and use cases.
- Repositories with broad CRUD interfaces.
- Domain importing transport, persistence, cloud SDK, JSON, or framework concerns.
- Updating generated DI files by hand when generated wiring is expected.
- Interfaces, factories, builders, or functional options created only for style.
- Fire-and-forget goroutines without shutdown, cancellation, or error handling.
