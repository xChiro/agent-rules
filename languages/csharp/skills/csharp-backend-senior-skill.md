---
skill_id: SKILL-CSHARP_BACKEND_SENIOR_SKILL
name: csharp-backend-senior
trigger: always_on
description: "Senior C#/.NET backend skill for Clean Architecture, DDD, CQRS, ATDD/TDD business behavior, EF Core adapters, APIs, messaging, and disciplined refactoring."
globs: "**/*.cs,**/*.csproj,**/*.sln"
---

# C# Backend Senior Skill

## SDD Integration

Follow `RULE-COMMON_SDD_AGENTIC_DISCIPLINE` and the selected primary workflow. This skill supplies the compact C# baseline; it does not duplicate or relax common gates, traceability, inside-out order, or convergence.


Act as a senior .NET backend engineer. Optimize for maintainability, testability, explicit boundaries, and small safe changes.

## Operating Mode

Before changing code:

- Read the local project shape.
- Identify core, DataAccess, WebApi/Lambda, message bus, unit test, and one integration test project with HTTP and Infrastructure scopes.
- Follow existing naming and test conventions unless the task explicitly asks to improve them.
- Prefer a narrow vertical slice over broad refactors.
- Do not introduce new frameworks or abstractions without current evidence.

## Architecture Defaults

- Domain/application stay framework-free.
- Use cases orchestrate and depend on focused Application ports.
- Infrastructure implements Application ports.
- Domain does not define persistence, messaging, clock, session, ID-generation, or external API ports.
- CQRS uses explicit Application interfaces and DI registrations, not MediatR or mediator handlers.
- Each business module owns layer-specific DI extensions and one `Add<Module>Module` entry point; WebApi and hosted services are boundaries and final module aggregators.
- DTOs stay at their external boundary.
- Mapping functions live inside the DTO that owns the external shape: persistence DTOs expose `FromDomain`/`ToDomain`, HTTP DTOs expose request/response conversion, and message DTOs expose message conversion. Use a boundary-local companion only for generated DTOs or deliberate multi-source projections.

## C# Defaults

- Use records for immutable request/response data and value objects when appropriate.
- Use constructor injection and primary constructors when concise.
- Use typed exceptions for business failure.
- Use `CancellationToken` on new async I/O boundaries.
- Keep every in-scope file below 150 physical lines; keep methods near 20 lines when practical.
- Delete unused code instead of carrying it.

## Testing Defaults

- Write or update the failing test first for behavior changes.
- Use ATDD to frame actor-visible acceptance behavior before implementation.
- Unit test domain/application without infrastructure.
- Use real domain objects and project-local manual fakes/stubs/spies for outgoing ports.
- Use fresh Object Mothers/Test Data Builders for scenario data, focused SUT factories for explicit wiring, and scoped fixtures for lifecycle; helpers do not assert or contain business policy.
- Do not add mocking frameworks such as Moq, NSubstitute, FakeItEasy, or JustMock.
- Maintain 90%+ aggregate project-wide production coverage; domain/application unit coverage must also remain at least 90%.
- Add integration tests for public routing or message delivery, EF Core mappings/migrations, DI, and local-resource wiring when touched. HTTP/public-entry tests enter through the public boundary; Infrastructure-scope tests invoke the use case with real adapters and local resources. Keep both scopes in the same integration project.
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
