---
skill_id: SKILL-GO_BACKEND_SENIOR_SKILL
name: go-backend-senior
trigger: always_on
description: "Go backend skill for Clean Architecture, DDD, CQRS, ATDD/TDD business behavior, and transport adapters."
globs: "**/*.go,template.yaml"
---

# Go Backend Senior Skill

## SDD Integration

Follow `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and the selected primary workflow. This skill supplies the compact Go baseline; it does not duplicate or relax common gates, traceability, inside-out order, or convergence.


Use the existing backend style in the current repository.

## Project Shape

- Domain module path: `internal/{bounded_context}/domain/{entity}`.
- Application use cases: `internal/{bounded_context}/application/{use_case}`.
- Ports: `application/{use_case}/ports/{commands|queries|validation}` or shared application ports when reuse is already established.
- Infrastructure adapters: `internal/{bounded_context}/infrastructure/{persistence|messaging|session|auth|external}`.
- Interface adapters: `internal/{bounded_context}/interfaces/{http|grpc|cli|worker}`.
- Tests use only `tests/unit/` and `tests/integration/`; integration is split into `http/{context}/` and `infrastructure/{context}/`. HTTP/message services use their real public entry in the HTTP scope; infrastructure scenarios invoke the use case with real adapters and real local resources in the Infrastructure scope.

## Go Style

- Constructors are `NewType(...) (*Type, error)` or `NewType(...) Type` depending on validation.
- Use cases expose `Execute(ctx context.Context, request Request) (Response, error)` or `Execute(ctx, request) error`.
- Name use case types with agent nouns such as `PartyCreator`, `MemberEnroller`, or `OrderCanceller`; avoid `*UseCase`, `*Service`, and `*Handler` for the Application orchestrator.
- Tests use Go's standard `testing` runner with `testify/assert` or `testify/require` assertions, `Test_given_condition_when_action_then_result`, exact `// Arrange`, `// Act`, and `// Assert` comments, a one-line single-statement Act, `t.Parallel()`, setup helpers, builders, and focused hand-written outgoing-port doubles; production APIs under test may be imported. Do not use `require.NoError(t, err)`; use an explicit context-rich error check and `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe.
- Prefer fresh Object Mothers/Test Data Builders and focused SUT factories; fixtures own lifecycle, and test helpers never assert or contain business policy.
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

1. Use BDD to frame actor-visible behavior and acceptance outcome without creating outer test code yet.
2. Drive changed domain invariants with the standard `testing` runner and pass `LAYER-GATE-DOMAIN`.
3. Drive use-case orchestration with the standard `testing` runner and hand-written outgoing-port doubles; pass `LAYER-GATE-APPLICATION`.
4. When outer production is affected, create executable HTTP/message RED and obtain Gate 3-BOUNDARY; otherwise run existing boundary evidence GREEN.
5. Add infrastructure adapters, delivery interfaces, and composition/DI/IaC in that order.
6. Make boundary evidence green through real local resources and refactor with tests green.
7. Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%, and integration tests do not replace core coverage.

## Test Tags

- Unit tests run by default without a Go build tag.
- Boundary integration files must start with `//go:build integration`.
- Do not create additional integration or contract runtime suites; use checked-in schema validation when contract drift needs a static gate.
- Document the matching commands, for example `go test -tags=integration ./tests/integration/http/...` and `go test -tags=integration ./tests/integration/infrastructure/...`.

## Avoid

- Raw primitive validation duplicated across handlers and use cases.
- Repositories with broad CRUD interfaces.
- Domain importing transport, persistence, cloud SDK, JSON, or framework concerns.
- Updating generated DI files by hand when generated wiring is expected.
- Listing a module's individual providers in the executable root instead of using its module-owned DI initializer/output.
- Interfaces, factories, builders, or functional options created only for style.
- Fire-and-forget goroutines without shutdown, cancellation, or error handling.
