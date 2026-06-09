---
trigger: always_on
description: .NET backend skill for Clean Architecture, DDD, messaging/persistence adapters, and TDD.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# .NET Backend Senior Skill

Use the existing .NET backend style in the current repository: clean core, explicit ports, focused tests, and small files.

## Project Shape

- Core/domain/application: the project containing business rules and application orchestration.
- Persistence adapters: the project or folder that maps domain objects to storage.
- Messaging adapters: the project or folder that maps transport messages to application requests.
- API/composition root: the project that exposes external protocols and wires dependencies.
- Unit tests: focused tests for domain and application behavior.
- Integration tests: real infrastructure tests for persistence, messaging, API wiring, and hosted services.

## .NET Style

- Value objects are immutable records when possible.
- Entities/classes protect invariants and expose named behavior.
- Ports are small interfaces named by behavior: `ISaveTelemetry`, `IGetDeviceSettingByDeviceId`, `ISendTelemetry`.
- Use constructor dependency injection and register dependencies in the composition root or service collection extension.
- Use manual mocks/fakes in tests before adding a mocking framework.
- Keep production files close to 150 lines and methods close to 20 lines.

## TDD Slice

1. Add a failing xUnit test in Given-When-Then form.
2. Name the SUT variable `SUT` for new tests.
3. Use real domain objects/value objects; use manual mocks for outgoing ports.
4. Add request/response records only when they clarify the use case boundary.
5. Keep business logic in entities/value objects/domain services; use cases orchestrate.
6. Add integration tests for EF Core mappings, RabbitMQ consumers/publishers, hosted services, and API wiring.

## Boundaries

- Core/domain/application code must not depend on EF Core, message broker SDKs, ASP.NET, or infrastructure DTOs.
- Persistence adapters map domain to storage DTO/configuration and back.
- Message adapters map transport messages to application requests and handle ack/retry semantics.
- API projects wire services and expose external protocols only.
