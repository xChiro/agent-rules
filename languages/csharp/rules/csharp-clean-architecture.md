---
rule_id: RULE-CSHARP_CLEAN_ARCHITECTURE
trigger: always_on
description: C#/.NET Clean Architecture, DDD, CQRS, ports/adapters, and YAGNI rules for backend services.
globs: **/*.cs,**/*.csproj,**/*.sln
---

# C# Clean Architecture

## SDD Baseline

- Apply `common/rules/common-sdd-agentic-discipline.md` before this rule.
- Create or evolve the owning User Story based spec before production code when behavior, contracts, architecture, or risk changes.
- Apply mandatory Gate 1 before spec writes, Gate 2 before RED, and Gate 3 before Green, even for simple or low-risk changes.
- Keep artifact, task, track, and test IDs traceable through `traceability.yaml` and `parallel-tracks.md`.
- Write BDD Given/When/Then acceptance evidence first, then the unit-level ATDD-style focused failing test for the next rule or boundary before production code.
- Refactor only with tests green and converge spec history, tasks, parallel tracks, traceability, verification notes, and code.


Use these rules for .NET backend services that follow Clean Architecture, DDD, CQRS, business logic testing, SOLID, Clean Code, and ports/adapters.

Prefer the existing project shape first. Onnodo projects commonly use a core project, `DataAccess`, `WebApi` or Lambda adapter, unit tests, HTTP integration tests, small command/query ports, EF Core adapters, and optional message bus adapters.

## Dependency Rule

Dependencies must point inward:

```text
WebApi / MessageBus / DataAccess -> Application / Domain
```

- Domain owns entities, value objects, domain services, domain events, and business exceptions.
- Application owns use cases, orchestration, request/response models, and all ports consumed by use cases.
- Domain must not define infrastructure ports; domain stays pure and exposes business behavior through entities, value objects, domain services, events, and exceptions.
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
    Application/
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

Place port interfaces in the Application layer, near the use case or application module that consumes them. Infrastructure projects such as `DataAccess` or message adapters implement those Application ports; they do not own the contracts. Domain does not own persistence, messaging, clock, ID-generation, session, or external API ports.

CQRS is implemented with explicit Application interfaces, concrete use case classes, and normal DI registration. Do not use MediatR, mediator pipelines, request handlers, or in-process buses to implement application CQRS.

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
- Mapping belongs inside the DTO that owns the external shape. Persistence DTOs expose `FromDomain`/`ToDomain`, HTTP DTOs expose request/response conversion, and message DTOs expose event/message conversion.

```csharp
public sealed record ItemDbDto(Guid Id, int Quantity)
{
    public static ItemDbDto FromDomain(Item item) =>
        new(item.Id.Value, item.Quantity.Value);

    public Item ToDomain() => Item.Create(Id, Quantity);
}
```

DTO mapping is structural translation and domain construction only. It must not perform I/O, authorization, logging, orchestration, or business policy. If a generated DTO cannot be edited, place a companion mapper beside it in the same adapter project and document the constraint.

Do not pass EF DTOs, broker messages, `IActionResult`, `ProblemDetails`, or `DbContext` into core code.

## YAGNI Guardrails

Create only what the current use case needs.

- Do not add or use MediatR, mediator pipelines, request/notification handlers, AutoMapper, Result libraries, generic repositories, service locators, factories, builders, or decorator pipelines by default.
- Do not add an interface for a private helper or concrete class that does not cross a boundary.
- Do not add ports "for future use".
- Delete unused ports, test doubles, request fields, DTO properties, and packages.
- Add abstractions only when they protect a real boundary, current variation, or stable duplicated decision.

## Decorator Pattern With Guardrails

Use decorators only when a current cross-cutting concern must wrap an existing use case or port while preserving the same business contract.

Good triggers:

- Metrics, tracing, auditing, idempotency, read cache, transaction boundaries, or retry around external dependencies
- The concern would otherwise pollute the use case or be duplicated across multiple implementations
- The decorated interface is small and already represents a real boundary or application action

Rules:

- Keep business rules in the inner use case/domain, not in the decorator.
- Keep infrastructure dependencies in the decorator or composition root, not in Domain/Application.
- The decorator must preserve inputs, outputs, cancellation behavior, and exception meaning.
- Register decorators explicitly in DI. Do not introduce MediatR-style pipelines or generic decorator frameworks.
- Do not add decorators for hypothetical future policies.

```csharp
public interface ICreateBrand
{
    Task<Brand> ExecuteAsync(CreateBrandRequest request, CancellationToken cancellationToken = default);
}

public sealed class CreateBrandMetricsDecorator(
    ICreateBrand inner,
    IMetrics metrics) : ICreateBrand
{
    public async Task<Brand> ExecuteAsync(
        CreateBrandRequest request,
        CancellationToken cancellationToken = default)
    {
        using var timer = metrics.Measure("create_brand");
        return await inner.ExecuteAsync(request, cancellationToken);
    }
}
```

## Architecture Quality Gate

Before finishing a change:

- Core has no references to infrastructure or transport packages.
- Each use case has one actor and one business outcome.
- Ports are behavior-specific, consumer-owned, and defined in Application.
- CQRS uses Application interfaces and DI directly, not MediatR or mediator abstractions.
- Mapping does not leak external models inward.
- New code follows existing project naming unless the task is explicitly a refactor.
- Tests cover the changed business behavior and at least one meaningful edge path.
