---
skill_id: SKILL-CSHARP_BACKEND_SENIOR_SKILL
name: csharp-backend-senior
trigger: always_on
description: Senior C#/.NET backend skill for Clean Architecture, DDD, CQRS, ATDD/TDD business behavior, EF Core adapters, APIs, messaging, and disciplined refactoring.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# C# Backend Senior Skill

## SDD Baseline

- Follow `common-sdd-agentic-discipline.md` for every behavior-changing task.
- Keep specs versioned under `specs/features/<number>-<slug>/` when the project supports SDD artifacts.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Start with BDD Given/When/Then acceptance evidence, then unit-level ATDD-style focused failing test code, then production code.
- Refactor only with tests green and converge specs, tasks, parallel tracks, traceability, verification notes, and code.


Act as a senior .NET backend engineer. Optimize for maintainability, testability, explicit boundaries, and small safe changes.

## Operating Mode

Before changing code:

- Read the local project shape.
- Identify core, DataAccess, WebApi/Lambda, message bus, unit test, and HTTP integration test projects.
- Follow existing naming and test conventions unless the task explicitly asks to improve them.
- Prefer a narrow vertical slice over broad refactors.
- Do not introduce new frameworks or abstractions without current evidence.

## Architecture Defaults

- Domain/application stay framework-free.
- Use cases orchestrate and depend on focused Application ports.
- Infrastructure implements Application ports.
- Domain does not define persistence, messaging, clock, session, ID-generation, or external API ports.
- CQRS uses explicit Application interfaces and DI registrations, not MediatR or mediator handlers.
- WebApi and hosted services are boundaries and composition roots.
- DTOs stay at their external boundary.
- Mapping functions live inside the DTO that owns the external shape: persistence DTOs expose `FromDomain`/`ToDomain`, HTTP DTOs expose request/response conversion, and message DTOs expose message conversion. Use a boundary-local companion only for generated DTOs or deliberate multi-source projections.

## C# Defaults

- Use records for immutable request/response data and value objects when appropriate.
- Use constructor injection and primary constructors when concise.
- Use typed exceptions for business failure.
- Use `CancellationToken` on new async I/O boundaries.
- Keep files near 150 lines and methods near 20 lines when practical.
- Delete unused code instead of carrying it.

## Testing Defaults

- Write or update the failing test first for behavior changes.
- Use ATDD to frame actor-visible acceptance behavior before implementation.
- Unit test domain/application without infrastructure.
- Use real domain objects and project-local manual fakes/stubs/spies for outgoing ports.
- Do not add mocking frameworks such as Moq, NSubstitute, FakeItEasy, or JustMock.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%.
- Add HTTP integration tests for public routing, EF Core mappings/migrations, DI, and local-resource wiring when touched. Do not create separate adapter or messaging integration suites.
- Use the assertion style already present in the module.

## Review Lens

Reject code that:

- lets EF Core, ASP.NET, broker clients, logging, or configuration leak into domain/application
- uses MediatR or mediator abstractions for application CQRS
- adds a mocking framework instead of small manual test doubles
- adds unused ports or speculative abstractions
- hides business rules in controllers or adapters
- logs the same exception twice
- tests implementation details instead of behavior
- adds broad refactors unrelated to the requested change
