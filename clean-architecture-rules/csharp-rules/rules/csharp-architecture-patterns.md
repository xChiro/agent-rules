---
trigger: always_on
description: C#/.NET Clean Architecture, DDD, CQRS, ports/adapters, and YAGNI rules for backend services.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# C# Architecture Patterns

Use these rules for .NET backend services that follow Clean Architecture, DDD, CQRS, TDD, SOLID, Clean Code, and ports/adapters.

Prefer the existing project shape first. Onnodo projects commonly use a core project, `DataAccess`, `WebApi`, unit tests, integration tests, small command/query ports, EF Core adapters, and optional message bus adapters.

## Dependency Rule

Dependencies must point inward:

```text
WebApi / MessageBus / DataAccess -> Application / Domain
```

- Domain owns entities, value objects, domain services, domain events, and business exceptions.
- Application owns use cases, orchestration, request/response models, and ports consumed by use cases.
- Infrastructure owns EF Core, persistence DTOs, migrations, message broker clients, external SDKs, and adapter mapping.
- WebApi or worker host owns composition, middleware, route registration, hosted services, configuration, and top-level error handling.

Never let domain/application depend on ASP.NET Core, EF Core, RabbitMQ, HTTP clients, SDK models, `ILogger`, `IConfiguration`, `IOptions`, or transport DTOs.

## Screaming Architecture

Project and folder names should reveal business capability before technology.

Prefer:

```text
Onnodo.FleetTracking/
  Telemetries/
    Entities/
    Processing/
    Repositories/
    Ports/

Onnodo.FleetTracking.DataAccess/
  Telemetries/
    Commands/
    Queries/
    TelemetryDto.cs
    TelemetryConfiguration.cs
```

Avoid:

```text
Domain/Models/Entity.cs
Services/Manager.cs
Helpers/Utility.cs
```

## CQRS Ports

Use focused ports that describe the behavior needed by the consumer.

Good:

```csharp
public interface ICreateBrandCommand
{
    Task Execute(Brand brand, CancellationToken cancellationToken = default);
}

public interface IGetDeviceSettingByDeviceId
{
    Task<DeviceSetting?> Execute(string deviceId, CancellationToken cancellationToken = default);
}
```

Avoid generic repositories unless the project already has one and changing it is out of scope:

```csharp
public interface IRepository<T>
{
    Task Add(T entity);
    Task<T?> GetById(Guid id);
    Task<IReadOnlyList<T>> List();
    Task Delete(Guid id);
}
```

## DDD Boundaries

- Entities protect invariants and expose behavior.
- Value objects represent meaningful domain concepts and validate themselves.
- Use cases coordinate entities and ports; they do not own domain rules that naturally belong in entities or value objects.
- Domain events describe something that already happened in the domain language.
- Application services may publish events or call ports after domain state changes.

## DTO Boundaries

- HTTP request/response DTOs live in WebApi.
- Persistence DTOs and EF configurations live in DataAccess.
- Broker messages live in the message bus adapter project.
- Application request/response records must stay framework-free.
- Mapping belongs near the boundary that owns the external shape.

Do not pass EF DTOs, broker messages, `IActionResult`, `ProblemDetails`, or `DbContext` into core code.

## YAGNI Guardrails

Create only what the current use case needs.

- Do not add MediatR, AutoMapper, Result libraries, generic repositories, service locators, factories, builders, or decorators unless there is a current need and the project already accepts that pattern.
- Do not add an interface for a private helper or concrete class that does not cross a boundary.
- Do not add ports "for future use".
- Delete unused ports, mocks, request fields, DTO properties, and packages.
- Add abstractions only when they protect a real boundary, current variation, or stable duplicated decision.

## Architecture Quality Gate

Before finishing a change:

- Core has no references to infrastructure or transport packages.
- Each use case has one actor and one business outcome.
- Ports are behavior-specific and consumer-owned.
- Mapping does not leak external models inward.
- New code follows existing project naming unless the task is explicitly a refactor.
- Tests cover the changed business behavior and at least one meaningful edge path.
