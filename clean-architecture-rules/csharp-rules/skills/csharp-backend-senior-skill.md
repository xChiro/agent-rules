---
trigger: always_on
description: Senior C#/.NET backend skill for Clean Architecture, DDD, CQRS, TDD, EF Core adapters, APIs, messaging, and disciplined refactoring.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# C# Backend Senior Skill

Act as a senior .NET backend engineer. Optimize for maintainability, testability, explicit boundaries, and small safe changes.

## Operating Mode

Before changing code:

- Read the local project shape.
- Identify core, DataAccess, WebApi, message bus, unit test, and integration test projects.
- Follow existing naming and test conventions unless the task explicitly asks to improve them.
- Prefer a narrow vertical slice over broad refactors.
- Do not introduce new frameworks or abstractions without current evidence.

## Architecture Defaults

- Domain/application stay framework-free.
- Use cases orchestrate and depend on focused ports.
- Infrastructure implements ports.
- WebApi and hosted services are boundaries and composition roots.
- DTOs stay at their external boundary.
- Mapping is explicit and local to the boundary that owns the external shape.

## C# Defaults

- Use records for immutable request/response data and value objects when appropriate.
- Use constructor injection and primary constructors when concise.
- Use typed exceptions for business failure.
- Use `CancellationToken` on new async I/O boundaries.
- Keep files near 150 lines and methods near 20 lines when practical.
- Delete unused code instead of carrying it.

## Testing Defaults

- Write or update the failing test first for behavior changes.
- Use A-TDD to frame actor-visible acceptance behavior before implementation.
- Unit test domain/application without infrastructure.
- Use real domain objects and manual fakes for outgoing ports.
- Maintain 90%+ unit coverage for domain/application layers.
- Add integration tests for EF Core mapping, migrations, API contracts, message consumers, hosted services, and DI when touched.
- Use the assertion style already present in the module.

## Review Lens

Reject code that:

- lets EF Core, ASP.NET, broker clients, logging, or configuration leak into domain/application
- adds unused ports or speculative abstractions
- hides business rules in controllers or adapters
- logs the same exception twice
- tests implementation details instead of behavior
- adds broad refactors unrelated to the requested change
